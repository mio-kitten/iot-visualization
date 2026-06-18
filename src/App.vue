<script setup lang="ts">
import { ref, provide, onUnmounted, computed, watch } from 'vue'
import { useProject } from './composables/useProject'
import { MqttClientWrapper } from './utils/mqttClient'
import type { PlatformConfig, DataPoint, Widget, Project } from './types'
import Header from './components/Header.vue'
import SidebarLeft from './components/SidebarLeft.vue'
import MainCanvas from './components/MainCanvas.vue'
import SidebarRight from './components/SidebarRight.vue'
import PlatformConfigModal from './components/PlatformConfigModal.vue'
import ProjectManager from './components/ProjectManager.vue'
import TopBar from './components/TopBar.vue'

const {
  projects,
  currentProject,
  currentProjectId,
  createProject,
  updateProject,
  deleteProject,
  setCurrentProject,
  addWidget,
  updateWidget,
  removeWidget,
  savePlatformConfig,
  loadPlatformConfig,
  createWidget
} = useProject()

const isConnected = ref(false)
const isConnecting = ref(false)
const showPlatformConfig = ref(false)
const showProjectManager = ref(!currentProjectId.value)
const selectedWidgetId = ref<string | null>(null)
const selectedWidget = computed(() => {
  return currentProject.value?.widgets.find((w: Widget) => w.id === selectedWidgetId.value) || undefined
})
const mqttClient = new MqttClientWrapper()

const isFullscreen = ref(false)
const showTopBar = ref(false)
let topBarTimeout: number | null = null

const handleFullscreenChange = () => {
  if (!document.fullscreenElement && isFullscreen.value) {
    showTopBar.value = false
    isFullscreen.value = false
  }
}

document.addEventListener('fullscreenchange', handleFullscreenChange)

const widgetData = ref<Map<string, Map<string, DataPoint[]>>>(new Map())
const updateInterval = ref<number | null>(null)
const healthCheckInterval = ref<number | null>(null)

const pendingPlatformConfig = ref<PlatformConfig | null>(null)
const defaultPlatformConfig = ref<PlatformConfig | null>(loadPlatformConfig())

const getAllTopics = () => {
  if (!currentProject.value) return []
  
  return currentProject.value.widgets
    .flatMap((w: Widget) => {
      if (w.type === 'lineChart') {
        const config = w.config as { displayMode: string; topic?: string; themes: { topic: string }[] }
        if (config.displayMode === 'singleTopic') {
          return config.topic ? [config.topic] : []
        } else {
          return config.themes
            .filter(t => t.topic)
            .map(t => t.topic)
        }
      }
      if (w.type === 'switch') {
        const config = w.config as { topic?: string }
        return config.topic ? [config.topic] : []
      }
      if (w.type === 'text') {
        const config = w.config as { topic?: string }
        return config.topic ? [config.topic] : []
      }
      if (w.type === 'textarea') {
        const config = w.config as { themes?: { topic: string }[] }
        if (config.themes) {
          return config.themes
            .filter(t => t.topic)
            .map(t => t.topic)
        }
        return []
      }
      if (w.type === 'barChart') {
        const config = w.config as { topic?: string }
        return config.topic ? [config.topic] : []
      }
      if (w.type === 'miniArea') {
        const config = w.config as { topic?: string }
        return config.topic ? [config.topic] : []
      }
      return []
    })
  }

  const updateSubscriptions = () => {
  if (!mqttClient.isConnected()) return
  // 先取消所有旧订阅，再订阅当前项目的主题
  mqttClient.unsubscribeAll()
  
  const topics = getAllTopics()
  if (topics.length > 0) {
    mqttClient.subscribe(topics)
  }
}

const showEditor = computed(() => !isFullscreen.value && !showProjectManager.value)
const showProjectSelector = computed(() => !showProjectManager.value)
const showProjectManagerBtn = computed(() => !showProjectManager.value)

