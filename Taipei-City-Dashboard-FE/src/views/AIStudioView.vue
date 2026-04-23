<script setup>
import { computed, onBeforeUnmount, ref, watch } from "vue";
import { storeToRefs } from "pinia";
import AIStudioChatPanel from "../components/ai-studio/AIStudioChatPanel.vue";
import DashboardComponent from "../dashboardComponent/DashboardComponent.vue";
import MapContainer from "../components/map/MapContainer.vue";
import { useChatStore } from "../store/chatStore";
import { useContentStore } from "../store/contentStore";
import { useAIStudioStore } from "../store/aiStudioStore";
import { useMapStore } from "../store/mapStore";

const chatStore = useChatStore();
const contentStore = useContentStore();
const aiStudioStore = useAIStudioStore();
const mapStore = useMapStore();

const { chatData } = storeToRefs(chatStore);
const { scene } = storeToRefs(aiStudioStore);
const webUrlInput = ref("https://www.gov.taipei/");

const clearChatConfirm = () => {
	if (confirm("確定要清除所有聊天紀錄並開新的 Chat 嗎？")) {
		chatStore.clearChatHistory();
	}
};
const showSceneJson = ref(false);

const lastBotMessage = computed(() => {
	const list = [...chatData.value];
	return list.reverse().find((item) => item.role === "bot" && !item.isDefault);
});

const latestComponents = computed(() => {
	const components = lastBotMessage.value?.components;
	return Array.isArray(components) ? components : [];
});

const sceneBlocks = computed(() => {
	if (Array.isArray(scene.value.blocks) && scene.value.blocks.length > 0) {
		return scene.value.blocks;
	}
	return latestComponents.value.map((item) => ({
		type: "component",
		title: item.name,
		componentId: item.id,
		componentIndex: item.index,
		city: item.city || "taipei",
	}));
});

const selectedMode = computed(() => scene.value?.layout?.rightPanel?.mode || "components");

const componentCards = computed(() => {
	if (!latestComponents.value.length) return [];
	return latestComponents.value.filter((item) => item?.dashboardConfig);
});

watch(
	lastBotMessage,
	(nextValue) => {
		if (!nextValue) return;
		aiStudioStore.ingestChatResult(nextValue);
	},
	{ immediate: true },
);

onBeforeUnmount(() => {
	mapStore.destroyMapBox();
});
</script>

<template>
  <div class="aistudio">
    <!-- ── LEFT PANEL ── -->
    <aside
      class="aistudio-left"
      :class="{ 'aistudio-left--collapsed': scene.layout.leftPanel.collapsed }"
    >
      <!-- header -->
      <div class="aistudio-left-header">
        <span
          v-if="!scene.layout.leftPanel.collapsed"
          class="aistudio-left-title"
        >
          <span class="icon">smart_toy</span>AI Studio
        </span>
				<div class="aistudio-left-actions">
					<button
						v-if="!scene.layout.leftPanel.collapsed"
						class="icon-btn"
						title="清除聊天紀錄"
						@click="clearChatConfirm"
					>
						<span class="icon">delete_sweep</span>
					</button>
					<button
						class="icon-btn"
						:title="scene.layout.leftPanel.collapsed ? '展開面板' : '收合面板'"
						@click="aiStudioStore.toggleLeftPanel()"
					>
						<span class="icon">{{
							scene.layout.leftPanel.collapsed
								? "keyboard_double_arrow_right"
								: "keyboard_double_arrow_left"
						}}</span>
					</button>
				</div>
      </div>

      <!-- body: hidden when collapsed -->
      <div
        v-if="!scene.layout.leftPanel.collapsed"
        class="aistudio-left-body"
      >
        <!-- Chat -->
        <div class="chat-panel">
          <AIStudioChatPanel />
        </div>
      </div>
    </aside>

    <!-- ── RIGHT PANEL ── -->
    <section class="aistudio-right">

      <!-- canvas area -->
      <div
        class="aistudio-canvas"
        :class="{ 'aistudio-canvas--with-json': showSceneJson }"
      >
        <!-- canvas body -->
        <div class="canvas-body">
          <!-- components mode -->
          <div
            v-if="selectedMode === 'components'"
            class="canvas-inner"
          >
            <div
              v-if="componentCards.length === 0"
              class="canvas-empty"
            >
              <span class="icon canvas-empty-icon">smart_toy</span>
              <p>透過左側 AI 對話取得推薦組件</p>
              <p class="canvas-empty-sub">組件將自動渲染至此畫布</p>
            </div>
            <div
              v-else
              class="component-grid scrollbar-custom"
            >
              <DashboardComponent
                v-for="item in componentCards"
                :key="`${item.id}-${item.city}`"
                :config="item.dashboardConfig"
                :active-city="item.city || item.dashboardConfig.city"
                :city-tag="contentStore.cityManager.getTagList(item.city || item.dashboardConfig.city)"
                :style="{ height: '320px', width: '100%' }"
              />
            </div>
          </div>

          <!-- map mode -->
          <div
            v-else-if="selectedMode === 'map'"
            class="canvas-inner canvas-inner--map"
          >
            <MapContainer />
          </div>

          <!-- web mode -->
          <div
            v-else
            class="canvas-inner canvas-inner--web"
          >
            <iframe
              :title="`web-preview-${webUrlInput}`"
              :src="webUrlInput"
            />
          </div>
        </div>

        <!-- scene json drawer -->
        <div
          v-if="showSceneJson"
          class="scene-json-drawer scrollbar-custom"
        >
          <div class="scene-json-header">
            <span>Scene JSON</span>
            <button
              class="icon-btn"
              @click="showSceneJson = false"
            >
              <span class="icon">close</span>
            </button>
          </div>
          <pre class="scene-json-pre">{{ JSON.stringify({ ...scene, blocks: sceneBlocks }, null, 2) }}</pre>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped lang="scss">
