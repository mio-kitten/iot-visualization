<script setup lang="ts">
import { ref, watch, inject } from 'vue'

const props = defineProps<{
  config: {
    title?: string
    width?: number
    height?: number
    topic?: string
    placeholder?: string
  }
}>()

const sendMessage = inject<(topic: string, message: string) => void>('sendMessage')

const inputValue = ref('')

const handleSend = () => {
  const topic = String(props.config.topic || '')
  if (inputValue.value.trim() && topic && sendMessage) {
    sendMessage(topic, inputValue.value.trim())
  }
}

const handleKeydown = (e: KeyboardEvent) => {
  if (e.key === 'Enter') {
    handleSend()
  }
}

watch(() => props.config.placeholder, () => {
  inputValue.value = inputValue.value || ''
})
</script>

<template>
  <div class="input-widget">
    <div class="input-container">
      <input
          v-model="inputValue"
          :placeholder="String(config.placeholder || '请输入内容')"
          @keydown="handleKeydown"
          type="text"
          class="input-field"
        />
      <button class="send-btn" @click="handleSend">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2">
          <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
        </svg>
      </button>
    </div>
  </div>
</template>

<style scoped>
.input-widget {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 8px;
}

.input-container {
  display: flex;
  gap: 8px;
  width: 100%;
  max-width: 300px;
}

.input-field {
  flex: 1;
  padding: 8px 12px;
  border: 1px solid #e0e0e0;
  border-radius: 4px;
  font-size: 14px;
  outline: none;
  transition: border-color 0.2s;
}

.input-field:focus {
  border-color: #5c9ce6;
}

.input-field::placeholder {
  color: #999;
}

.send-btn {
  padding: 8px 16px;
  background: linear-gradient(135deg, #5c9ce6 0%, #4a8fd4 100%);
  border: none;
  border-radius: 4px;
  color: white;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: opacity 0.2s;
}

.send-btn:hover {
  opacity: 0.9;
}

.send-btn:active {
  opacity: 0.8;
}
</style>