const headerTitle = computed(() => {
  if (!currentProjectId.value || showProjectManager.value) {
    return '项目管理'
  }
  return showEditor.value ? '编辑模式' : '查看模式'
})

const connectToPlatform = async (config: PlatformConfig, isFromProjectSwitch = false) => {
  if (isConnecting.value) return
  
  isConnecting.value = true
  
  try {
    const connectPromise = mqttClient.connect(config)
    
    await new Promise((resolve) => setTimeout(resolve, 2000))
    
    if (!mqttClient.isConnected()) {
      await new Promise((resolve) => setTimeout(resolve, 4000))
    }
    
    await connectPromise.catch(() => {})
    
    if (!mqttClient.isConnected()) {
      throw new Error('连接超时')
    }
    
    isConnected.value = true
    
    if (!isFromProjectSwitch) {
      const shouldUpdateDefault = checkAndUpdateDefaultConfig(config)
      if (shouldUpdateDefault) {
        defaultPlatformConfig.value = { ...config }
        savePlatformConfig(config)
      }
    }
    
    if (currentProject.value) {
      updateProject(currentProject.value.id, { platformConfig: config })
    }
    
    const topics = getAllTopics()
    if (topics.length > 0) {
      mqttClient.subscribe(topics)
    }
    
    mqttClient.setOnMessageCallback((topic: string, message: string) => {
      handleMessage(topic, message)
    })
    
    // 监听MQTT底层事件，自动响应断连
    mqttClient.setOnStatusChange((connected) => {
      if (!connected && isConnected.value) {
        isConnected.value = false
        stopHealthCheck()
      }
    })
    
    // 每5秒主动检查连接健康状态
    startHealthCheck()
    
    startUpdateLoop()
  } catch (error) {
    console.error('连接失败:', error)
    isConnected.value = false
    if (!isFromProjectSwitch) {
      alert('连接失败，请检查服务器地址和端口是否正确')
    }
  } finally {
    isConnecting.value = false
  }
}

const checkAndUpdateDefaultConfig = (config: PlatformConfig): boolean => {
  if (!defaultPlatformConfig.value) return true
  
  if (config.platform !== defaultPlatformConfig.value.platform) {
    const confirmOverride = confirm(`检测到平台配置已更改，是否覆盖默认配置？\n\n当前默认: ${defaultPlatformConfig.value.platform || '未设置'}\n新配置: ${config.platform || '未设置'}`)
    return confirmOverride
  }
  
  if (config.platform === 'siot') {
    const siot = config.siot
    const defaultSiot = defaultPlatformConfig.value.siot
    if (siot.server !== defaultSiot.server || siot.port !== defaultSiot.port ||
        siot.username !== defaultSiot.username || siot.password !== defaultSiot.password) {
      const confirmOverride = confirm(`检测到SIoT配置已更改，是否覆盖默认配置？`)
      return confirmOverride
    }
  } else {
    const bafayun = config.bafayun
    const defaultBafayun = defaultPlatformConfig.value.bafayun
    if (bafayun.server !== defaultBafayun.server || bafayun.port !== defaultBafayun.port ||
        bafayun.privateKey !== defaultBafayun.privateKey) {
      const confirmOverride = confirm(`检测到巴法云配置已更改，是否覆盖默认配置？`)
      return confirmOverride
    }
  }
  
  return true
}

const MAX_DATA_BUFFER = 500

