<script setup lang="ts">
defineProps<{
  isVisible: boolean
  isConnected: boolean
  title: string
  projectId: string
  projects: any[]
}>()

const emit = defineEmits<{
  exitFullscreen: []
  connect: []
  openProjectManager: []
  selectProject: [id: string]
}>()

const handleChangeProject = (e: Event) => {
  const projectId = (e.target as HTMLSelectElement).value
  if (projectId) {
    emit('selectProject', projectId)
  }
}
</script>

<template>
  <div class="top-bar" :class="{ visible: isVisible }">
    <div class="top-bar-left">
      <button 
        class="btn btn-secondary"
        @click="emit('openProjectManager')"
        style="margin-right: 12px;"
      >
        项目管理
      </button>
      <select :value="projectId" class="project-select" @change="handleChangeProject" style="background: rgba(255,255,255,0.2); color: white; border: none; padding: 6px 12px; border-radius: 4px; font-size: 13px;">
        <option v-if="projects.length === 0" value="">未选择项目</option>
        <option v-for="project in projects" :key="project.id" :value="project.id">{{ project.name }}</option>
      </select>
    </div>
    
    <h1 class="top-bar-title">{{ title }}</h1>
    
    <div class="top-bar-right">
      <div class="connection-status" :class="{ connected: isConnected, disconnected: !isConnected }">
        <span class="status-dot" :class="{ connected: isConnected, disconnected: !isConnected }"></span>
        <span>{{ isConnected ? '已连接' : '未连接' }}</span>
      </div>
      
      <button
        class="btn"
        :class="isConnected ? 'btn-danger' : 'btn-success'"
        @click="emit('connect')"
        style="margin-left: 12px;"
      >
        {{ isConnected ? '断开连接' : '连接平台' }}
      </button>
      
      <button 
        class="btn btn-secondary"
        @click="emit('exitFullscreen')"
        style="margin-left: 12px;"
      >
        退出全屏
      </button>
    </div>
  </div>
</template>

<style scoped>
.top-bar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  background: linear-gradient(135deg, #5c9ce6 0%, #4a8fd4 100%);
  color: #fff;
  padding: 0 20px;
  height: 48px;
  display: flex;
  align-items: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
  z-index: 9999;
  transform: translateY(-100%);
  transition: transform 0.3s ease;
}

.top-bar.visible {
  transform: translateY(0);
}

.top-bar-left {
  display: flex;
  align-items: center;
  position: relative;
  z-index: 1;
}

.top-bar-right {
  display: flex;
  align-items: center;
  position: relative;
  z-index: 1;
  margin-left: auto;
}

.top-bar-title {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  font-size: 16px;
  font-weight: 500;
  margin: 0;
  color: #fff;
}

.project-select option {
  color: #333;
}

.connection-status {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 12px;
}

.connection-status.connected {
  background: rgba(102, 187, 106, 0.2);
  color: #a5d6a7;
}

.connection-status.disconnected {
  background: rgba(239, 83, 80, 0.2);
  color: #ef9a9a;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.status-dot.connected {
  background: #66bb6a;
}

.status-dot.disconnected {
  background: #ef5350;
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