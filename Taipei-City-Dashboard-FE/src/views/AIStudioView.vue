<script setup>
import { computed, nextTick, onBeforeUnmount, ref, watch } from "vue";
import { storeToRefs } from "pinia";
import { useRoute, useRouter } from "vue-router";
import AIStudioChatPanel from "../components/ai-studio/AIStudioChatPanel.vue";
import AIStudioPresentationCanvas from "../components/ai-studio/AIStudioPresentationCanvas.vue";
import DashboardComponent from "../dashboardComponent/DashboardComponent.vue";
import MapContainer from "../components/map/MapContainer.vue";
import { useAiStudioChatStore } from "../store/aiStudioChatStore";
import { useContentStore } from "../store/contentStore";
import { useAIStudioStore } from "../store/aiStudioStore";
import { useMapStore } from "../store/mapStore";
import { useAuthStore } from "../store/authStore";
import { useDialogStore } from "../store/dialogStore";

const chatStore = useAiStudioChatStore();
const contentStore = useContentStore();
const aiStudioStore = useAIStudioStore();
const mapStore = useMapStore();
const authStore = useAuthStore();
const dialogStore = useDialogStore();
const route = useRoute();
const router = useRouter();

const { chatData } = storeToRefs(chatStore);
const { user } = storeToRefs(authStore);
const { scene } = storeToRefs(aiStudioStore);
const webUrlInput = ref("https://www.gov.taipei/");

const clearChatConfirm = () => {
	if (confirm("確定要清除所有聊天紀錄並開新的 Chat 嗎？")) {
		chatStore.clearChatHistory();
	}
};
const showSceneJson = ref(false);
const immersiveUiVisible = ref(false);
let immersiveUiTimer = null;

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

const isImmersive = computed(() => route.query.fullscreen === "1");

const selectedModeLabel = computed(() => {
	const modeLabelMap = {
		presentation: "輪播展示",
		components: "圖表牆",
		map: "地圖",
	};

	return modeLabelMap[selectedMode.value] || "AI Studio";
});

const componentCards = computed(() => {
	if (!latestComponents.value.length) return [];
	return latestComponents.value.filter((item) => item?.dashboardConfig);
});

const hasMapComponents = computed(() =>
	componentCards.value.some((item) => {
		const mapConfig = item?.dashboardConfig?.map_config;
		return Array.isArray(mapConfig) && mapConfig.length > 0 && Boolean(mapConfig[0]);
	}),
);

const hasSceneContent = computed(() => {
	const slidesLength = Array.isArray(scene.value?.presentation?.slides)
		? scene.value.presentation.slides.length
		: 0;
	return sceneBlocks.value.length > 0 || componentCards.value.length > 0 || slidesLength > 0;
});

const componentCardHeight = computed(() =>
	isImmersive.value ? "min(52vh, 560px)" : "clamp(260px, 36vh, 460px)",
);

const triggerCanvasResize = () => {
	nextTick(() => {
		requestAnimationFrame(() => {
			window.dispatchEvent(new Event("resize"));
			if (mapStore.map?.resize) {
				mapStore.map.resize();
			}
		});
	});
};

const setImmersiveMode = (nextValue) => {
	const nextQuery = { ...route.query };

	if (nextValue) {
		nextQuery.fullscreen = "1";
	} else {
		delete nextQuery.fullscreen;
	}

	router.replace({ query: nextQuery });
};

const clearImmersiveUiTimer = () => {
	if (immersiveUiTimer) {
		clearTimeout(immersiveUiTimer);
		immersiveUiTimer = null;
	}
};

const handleImmersiveMouseMove = () => {
	if (!isImmersive.value) return;
	immersiveUiVisible.value = true;
	clearImmersiveUiTimer();
	immersiveUiTimer = setTimeout(() => {
		immersiveUiVisible.value = false;
	}, 1500);
};

watch(
	lastBotMessage,
	(nextValue) => {
		if (!nextValue) return;
		aiStudioStore.ingestChatResult(nextValue);
		
		// 如果 ingestion 後產生了 slides，自動切換至 presentation 模式
		if (Array.isArray(scene.value?.presentation?.slides) && scene.value.presentation.slides.length > 0) {
			aiStudioStore.setRightMode("presentation");
		}
	},
	{ immediate: true },
);

watch([selectedMode, isImmersive, () => componentCards.value.length], () => {
	triggerCanvasResize();
}, { flush: "post" });

watch(isImmersive, (nextValue) => {
	if (nextValue) {
		immersiveUiVisible.value = true;
		handleImmersiveMouseMove();
		return;
	}
	immersiveUiVisible.value = false;
	clearImmersiveUiTimer();
});

onBeforeUnmount(() => {
	clearImmersiveUiTimer();
	mapStore.destroyMapBox();
});
</script>