const handleMessage = (topic: string, message: string) => {
  if (!currentProject.value) return
  
  currentProject.value.widgets.forEach((widget: Widget) => {
    let widgetDataUpdated = false
    const widgetDataMap = widgetData.value.get(widget.id) || new Map()
    
    if (widget.type === 'lineChart') {
      const config = widget.config as { themes: { id: string; topic: string }[]; maxDataPoints: number; displayMode: string; topic?: string }
      
      if (config.displayMode === 'singleTopic' && config.topic === topic) {
        const values = message.split('/')
        
        for (let index = 0; index < values.length; index++) {
          const lineId = `line-${index + 1}`
          const data = [...(widgetDataMap.get(lineId) || [])]
          const numValue = parseFloat(values[index].trim())
          
          data.push({
            timestamp: Date.now(),
            value: isNaN(numValue) ? 0 : numValue,
            themeId: lineId
          })
          
          if (data.length > MAX_DATA_BUFFER) {
            data.shift()
          }
          
          widgetDataMap.set(lineId, data)
        }
        widgetDataUpdated = true
      } else if (config.displayMode === 'multiTopic') {
        const parts = message.split('\\')
        let value: number
        
        if (parts.length === 2) {
          value = parseFloat(parts[1])
          if (isNaN(value)) return
        } else {
          value = parseFloat(message)
          if (isNaN(value)) return
        }
        
        // 不论该 topic 是否有匹配的主题，都保存数据
        const data = [...(widgetDataMap.get(topic) || [])]
        
        data.push({
          timestamp: Date.now(),
          value,
          themeId: topic
        })
        
        if (data.length > MAX_DATA_BUFFER) {
          data.shift()
        }
        
        widgetDataMap.set(topic, data)
        widgetDataUpdated = true
      }
    }
    
    if (widget.type === 'barChart') {
      const config = widget.config as { topic?: string; color?: string; maxDataPoints?: number }
      
      if (config.topic === topic) {
        const value = parseFloat(message)
        
        if (!isNaN(value)) {
          const data = [...(widgetDataMap.get(widget.id) || [])]
          data.push({
            timestamp: Date.now(),
            value,
            themeId: widget.id
          })
          
          if (data.length > MAX_DATA_BUFFER) {
            data.shift()
          }
          
          widgetDataMap.set(widget.id, data)
          widgetDataUpdated = true
        }
      }
    }
    
    if (widget.type === 'miniArea') {
      const config = widget.config as { topic?: string; color?: string; maxDataPoints?: number }
      
      if (config.topic === topic) {
        const value = parseFloat(message)
        
        if (!isNaN(value)) {
          const data = [...(widgetDataMap.get(widget.id) || [])]
          data.push({
            timestamp: Date.now(),
            value,
            themeId: widget.id
          })
          
          if (data.length > MAX_DATA_BUFFER) {
            data.shift()
          }
          
          widgetDataMap.set(widget.id, data)
          widgetDataUpdated = true
        }
      }
    }
    
    if (widget.type === 'text') {
      const config = widget.config as { topic?: string }
      if (config.topic === topic) {
        const data = [...(widgetDataMap.get(topic) || [])]
        data.push({
          timestamp: Date.now(),
          value: message,
          themeId: topic
        })
        
        if (data.length > MAX_DATA_BUFFER) {
          data.shift()
        }
        
        widgetDataMap.set(topic, data)
        widgetDataUpdated = true
      }
    }
    
    if (widget.type === 'textarea') {
      const config = widget.config as { themes?: { topic: string }[] }
      if (config.themes?.some(t => t.topic === topic)) {
        const data = [...(widgetDataMap.get(topic) || [])]
        data.push({
          timestamp: Date.now(),
          value: message,
          themeId: topic
        })
        
        if (data.length > MAX_DATA_BUFFER) {
          data.shift()
        }
        
        widgetDataMap.set(topic, data)
        widgetDataUpdated = true
      }
    }
    
    if (widget.type === 'switch') {
      const config = widget.config as { topic?: string }
      if (config.topic === topic) {
        const data = [...(widgetDataMap.get(topic) || [])]
        data.push({
          timestamp: Date.now(),
          value: message,
          themeId: topic
        })
        
        if (data.length > MAX_DATA_BUFFER) {
          data.shift()
        }
        
        widgetDataMap.set(topic, data)
        widgetDataUpdated = true
      }
    }
    
    if (widgetDataUpdated) {
      const newWidgetData = new Map(widgetData.value)
      newWidgetData.set(widget.id, new Map(widgetDataMap))
      widgetData.value = newWidgetData
    }
  })
}

