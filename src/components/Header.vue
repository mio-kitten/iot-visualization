<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  isConnected: boolean
  projectId: string
  showFullscreenBtn: boolean
  showProjectSelector: boolean
  projects: any[]
  isEditorMode: boolean
  showProjectManagerBtn: boolean
}>()

const emit = defineEmits<{
  connect: []
  disconnect: []
  openProjectManager: []
  toggleFullscreen: []
  selectProject: [id: string]
}>()

const handleChangeProject = (e: Event) => {
  const projectId = (e.target as HTMLSelectElement).value
  if (projectId) {
    emit('selectProject', projectId)
  }
}

const headerTitle = computed(() => {
  if (!props.projectId || !props.showProjectSelector) {
    return '项目管理'
  }
  return props.isEditorMode ? '编辑模式' : '查看模式'
})
</script>

<template>
  <header class="blue-header">
    <div class="header-left">
      <button v-if="showProjectManagerBtn" class="btn btn-secondary" @click="emit('openProjectManager')" style="margin-right: 12px;">
        项目管理
      </button>
      <select v-if="showProjectSelector" :value="projectId" class="project-select" @change="handleChangeProject" style="background: rgba(255,255,255,0.2); color: white; border: none; padding: 6px 12px; border-radius: 4px; font-size: 13px;">
        <option v-if="projects.length === 0" value="">未选择项目</option>
        <option v-for="project in projects" :key="project.id" :value="project.id">{{ project.name }}</option>
      </select>
    </div>
    
    <h1>{{ headerTitle }}</h1>
    
    <div class="header-right">
      <div class="connection-status" :class="{ connected: isConnected, disconnected: !isConnected }">
        <span class="status-dot" :class="{ connected: isConnected, disconnected: !isConnected }"></span>
        <span>{{ isConnected ? '已连接' : '未连接' }}</span>
      </div>
      
      <button
        class="btn"
        :class="isConnected ? 'btn-danger' : 'btn-success'"
        @click="isConnected ? emit('disconnect') : emit('connect')"
        style="margin-left: 12px;"
      >
        {{ isConnected ? '断开连接' : '连接平台' }}
      </button>
      
      <button 
        v-if="showFullscreenBtn"
        class="btn btn-secondary" 
        style="margin-left: 12px;"
        @click="emit('toggleFullscreen')"
      >
        全屏
      </button>
    </div>
  </header>
</template>

<style scoped>
.header-left {
  display: flex;
  align-items: center;
  position: relative;
  z-index: 1;
}

.header-right {
  display: flex;
  align-items: center;
  position: relative;
  z-index: 1;
}

.blue-header h1 {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  margin: 0;
}

.project-select option {
  color: #333;
}

.btn {
  padding: 8px 16px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 13px;
  transition: all 0.2s;
  font-weight: 500;
}

.btn:hover {
  opacity: 0.88;
}

.btn-success {
  background-color: #66bb6a;
  color: #fff;
}

.btn-danger {
  background-color: #ef5350;
  color: #fff;
}

.btn-secondary {
  background-color: rgba(255, 255, 255, 0.25);
  color: #fff;
}
</style>