/* ── Design tokens (align with globalStyles.css) ─────────────── */
$bg:          var(--color-background);
$panel-bg:    var(--color-component-background);
$border:      var(--color-border);
$text:        var(--color-normal-text);
$muted:       var(--color-complement-text);
$accent:      var(--color-highlight);
$sidebar-bg:  var(--color-sidebar-bg-start);
$sidebar-border: var(--color-sidebar-border);

$transition: 0.22s cubic-bezier(0.4, 0, 0.2, 1);
$left-w: 360px;

/* ── Root layout ─────────────────────────────────────────────── */
.aistudio {
	display: flex;
	flex-direction: row;
	width: 100%;
	height: 100%;
	background: $bg;
	overflow: hidden;
}

/* ── Icon shorthand ──────────────────────────────────────────── */
.icon {
	font-family: var(--font-icon);
	font-size: 1.1rem;
	line-height: 1;
	display: inline-flex;
	align-items: center;
	user-select: none;
}

/* ── Generic icon button ─────────────────────────────────────── */
.icon-btn {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	width: 32px;
	height: 32px;
	border: none;
	border-radius: 6px;
	background: transparent;
	color: $muted;
	cursor: pointer;
	flex-shrink: 0;
	transition: background $transition, color $transition;

	&:hover {
		background: rgba(255, 255, 255, 0.1);
		color: $text;
	}

	&.active {
		background: rgba($accent, 0.18);
		color: $accent;
	}

	&--accent {
		color: $accent;

		&:hover {
			background: rgba($accent, 0.2);
		}

		&:disabled {
			opacity: 0.35;
			cursor: not-allowed;
		}
	}

	&--danger {
		&:hover {
			background: rgba(248, 113, 113, 0.18);
			color: #f87171;
		}
	}
}

/* ── Left panel ──────────────────────────────────────────────── */
.aistudio-left {
	display: flex;
	flex-direction: column;
	width: $left-w;
	min-width: $left-w;
	background: $sidebar-bg;
	border-right: 1px solid $sidebar-border;
	transition: border-color $transition;
	overflow: hidden;
	flex-shrink: 0;

	&--collapsed {
		width: 48px;
		min-width: 48px;
	}
}

.aistudio-left-header {
	display: flex;
	align-items: center;
	justify-content: space-between;
	height: 48px;
	padding: 0 10px 0 14px;
	border-bottom: 1px solid $sidebar-border;
	flex-shrink: 0;
	gap: 8px;
}

.aistudio-left-actions {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	margin-left: auto;
}

.aistudio-left-title {
	display: flex;
	align-items: center;
	gap: 7px;
	font-size: var(--font-ms);
	font-weight: 600;
	color: $text;
	white-space: nowrap;

	.icon {
		color: $accent;
		font-size: 1.2rem;
	}
}