const handleSendMessage = (topic: string, message: string) => {
  if (mqttClient.isConnected()) {
    mqttClient.publish(topic, message)
  }
}

const startUpdateLoop = () => {
  if (updateInterval.value) {
    clearInterval(updateInterval.value)
  }
  
  updateInterval.value = window.setInterval(() => {
    if (!currentProject.value || !mqttClient.isConnected()) return
    
    const allTopics = new Set<string>()
    
    currentProject.value.widgets.forEach((widget: Widget) => {
      if (widget.type === 'lineChart') {
        const config = widget.config as { themes: { topic: string }[] }
        config.themes.forEach(t => {
          if (t.topic) allTopics.add(t.topic)
        })
      }
    })
  }, 2000)
}

const disconnectFromPlatform = () => {
  mqttClient.disconnect()
  isConnected.value = false
  stopHealthCheck()
  if (updateInterval.value) {
    clearInterval(updateInterval.value)
    updateInterval.value = null
  }
}

const startHealthCheck = () => {
  stopHealthCheck()
  healthCheckInterval.value = window.setInterval(() => {
    if (isConnected.value && !mqttClient.isConnected()) {
      console.log('健康检查：MQTT连接已断开')
      isConnected.value = false
      stopHealthCheck()
    }
  }, 5000)
}

const stopHealthCheck = () => {
  if (healthCheckInterval.value) {
    clearInterval(healthCheckInterval.value)
    healthCheckInterval.value = null
  }
}

const handleAddWidget = (type: string, x: number, y: number) => {
  if (!currentProjectId.value || isFullscreen.value) return
  
  const widget = createWidget(type, x, y)
  addWidget(currentProjectId.value, widget)
  widgetData.value.set(widget.id, new Map())
}

const handleUpdateWidget = (widgetId: string, updates: Record<string, unknown>) => {
  if (!currentProjectId.value) return
  updateWidget(currentProjectId.value, widgetId, updates)
}

const handleRemoveWidget = (widgetId: string) => {
  if (!currentProjectId.value || isFullscreen.value) return
  removeWidget(currentProjectId.value, widgetId)
  widgetData.value.delete(widgetId)
}

const handleSidebarUpdate = (updates: Record<string, unknown>) => {
  if (selectedWidgetId.value) {
    handleUpdateWidget(selectedWidgetId.value, updates)
  }
}

const handleClearWidgetData = (widgetId: string) => {
  widgetData.value.delete(widgetId)
  widgetData.value = new Map(widgetData.value)
}

const handleSelectWidget = (widgetId: string | null) => {
  if (isFullscreen.value) {
    selectedWidgetId.value = null
    return
  }
  selectedWidgetId.value = widgetId
}

const handleCreateProject = (name: string) => {
  const project = createProject(name)
  showProjectManager.value = false
  
  if (pendingPlatformConfig.value) {
    updateProject(project.id, { platformConfig: pendingPlatformConfig.value })
    connectToPlatform(pendingPlatformConfig.value)
    pendingPlatformConfig.value = null
  } else if (defaultPlatformConfig.value) {
    updateProject(project.id, { platformConfig: defaultPlatformConfig.value })
  }
}

const handleSelectProject = (projectId: string) => {
  const previousConfig = currentProject.value?.platformConfig
  setCurrentProject(projectId)
  showProjectManager.value = false
  
  const newProject = currentProject.value
  if (newProject?.platformConfig) {
    const needsReconnect = !previousConfig || 
      previousConfig.platform !== newProject.platformConfig.platform
    
    if (needsReconnect && isConnected.value) {
      disconnectFromPlatform()
    }
    
    if (isConnected.value && !needsReconnect) {
      // 相同配置且已连接：只更新订阅主题，不重连
      updateSubscriptions()
    } else if (newProject.platformConfig) {
      connectToPlatform(newProject.platformConfig, true)
    }
  } else if (isConnected.value) {
    // 新项目无配置但已连接：断开
    disconnectFromPlatform()
  } else if (defaultPlatformConfig.value) {
    connectToPlatform(defaultPlatformConfig.value, true)
  }
}