<template>
	<div
		class="aistudio"
		:class="{ 'aistudio--immersive': isImmersive }"
	>
    <!-- ── RIGHT PANEL ── -->
		<section
			class="aistudio-right"
			:class="{ 'aistudio-right--immersive': isImmersive }"
		>
			<div
				v-if="!isImmersive"
				class="aistudio-toolbar"
			>
        <div class="mode-switch">
          <button
            class="mode-btn"
            :class="{ active: selectedMode === 'presentation' }"
            @click="aiStudioStore.setRightMode('presentation')"
          >
            <span class="icon">slideshow</span>
            <span>輪播展示</span>
          </button>
          <button
            class="mode-btn"
            :class="{ active: selectedMode === 'components' }"
            @click="aiStudioStore.setRightMode('components')"
          >
            <span class="icon">dashboard_customize</span>
            <span>圖表牆</span>
          </button>
          <button
            class="mode-btn"
            :class="{ active: selectedMode === 'map' }"
            @click="aiStudioStore.setRightMode('map')"
          >
            <span class="icon">map</span>
            <span>地圖</span>
          </button>
        </div>
        <div class="toolbar-actions">
					<button
						class="icon-btn"
						:title="`全螢幕觀看${selectedModeLabel}`"
						@click="setImmersiveMode(true)"
					>
						<span class="icon">open_in_full</span>
					</button>
          <button
            class="icon-btn"
            :title="showSceneJson ? '隱藏 Scene JSON' : '顯示 Scene JSON'"
            @click="showSceneJson = !showSceneJson"
          >
            <span class="icon">data_object</span>
          </button>
        </div>
      </div>

      <!-- canvas area -->
      <div
        class="aistudio-canvas"
				:class="{
					'aistudio-canvas--with-json': showSceneJson && !isImmersive,
					'aistudio-canvas--immersive': isImmersive,
				}"
				@mousemove="handleImmersiveMouseMove"
      >
				<div
					v-if="isImmersive"
					class="immersive-overlay"
					:class="{ 'immersive-overlay--visible': immersiveUiVisible }"
				>
					<span
						v-if="selectedMode !== 'presentation'"
						class="immersive-badge"
					>{{ selectedModeLabel }}</span>
					<button
						class="icon-btn immersive-exit"
						title="離開全螢幕"
						@click="setImmersiveMode(false)"
					>
						<span class="icon">close_fullscreen</span>
					</button>
				</div>

        <!-- canvas body -->
				<div
					class="canvas-body"
					:class="{ 'canvas-body--immersive': isImmersive }"
				>
				<div
					v-show="selectedMode === 'presentation'"
					class="canvas-inner canvas-inner--presentation"
					:class="{ 'canvas-inner--immersive': isImmersive }"
				>
            <AIStudioPresentationCanvas
              v-if="hasSceneContent"
              :scene="scene"
              :components="componentCards"
              :city-manager="contentStore.cityManager"
						:is-immersive="isImmersive"
            />
            <div
              v-else
              class="canvas-empty"
            >
              <span class="icon canvas-empty-icon">slideshow</span>
              <p>輸入需求後，AI Agent 會自動生成輪播畫面</p>
              <p class="canvas-empty-sub">
                可直接用於校園或政府大螢幕展示
              </p>
            </div>
          </div>

          <!-- components mode -->
				<div
					v-show="selectedMode === 'components'"
					class="canvas-inner"
					:class="{ 'canvas-inner--immersive': isImmersive }"
				>
            <div
              v-if="componentCards.length === 0"
              class="canvas-empty"
            >
              <span class="icon canvas-empty-icon">smart_toy</span>
              <p>透過右側 AI 對話取得推薦組件</p>
              <p class="canvas-empty-sub">
                組件將自動渲染至此畫布
              </p>
            </div>
            <div
              v-else
              class="component-grid scrollbar-custom"
            >
              <div
                v-for="item in componentCards"
                :key="`${item.id}-${item.city}`"
                class="component-card-wrap"
              >
                <DashboardComponent
                  :config="item.dashboardConfig"
                  :active-city="item.city || item.dashboardConfig.city"
                  :city-tag="contentStore.cityManager.getTagList(item.city || item.dashboardConfig.city)"
									:style="{ height: componentCardHeight, width: '100%' }"
                />
              </div>
            </div>
          </div>

          <!-- map mode -->
				<div
					v-show="selectedMode === 'map'"
					class="canvas-inner canvas-inner--map"
					:class="{ 'canvas-inner--immersive': isImmersive }"
				>
					<MapContainer v-if="hasMapComponents" />
					<div v-else class="canvas-empty">
              <span class="icon canvas-empty-icon">map</span>
						<p>目前推薦內容沒有可顯示的地圖圖層</p>
						<p class="canvas-empty-sub">可先請 AI 推薦包含地圖圖層的組件</p>
            </div>
          </div>

          <!-- web mode -->
				<div
					v-show="selectedMode === 'web'"
					class="canvas-inner canvas-inner--web"
					:class="{ 'canvas-inner--immersive': isImmersive }"
				>
            <iframe
              :title="`web-preview-${webUrlInput}`"
              :src="webUrlInput"
            />
          </div>
        </div>

        <!-- scene json drawer -->
        <div
					v-if="showSceneJson && !isImmersive"
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

    <!-- ── CHAT PANEL (right) ── -->
    <aside
			v-if="!isImmersive"
      class="aistudio-left"
      :class="{ 'aistudio-left--collapsed': scene.layout.leftPanel.collapsed }"
    >
      <!-- header -->
      <div class="aistudio-left-header">
        <span
          v-if="!scene.layout.leftPanel.collapsed"
          class="aistudio-left-title"
        >
          AI Studio
        </span>
        <div class="aistudio-left-actions">
          <button
            v-if="!scene.layout.leftPanel.collapsed && user?.is_admin"
            class="icon-btn"
            title="檢視 AI 思考流程 (管理員)"
            @click="dialogStore.showDialog('aiTrace')"
          >
            <span class="icon">psychology</span>
          </button>
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
                ? "keyboard_double_arrow_left"
                : "keyboard_double_arrow_right"
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

	&--immersive {
		background: #050b14;
	}
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
	min-width: 0;
	background: $sidebar-bg;
	border-left: 1px solid $sidebar-border;
	transition: width $transition, min-width $transition, border-color $transition;
	overflow: hidden;
	flex-shrink: 0;

	&--collapsed {
		width: 48px;

		.aistudio-left-header {
			padding: 0;
			justify-content: center;
		}

		.aistudio-left-actions {
			margin-left: 0;
		}
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
	overflow: hidden;
	white-space: nowrap;
}

