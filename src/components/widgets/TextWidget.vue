<script setup lang="ts">
import { computed, ref, onMounted, onUnmounted } from 'vue'
import type { DataPoint, ThemeConfig } from '@/types'

const props = defineProps<{
  config: {
    title?: string
    width?: number
    height?: number
    textColor?: string
    topic?: string
    themes?: ThemeConfig[]
  }
  data: Map<string, DataPoint[]>
}>()

const containerRef = ref<HTMLElement | null>(null)
const containerSize = ref({ width: 280, height: 80 })

const updateSize = () => {
  if (containerRef.value) {
    const rect = containerRef.value.getBoundingClientRect()
    containerSize.value = {
      width: rect.width,
      height: rect.height
    }
  }
}

let resizeObserver: ResizeObserver | null = null

onMounted(() => {
  updateSize()
  if (containerRef.value) {
    resizeObserver = new ResizeObserver(updateSize)
    resizeObserver.observe(containerRef.value)
  }
})

onUnmounted(() => {
  if (resizeObserver) {
    resizeObserver.disconnect()
  }
})

const textColor = computed(() => {
  return String(props.config.textColor || '#333333')
})

const fontSize = computed(() => {
  const { width, height } = containerSize.value
  const minSize = 22
  const maxSize = 120
  
  // 根据组件尺寸计算字体大小，取宽高的较小值的一定比例
  const sizeBasedOnWidth = width * 0.18
  const sizeBasedOnHeight = height * 0.5
  
  const calculatedSize = Math.min(sizeBasedOnWidth, sizeBasedOnHeight)
  
  return `${Math.max(minSize, Math.min(calculatedSize, maxSize))}px`
})

const lines = computed(() => {
  const result: { text: string; color?: string }[] = []
  
  if (props.config.themes) {
    props.config.themes.forEach((theme) => {
      if (theme.topic) {
        const points = props.data.get(theme.topic)
        if (points && points.length > 0) {
          const latest = points[points.length - 1]
          result.push({
            text: `${theme.name}: ${String(latest.value)}`,
            color: theme.color
          })
        } else {
          result.push({
            text: `${theme.name}: --`,
            color: theme.color
          })
        }
      }
    })
  } else if (props.config.topic) {
    const points = props.data.get(props.config.topic)
    if (points && points.length > 0) {
      const latest = points[points.length - 1]
      result.push({ text: String(latest.value) })
    } else {
      result.push({ text: '等待数据...' })
    }
  } else {
    result.push({ text: '等待数据...' })
  }
  
  return result
})
</script>

<template>
  <div ref="containerRef" class="text-widget-container">
    <div class="received-lines">
      <div 
        v-for="(line, index) in lines" 
        :key="index" 
        class="line-item"
        :style="{ color: line.color || textColor, fontSize: fontSize }"
      >
        {{ line.text }}
      </div>
    </div>
  </div>
</template>

<style scoped>
.text-widget-container {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 12px;
}

.received-lines {
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100%;
  text-align: center;
}

.line-item {
  font-weight: 500;
  white-space: pre-wrap;
  word-break: break-word;
  line-height: 1.4;
}
</style>