const handleViewProject = (projectId: string) => {
  setCurrentProject(projectId)
  showProjectManager.value = false
  isFullscreen.value = true
  
  const container = document.querySelector('.app-container')
  if (container && !document.fullscreenElement) {
    container.requestFullscreen().catch(err => {
      console.error('全屏请求失败:', err)
    })
  }
  
  const project = currentProject.value
  if (project?.platformConfig) {
    connectToPlatform(project.platformConfig, true)
  } else if (defaultPlatformConfig.value) {
    connectToPlatform(defaultPlatformConfig.value, true)
  }
}

const handleDeleteProject = (projectId: string) => {
  deleteProject(projectId)
  if (!currentProjectId.value) {
    showProjectManager.value = true
  }
}

const handleOpenProjectManager = () => {
  if (isFullscreen.value) {
    if (document.fullscreenElement) {
      document.exitFullscreen().catch(err => {
        console.error('退出全屏失败:', err)
      })
    }
    isFullscreen.value = false
    showTopBar.value = false
  }
  showProjectManager.value = true
}

const toggleFullscreen = () => {
  if (!isFullscreen.value) {
    isFullscreen.value = true
    selectedWidgetId.value = null
    showTopBar.value = false
    
    const container = document.querySelector('.app-container')
    if (container && !document.fullscreenElement) {
      container.requestFullscreen().catch(err => {
        console.error('全屏请求失败:', err)
      })
    }
  } else {
    if (document.fullscreenElement) {
      document.exitFullscreen().catch(err => {
        console.error('退出全屏失败:', err)
      })
    }
    isFullscreen.value = false
    showTopBar.value = false
  }
}

const handleMouseMove = (e: MouseEvent) => {
  if (!isFullscreen.value) return
  
  if (e.clientY <= 20) {
    showTopBar.value = true
    
    if (topBarTimeout) {
      clearTimeout(topBarTimeout)
      topBarTimeout = null
    }
  } else if (e.clientY > 60) {
    if (topBarTimeout) {
      clearTimeout(topBarTimeout)
    }
    topBarTimeout = window.setTimeout(() => {
      showTopBar.value = false
    }, 500)
  }
}

const handleMouseLeave = () => {
  if (isFullscreen.value && topBarTimeout) {
    clearTimeout(topBarTimeout)
  }
  showTopBar.value = false
}

const handlePlatformConfigConfirm = async (config: PlatformConfig) => {
  if (!currentProject.value) {
    pendingPlatformConfig.value = config
  }
  
  if (currentProject.value) {
    updateProject(currentProject.value.id, { platformConfig: config })
  }
  
  defaultPlatformConfig.value = { ...config }
  savePlatformConfig(config)
  
  showPlatformConfig.value = false
  await connectToPlatform(config)
}

watch(() => currentProjectId.value, (newId, oldId) => {
  if (newId && newId !== oldId) {
    const project = projects.value.find((p: Project) => p.id === newId)
    if (project?.platformConfig) {
      const prevProject = oldId ? projects.value.find((p: Project) => p.id === oldId) : null
      const needsReconnect = !prevProject?.platformConfig || 
        prevProject.platformConfig.platform !== project.platformConfig.platform
      
      if (needsReconnect && isConnected.value) {
        disconnectFromPlatform()
      }
      
      if (isConnected.value && !needsReconnect) {
        // 相同配置且已连接：只更新订阅主题，不重连
        updateSubscriptions()
      } else {
        connectToPlatform(project.platformConfig, true)
      }
    }
  }
})

watch(() => currentProject.value?.widgets, () => {
  updateSubscriptions()
}, { deep: true })

provide('mqttClient', mqttClient)
provide('widgetData', widgetData)
provide('sendMessage', handleSendMessage)

