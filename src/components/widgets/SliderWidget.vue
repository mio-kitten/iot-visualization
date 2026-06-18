<script setup lang="ts">
import { ref, watch, inject } from 'vue'

const props = defineProps<{
  config: {
    minValue?: number
    maxValue?: number
    step?: number
    topic?: string
  }
}>()

const emit = defineEmits<{
  change: [value: number]
}>()

const sendMessage = inject<(topic: string, message: string) => void>('sendMessage')

const minValue = Number(props.config.minValue) || 0
const maxValue = Number(props.config.maxValue) || 100
const step = Number(props.config.step) || 1

const value = ref((minValue + maxValue) / 2)
const isDragging = ref(false)

const handleInput = (event: Event) => {
  const target = event.target as HTMLInputElement
  value.value = parseFloat(target.value)
}

const handleChange = () => {
  emit('change', value.value)
  if (sendMessage && props.config.topic) {
    sendMessage(props.config.topic, value.value.toString())
  }
}

const handleMouseDown = () => {
  isDragging.value = true
}

const handleMouseUp = () => {
  isDragging.value = false
  handleChange()
}

watch(() => props.config, (newConfig) => {
  const newMin = Number(newConfig.minValue) || 0
  const newMax = Number(newConfig.maxValue) || 100
  value.value = Math.max(newMin, Math.min(value.value, newMax))
}, { deep: true })
</script>

<template>
  <div class="widget-slider-container">
    <div class="slider-value">{{ value.toFixed(1) }}</div>
    <input
      type="range"
      :min="minValue"
      :max="maxValue"
      :step="step"
      :value="value"
      class="slider-input"
      @input="handleInput"
      @change="handleChange"
      @mousedown="handleMouseDown"
      @mouseup="handleMouseUp"
      @mouseleave="handleMouseUp"
    />
    <div class="slider-labels">
      <span>{{ minValue }}</span>
      <span>{{ maxValue }}</span>
    </div>
  </div>
</template>

<style scoped>
.widget-slider-container {
  height: 100%;
  padding: 12px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 8px;
}

.slider-value {
  font-size: 24px;
  font-weight: 600;
  color: #5c9ce6;
  text-align: center;
}

.slider-input {
  width: 100%;
  height: 6px;
  -webkit-appearance: none;
  appearance: none;
  background: linear-gradient(90deg, #5c9ce6 0%, #ddd 0%);
  border-radius: 3px;
  cursor: pointer;
}

.slider-input::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 20px;
  height: 20px;
  background: white;
  border-radius: 50%;
  border: 2px solid #5c9ce6;
  cursor: pointer;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  transition: transform 0.2s;
}

.slider-input::-webkit-slider-thumb:hover {
  transform: scale(1.1);
}

.slider-input::-moz-range-thumb {
  width: 20px;
  height: 20px;
  background: white;
  border-radius: 50%;
  border: 2px solid #5c9ce6;
  cursor: pointer;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.slider-labels {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: #999;
}
</style>