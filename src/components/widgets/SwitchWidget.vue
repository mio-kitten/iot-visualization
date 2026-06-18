<script setup lang="ts">
import { ref, inject, watch } from 'vue'
import type { DataPoint } from '@/types'

const props = defineProps<{
  config: {
    topic?: string
    onDisplay?: string
    offDisplay?: string
    onSend?: string
    offSend?: string
  }
  data?: Map<string, DataPoint[]>
}>()

const emit = defineEmits<{
  change: [value: boolean]
}>()

const sendMessage = inject<(topic: string, message: string) => void>('sendMessage')
const isOn = ref(false)

// 监听数据变化更新开关状态
watch(() => props.data, (newData) => {
  if (newData && props.config.topic) {
    const topicData = newData.get(props.config.topic)
    if (topicData && topicData.length > 0) {
      const lastValue = topicData[topicData.length - 1].value
      const strValue = String(lastValue).toLowerCase().trim()
      
      const configuredOnValue = props.config.onSend ? String(props.config.onSend).toLowerCase().trim() : null
      const configuredOffValue = props.config.offSend ? String(props.config.offSend).toLowerCase().trim() : null
      
      if (configuredOnValue && configuredOffValue) {
        // 如果配置了自定义的开/关值，只响应这两个值
        if (strValue === configuredOnValue) {
          isOn.value = true
        } else if (strValue === configuredOffValue) {
          isOn.value = false
        }
        // 其他值忽略，保持当前状态
      } else if (configuredOnValue) {
        // 只配置了开值，收到开值打开，其他关闭
        isOn.value = strValue === configuredOnValue
      } else if (configuredOffValue) {
        // 只配置了关值，收到关值关闭，其他打开
        isOn.value = strValue !== configuredOffValue
      } else {
        // 都没配置，使用默认值
        isOn.value = strValue === 'true' || strValue === '1' || strValue === 'on' || strValue === '开'
      }
    }
  }
}, { deep: true, immediate: true })

const toggle = () => {
  isOn.value = !isOn.value
  emit('change', isOn.value)
  
  if (sendMessage && props.config.topic) {
    const content = isOn.value 
      ? String(props.config.onSend || 'on') 
      : String(props.config.offSend || 'off')
    sendMessage(props.config.topic, content)
  }
}
</script>

<template>
  <div class="widget-switch-container" @click="toggle">
    <div class="switch-track" :class="{ active: isOn }">
      <div class="switch-thumb"></div>
    </div>
    <span class="switch-label">{{ isOn ? (config.onDisplay || '开') : (config.offDisplay || '关') }}</span>
  </div>
</template>

<style scoped>
.widget-switch-container {
  display: flex;
  align-items: center;
  gap: 12px;
  height: 100%;
  padding: 8px;
  cursor: pointer;
}

.switch-track {
  width: 52px;
  height: 28px;
  background: #ddd;
  border-radius: 14px;
  position: relative;
  transition: background-color 0.3s;
}

.switch-track.active {
  background: linear-gradient(135deg, #5c9ce6 0%, #4a8fd4 100%);
}

.switch-thumb {
  position: absolute;
  top: 2px;
  left: 2px;
  width: 24px;
  height: 24px;
  background: white;
  border-radius: 50%;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  transition: transform 0.3s;
}

.switch-track.active .switch-thumb {
  transform: translateX(24px);
}

.switch-label {
  font-size: 14px;
  color: #333;
  font-weight: 500;
}
</style>