onUnmounted(() => {
  disconnectFromPlatform()
  if (topBarTimeout) {
    clearTimeout(topBarTimeout)
  }
  if (defaultPlatformConfig.value) {
    savePlatformConfig(defaultPlatformConfig.value)
  }
})
</script>

<template>
  <div 
    class="app-container" 
    :class="{ 'fullscreen-mode': isFullscreen }"
    @mousemove="handleMouseMove"
    @mouseleave="handleMouseLeave"
  >
    <TopBar
      v-if="isFullscreen"
      :is-visible="showTopBar"
      :is-connected="isConnected"
      :title="headerTitle"
      :project-id="currentProjectId || ''"
      :projects="projects"
      @exit-fullscreen="toggleFullscreen"
      @connect="showPlatformConfig = true"
      @open-project-manager="handleOpenProjectManager"
      @select-project="handleSelectProject"
    />
    
    <Header
      v-if="!isFullscreen"
      :is-connected="isConnected"
      :project-id="currentProjectId || ''"
      :projects="projects"
      :show-fullscreen-btn="!!currentProjectId"
      :show-project-selector="showProjectSelector"
      :is-editor-mode="showEditor"
      :show-project-manager-btn="showProjectManagerBtn"
      @connect="showPlatformConfig = true"
      @disconnect="disconnectFromPlatform"
      @open-project-manager="handleOpenProjectManager"
      @toggle-fullscreen="toggleFullscreen"
      @select-project="handleSelectProject"
    />
    
    <PlatformConfigModal
      v-if="showPlatformConfig"
      :config="currentProject?.platformConfig || defaultPlatformConfig || null"
      @confirm="handlePlatformConfigConfirm"
      @cancel="showPlatformConfig = false"
    />
    
    <ProjectManager
      v-if="showProjectManager"
      :projects="projects"
      @create="handleCreateProject"
      @select="handleSelectProject"
      @view="handleViewProject"
      @delete="handleDeleteProject"
    />
    
    <div v-else class="panel-container">
      <SidebarLeft 
        v-if="showEditor" 
        @add-widget="handleAddWidget" 
      />
      
      <div class="canvas-scroll-wrapper" :class="{ 'editor-mode': showEditor }">
        <MainCanvas
          :widgets="currentProject?.widgets || []"
          :selected-widget-id="selectedWidgetId"
          :widget-data="widgetData"
          :show-controls="showEditor"
          @select-widget="handleSelectWidget"
          @add-widget="handleAddWidget"
          @update-widget="handleUpdateWidget"
          @remove-widget="handleRemoveWidget"
        />
      </div>
      
      <SidebarRight
        v-if="showEditor"
        :widget="selectedWidget"
        :widget-data="widgetData.get(selectedWidgetId || '')"
        @update="handleSidebarUpdate"
        @remove="selectedWidgetId && handleRemoveWidget(selectedWidgetId)"
        @clear-data="selectedWidgetId && handleClearWidgetData(selectedWidgetId)"
      />
    </div>
  </div>
</template>

<style scoped>
.app-container {
  width: 100vw;
  height: 100vh;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  position: relative;
}

.app-container.fullscreen-mode {
  cursor: none;
  width: 100%;
  height: 100%;
  min-height: 100%;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 9999;
}

.app-container.fullscreen-mode .panel-container {
  height: 100%;
  min-height: 100%;
}

.app-container.fullscreen-mode .main-canvas {
  width: 100%;
  height: 100%;
  min-height: 100%;
}

/* 编辑模式：画布滚动容器 */
.canvas-scroll-wrapper {
  flex: 1;
  min-width: 0;
  position: relative;
  overflow: hidden;
  display: flex;
}

.canvas-scroll-wrapper.editor-mode {
  overflow: auto;
}

.canvas-scroll-wrapper.editor-mode .main-canvas {
  min-width: 200%;
  min-height: 200%;
}

.app-container.fullscreen-mode:hover {
  cursor: default;
}
</style>