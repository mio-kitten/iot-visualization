<script setup lang="ts">
import { ref } from 'vue'
import type { Project } from '../types'

defineProps<{
  projects: Project[]
}>()

const emit = defineEmits<{
  create: [name: string]
  select: [id: string]
  view: [id: string]
  delete: [id: string]
}>()

const showCreateModal = ref(false)
const newProjectName = ref('')
const deleteConfirmProjectId = ref<string | null>(null)

const handleCreate = () => {
  if (newProjectName.value.trim()) {
    emit('create', newProjectName.value.trim())
    newProjectName.value = ''
    showCreateModal.value = false
  }
}

const formatDate = (dateStr: string) => {
  const date = new Date(dateStr)
  return date.toLocaleString('zh-CN', {
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const handleView = (projectId: string) => {
  emit('view', projectId)
}

const handleDelete = (projectId: string) => {
  deleteConfirmProjectId.value = projectId
}

const confirmDelete = () => {
  if (deleteConfirmProjectId.value) {
    emit('delete', deleteConfirmProjectId.value)
    deleteConfirmProjectId.value = null
  }
}

const cancelDelete = () => {
  deleteConfirmProjectId.value = null
}
</script>

<template>
  <div class="project-manager">
    <div class="project-list-container">
      <div class="pm-header">
        <button class="new-project-btn" @click="showCreateModal = true">
          <span class="plus-icon">+</span>
          <span>新建项目</span>
        </button>
      </div>
      
      <div class="projects-wrapper">
        <div
          v-for="project in projects"
          :key="project.id"
          class="project-item"
        >
          <div class="project-info" @click="emit('select', project.id)">
            <h3>{{ project.name }}</h3>
            <p>最后修改: {{ formatDate(project.updatedAt) }}</p>
          </div>
          <div class="project-actions">
            <button class="action-btn edit-btn" @click.stop="emit('select', project.id)">
              编辑
            </button>
            <button class="action-btn view-btn" @click.stop="handleView(project.id)">
              查看
            </button>
            <button class="action-btn delete-btn" @click.stop="handleDelete(project.id)">
              删除
            </button>
          </div>
        </div>
        
        <div v-if="projects.length === 0" class="empty-state">
          <p>暂无项目</p>
          <p style="font-size: 12px; margin-top: 8px;">点击上方按钮创建新项目</p>
        </div>
      </div>
    </div>
    
    <div v-if="showCreateModal" class="modal-overlay" @click.self="showCreateModal = false">
      <div class="modal-content">
        <div class="modal-header">
          <h2>新建项目</h2>
          <button class="close-btn" @click="showCreateModal = false">×</button>
        </div>
        <div class="modal-body">
          <div class="config-item">
            <label>项目名称</label>
            <input
              v-model="newProjectName"
              type="text"
              placeholder="请输入项目名称"
              @keyup.enter="handleCreate"
            />
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="showCreateModal = false">取消</button>
          <button class="btn btn-success" @click="handleCreate">创建</button>
        </div>
      </div>
    </div>
    
    <div v-if="deleteConfirmProjectId" class="modal-overlay" @click.self="cancelDelete">
      <div class="modal-content">
        <div class="modal-header">
          <h2>确认删除</h2>
          <button class="close-btn" @click="cancelDelete">×</button>
        </div>
        <div class="modal-body">
          <p>确定要删除该项目吗？此操作无法撤销。</p>
        </div>
        <div class="modal-footer">
          <button class="btn btn-secondary" @click="cancelDelete">取消</button>
          <button class="btn btn-danger" @click="confirmDelete">确认删除</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.project-manager {
  width: 100vw;
  height: calc(100vh - 48px);
  background-color: #f0f2f5;
  padding-top: 48px;
}

.project-list-container {
  padding: 20px;
  overflow-y: auto;
  height: 100%;
}

.new-project-btn {
  width: 100%;
  padding: 24px;
  border: 2px dashed #ccc;
  border-radius: 10px;
  background: #fff;
  cursor: pointer;
  color: #666;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  transition: all 0.2s;
  margin-bottom: 20px;
}

.new-project-btn:hover {
  border-color: #5c9ce6;
  color: #5c9ce6;
  background: #f5f9fd;
}

.new-project-btn .plus-icon {
  font-size: 28px;
  font-weight: 300;
}

.projects-wrapper {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.project-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #fff;
  border-radius: 10px;
  padding: 0;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.project-info {
  flex: 1;
  padding: 16px;
  cursor: pointer;
  border: 2px solid transparent;
  border-right: none;
  border-radius: 10px 0 0 10px;
  transition: all 0.2s;
}

.project-info:hover {
  background: #f5f9fd;
  border-color: #5c9ce6;
}

.project-info h3 {
  font-size: 15px;
  font-weight: 600;
  margin-bottom: 4px;
  color: #333;
}

.project-info p {
  font-size: 12px;
  color: #999;
}

.project-actions {
  display: flex;
  gap: 8px;
  padding: 12px 16px;
  border-left: 1px solid #eee;
  opacity: 0;
  transition: opacity 0.3s;
}

.project-item:hover .project-actions {
  opacity: 1;
}

.action-btn {
  padding: 6px 12px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 12px;
  transition: all 0.2s;
  font-weight: 500;
}

.edit-btn {
  background: #e3f2fd;
  color: #5c9ce6;
}

.edit-btn:hover {
  background: #bbdefb;
}

.view-btn {
  background: #e8f5e9;
  color: #4caf50;
}

.view-btn:hover {
  background: #c8e6c9;
}

.delete-btn {
  background: #ffebee;
  color: #ef5350;
}

.delete-btn:hover {
  background: #ffcdd2;
}

.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #999;
}

.empty-state p {
  font-size: 14px;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: #fff;
  border-radius: 10px;
  padding: 24px;
  min-width: 360px;
  max-width: 90vw;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.modal-header h2 {
  font-size: 18px;
  font-weight: 600;
  color: #222;
}

.modal-header .close-btn {
  background: none;
  border: none;
  font-size: 20px;
  cursor: pointer;
  color: #999;
  transition: color 0.2s;
}

.modal-header .close-btn:hover {
  color: #555;
}

.modal-body {
  margin-bottom: 20px;
}

.modal-body p {
  color: #666;
  line-height: 1.6;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.btn {
  padding: 8px 16px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 13px;
  font-weight: 500;
  transition: all 0.2s;
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
  background-color: #e8e8e8;
  color: #444;
}

.config-item {
  margin-bottom: 16px;
}

.config-item label {
  display: block;
  margin-bottom: 6px;
  font-size: 13px;
  color: #555;
  font-weight: 500;
}

.config-item input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 13px;
  transition: border-color 0.2s;
}

.config-item input:focus {
  outline: none;
  border-color: #5c9ce6;
}

.pm-header {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 20px;
}

.pm-header .new-project-btn {
  flex: 1;
  margin-bottom: 0;
}
</style>