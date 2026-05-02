<script setup>
import { computed } from "vue";
import { useDialogStore } from "../../store/dialogStore";
import { useAiStudioChatStore } from "../../store/aiStudioChatStore";
import { useChatStore } from "../../store/chatStore";

const dialogStore = useDialogStore();
const aiStudioStore = useAiStudioChatStore();
const chatStore = useChatStore();

const lastAiMessageWithTimeline = computed(() => {
  // Check both stores, find the one with the most recently added bot message that has a timeline
  const studioMsg = [...aiStudioStore.chatData]
    .reverse()
    .find(m => m.role === 'bot' && m.toolTimeline && m.toolTimeline.length > 0);
    
  const widgetMsg = [...chatStore.chatData]
    .reverse()
    .find(m => m.role === 'bot' && m.toolTimeline && m.toolTimeline.length > 0);

  if (!studioMsg && !widgetMsg) return null;
  if (!studioMsg) return widgetMsg;
  if (!widgetMsg) return studioMsg;

  // Compare by ID (sequence number) or just assume the one that exists is better
  // Since both use IDs like chatData.length + 1, we can't easily compare IDs across stores.
  // One way is to check the meta.latency_ms presence or just return the one from studio if in studio path.
  // For simplicity, let's just return the one that is "newer" in memory if possible, but here we just pick studioMsg first.
  return studioMsg.id > widgetMsg.id ? studioMsg : widgetMsg;
});

const timeline = computed(() => lastAiMessageWithTimeline.value?.toolTimeline || []);
const meta = computed(() => lastAiMessageWithTimeline.value?.meta || {});

const formatTime = (ms) => {
  if (!ms) return "";
  return `${(ms / 1000).toFixed(2)}s`;
};

const getToolColor = (tool) => {
  const colors = {
    'retrieve_components_by_query': '#8b5cf6',
    'get_component_chart_data': '#3b82f6',
    'get_current_time': '#10b981',
    'get_population_summary': '#f59e0b'
  };
  return colors[tool] || '#6b7280';
};
</script>

<template>
  <div
    v-if="dialogStore.dialogs.aiTrace"
    class="dialog-overlay"
    @click.self="dialogStore.dialogs.aiTrace = false"
  >
    <div class="trace-dialog">
      <div class="trace-header">
        <div class="trace-title">
          <span class="material-icons-round">psychology</span>
          AI 思考處理流程 (內部分析)
        </div>
        <button 
          class="trace-close"
          @click="dialogStore.dialogs.aiTrace = false"
        >
          <span class="material-icons-round">close</span>
        </button>
      </div>

      <div class="trace-content">
        <div v-if="!lastAiMessageWithTimeline" class="trace-empty">
           目前沒有最新的 AI 思考流程紀錄。請先在 AI Studio 進行提問。
        </div>

        <div v-else class="trace-body">
          <!-- Meta Info -->
          <div class="trace-meta">
            <div class="meta-item">
              <span class="label">模型</span>
              <span class="value">{{ meta.model || 'N/A' }}</span>
            </div>
            <div class="meta-item">
              <span class="label">總延遲</span>
              <span class="value">{{ formatTime(meta.latency_ms) }}</span>
            </div>
            <div class="meta-item" v-if="meta.usage">
              <span class="label">Token 使用</span>
              <span class="value">Input: {{ meta.usage.prompt_tokens }} / Output: {{ meta.usage.completion_tokens }}</span>
            </div>
          </div>

          <!-- Timeline -->
          <div class="timeline">
            <div 
              v-for="(step, index) in timeline" 
              :key="index"
              class="timeline-step"
            >
              <div class="step-marker" :style="{ backgroundColor: getToolColor(step.tool) }"></div>
              <div class="step-content">
                <div class="step-header">
                  <span class="step-tool">{{ step.tool }}</span>
                  <span class="step-latency">{{ formatTime(step.latency_ms) }}</span>
                </div>
                <div class="step-args">
                  <div class="code-label">Arguments:</div>
                  <pre><code>{{ step.args }}</code></pre>
                </div>
                <div class="step-result">
                  <div class="code-label">Result:</div>
                  <pre><code>{{ step.result }}</code></pre>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.75);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2147483001;
}

.trace-dialog {
  width: 90%;
  max-width: 1000px;
  height: 85vh;
  background: #1a1a1a;
  border: 1px solid #333;
  border-radius: 16px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-shadow: 0 24px 48px rgba(0, 0, 0, 0.5);
}

.trace-header {
  padding: 16px 24px;
  background: #252525;
  border-bottom: 1px solid #333;
  display: flex;
  justify-content: space-between;
  align-items: center;

  .trace-title {
    display: flex;
    align-items: center;
    gap: 10px;
    font-size: 1.1rem;
    font-weight: 500;
    color: #ede9fe;
    
    span { color: #8b5cf6; }
  }

  .trace-close {
    background: transparent;
    color: #888;
    &:hover { color: white; }
  }
}

.trace-content {
  flex: 1;
  overflow-y: auto;
  padding: 24px;
  background: #0f0f0f;
}

.trace-empty {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #666;
  font-size: 1rem;
}

.trace-meta {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 32px;
  padding: 16px;
  background: #1e1e1e;
  border-radius: 12px;
  border: 1px solid #333;

  .meta-item {
    display: flex;
    flex-direction: column;
    gap: 4px;
    
    .label {
      font-size: 0.75rem;
      color: #888;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    .value {
      font-size: 0.95rem;
      color: #ede9fe;
      font-weight: 500;
    }
  }
}

.timeline {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.timeline-step {
  position: relative;
  padding-left: 24px;
  border-left: 2px solid #333;

  .step-marker {
    position: absolute;
    left: -7px;
    top: 0;
    width: 12px;
    height: 12px;
    border-radius: 50%;
    border: 2px solid #0f0f0f;
  }

  .step-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;

    .step-tool {
      font-family: 'Fira Code', monospace;
      font-weight: 600;
      color: #8b5cf6;
      font-size: 1rem;
    }
    .step-latency {
      font-size: 0.85rem;
      color: #666;
    }
  }

  pre {
    background: #1a1a1a;
    padding: 12px;
    border-radius: 8px;
    border: 1px solid #333;
    overflow-x: auto;
    margin-top: 4px;
    
    code {
      font-family: 'Fira Code', monospace;
      font-size: 0.85rem;
      color: #d1d5db;
      white-space: pre-wrap;
    }
  }

  .code-label {
    font-size: 0.75rem;
    color: #555;
    margin-top: 12px;
  }
}
</style>