.aistudio-left-body {
	display: flex;
	flex-direction: column;
	flex: 1;
	min-height: 0;
	overflow: hidden;
}

/* ── Chat panel ──────────────────────────────────────────────── */
.chat-panel {
	flex: 1;
	min-height: 0;
	overflow: hidden;
	display: flex;
	flex-direction: column;
}

/* ── Right panel ─────────────────────────────────────────────── */
.aistudio-right {
	flex: 1;
	min-width: 0;
	display: flex;
	flex-direction: column;
	background: $bg;
	overflow: hidden;
}

/* ── Toolbar ─────────────────────────────────────────────────── */
.aistudio-toolbar {
	display: flex;
	align-items: center;
	justify-content: space-between;
	height: 48px;
	padding: 0 14px;
	background: $panel-bg;
	border-bottom: 1px solid $border;
	flex-shrink: 0;
	gap: 12px;
}

.mode-switch {
	display: flex;
	gap: 4px;
	background: $bg;
	border-radius: 8px;
	padding: 3px;
}

.mode-btn {
	display: inline-flex;
	align-items: center;
	gap: 5px;
	padding: 5px 12px;
	border: none;
	border-radius: 6px;
	background: transparent;
	color: $muted;
	font-size: var(--font-s);
	cursor: pointer;
	transition: background $transition, color $transition;

	.icon { font-size: 1rem; }

	&:hover { color: $text; }

	&.active {
		background: $panel-bg;
		color: $accent;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.35);
	}
}

.toolbar-actions {
	display: flex;
	align-items: center;
	gap: 4px;
	margin-left: auto;
}

/* ── Canvas ──────────────────────────────────────────────────── */
.aistudio-canvas {
	flex: 1;
	min-height: 0;
	display: flex;
	flex-direction: column;
	overflow: hidden;
	position: relative;

	/* web url bar */
	&--with-json {
		.canvas-body {
			flex: 1;
		}
	}
}

.canvas-body {
	flex: 1;
	min-height: 0;
	display: flex;
	flex-direction: column;
	overflow: hidden;
}

.canvas-inner {
	flex: 1;
	min-height: 0;
	overflow: hidden;

	&--map {
		/* MapContainer needs 100% */
	}

	&--web {
		iframe {
			width: 100%;
			height: 100%;
			border: none;
			background: #fff;
			display: block;
		}
	}
}

/* ── Empty state ─────────────────────────────────────────────── */
.canvas-empty {
	height: 100%;
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	gap: 10px;
	color: $muted;

	p {
		margin: 0;
		font-size: var(--font-ms);
		color: $muted;
	}

	&-icon {
		font-size: 2.5rem;
		color: rgba($accent, 0.35);
	}
}

.canvas-empty-sub {
	font-size: var(--font-s) !important;
	opacity: 0.65;
}

/* ── Component grid ──────────────────────────────────────────── */
.component-grid {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
	gap: 14px;
	padding: 14px;
	height: 100%;
	overflow: auto;
	align-content: start;
}

/* ── Scene JSON drawer ───────────────────────────────────────── */
.scene-json-drawer {
	flex-shrink: 0;
	height: 220px;
	min-height: 0;
	border-top: 1px solid $border;
	display: flex;
	flex-direction: column;
	background: $panel-bg;
	overflow: hidden;
}

.scene-json-header {
	display: flex;
	align-items: center;
	justify-content: space-between;
	padding: 6px 12px;
	border-bottom: 1px solid $border;
	font-size: var(--font-s);
	color: $muted;
	flex-shrink: 0;
}

.scene-json-pre {
	flex: 1;
	min-height: 0;
	overflow: auto;
	padding: 10px 14px;
	font-size: 11px;
	font-family: "Monaco", "Courier New", monospace;
	line-height: 1.5;
	color: #93c5fd;
	background: transparent;
	white-space: pre;
}

/* ── Scrollbar ───────────────────────────────────────────────── */
.scrollbar-custom {
	scrollbar-width: thin;
	scrollbar-color: rgba(255, 255, 255, 0.2) transparent;

	&::-webkit-scrollbar { width: 4px; height: 4px; }
	&::-webkit-scrollbar-track { background: transparent; }
	&::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.2); border-radius: 4px; }
}
</style>