.aistudio-left-actions {
	display: inline-flex;
	align-items: center;
	gap: 6px;
	margin-left: auto;
	flex-shrink: 0;
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

	&--immersive {
		background: #050b14;
	}
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
	display: grid;
	grid-template-rows: minmax(0, 1fr);
	overflow: hidden;
	position: relative;

	/* web url bar */
	&--with-json {
		grid-template-rows: minmax(0, 1fr) 220px;
	}

	&--immersive {
		background:
			radial-gradient(circle at top, rgba(59, 130, 246, 0.18), transparent 32%),
			linear-gradient(180deg, rgba(5, 11, 20, 0.98) 0%, rgba(5, 11, 20, 1) 100%);
	}
}

.immersive-overlay {
	position: absolute;
	top: 16px;
	right: 16px;
	z-index: 5;
	display: flex;
	align-items: center;
	gap: 10px;
	opacity: 0;
	transition: opacity 0.2s ease;
	pointer-events: none;

	&--visible {
		opacity: 1;
	}
}

.immersive-badge {
	display: inline-flex;
	align-items: center;
	padding: 8px 12px;
	border: 1px solid rgba(148, 163, 184, 0.22);
	border-radius: 999px;
	background: rgba(15, 23, 42, 0.72);
	backdrop-filter: blur(10px);
	color: #e2e8f0;
	font-size: var(--font-s);
	letter-spacing: 0.04em;
	box-shadow: 0 10px 30px rgba(0, 0, 0, 0.28);
	pointer-events: auto;
}

.immersive-exit {
	width: 40px;
	height: 40px;
	border: 1px solid rgba(148, 163, 184, 0.22);
	border-radius: 999px;
	background: rgba(15, 23, 42, 0.72);
	backdrop-filter: blur(10px);
	color: #e2e8f0;
	box-shadow: 0 10px 30px rgba(0, 0, 0, 0.28);
	pointer-events: auto;

	&:hover {
		background: rgba(30, 41, 59, 0.92);
		color: #fff;
	}
}

.canvas-body {
	height: 100%;
	min-height: 0;
	display: flex;
	flex-direction: column;
	overflow: hidden;

	&--immersive {
		padding: 0;
	}
}

.canvas-inner {
	flex: 1;
	min-height: 0;
	overflow: auto;

	&--immersive {
		height: 100%;
	}

	&--map {
		overflow: hidden;
	}

	&--presentation {
		overflow: hidden;
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
	align-content: start;
	min-height: 100%;
}

.component-card-wrap {
	overflow: hidden;
	border-radius: 8px;
}

/* ── Scene JSON drawer ───────────────────────────────────────── */
.scene-json-drawer {
	flex-shrink: 0;
	height: 100%;
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

@media (max-width: 960px) {
	.immersive-overlay {
		top: 12px;
		right: 12px;
		gap: 8px;
	}

	.immersive-badge {
		padding: 6px 10px;
	}
}
</style>
