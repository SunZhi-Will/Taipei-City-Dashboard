<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from "vue";
import DashboardComponent from "../../dashboardComponent/DashboardComponent.vue";
import { useMapStore } from "../../store/mapStore";

const props = defineProps({
	scene: {
		type: Object,
		required: true,
	},
	components: {
		type: Array,
		default: () => [],
	},
	cityManager: {
		type: Object,
		default: null,
	},
	isImmersive: {
		type: Boolean,
		default: false,
	},
});

const mapStore = useMapStore();

const activeIndex = ref(0);
const isPlaying = ref(true);
let timer = null;

const progressWidth = ref(0);
const progressDuration = ref(0);
const progressRunKey = ref(0);
const controlsVisible = ref(false);
let controlsTimer = null;

const resolvedIndustry = computed(() => props.scene?.presentation?.industry || "general");
const autoplayMs = computed(() => {
	const duration = Number(props.scene?.presentation?.autoplay?.intervalMs || 10000);
	return Number.isFinite(duration) && duration >= 2000 ? duration : 10000;
});
const strictRender = computed(() => Boolean(props.scene?.presentation?.strictRender));

const themeClass = computed(() => `industry-${resolvedIndustry.value}`);

const hasMapConfig = (config) =>
	Array.isArray(config?.map_config) && config.map_config.length > 0 && Boolean(config.map_config[0]);

const toSlideComponentId = (value) => String(value ?? "");

const buildAutoComponentSlides = (components) => {
	const result = [];
	components.forEach((item, index) => {
		const types = item?.dashboardConfig?.chart_config?.types;
		if (Array.isArray(types) && types.length > 1) {
			// 一個組件有多圖表類型 → 每種圖表各產生一張投影片
			types.forEach((chartType) => {
				result.push({
					id: `auto-${item?.id || index}-${chartType}`,
					type: 'component',
					title: item?.name || `重點指標 ${index + 1}`,
					subtitle: item?.dashboardConfig?.short_desc || 'AI 精選重點圖表',
					focusComponentId: item?.id,
					chartType,
					durationSec: 12,
				});
			});
		} else {
			result.push({
				id: `auto-${item?.id || index}`,
				type: 'component',
				title: item?.name || `重點指標 ${index + 1}`,
				subtitle: item?.dashboardConfig?.short_desc || 'AI 精選重點圖表',
				focusComponentId: item?.id,
				chartType: Array.isArray(types) ? types[0] : undefined,
				durationSec: 12,
			});
		}
	});
	return result;
};

const slides = computed(() => {
	const explicitSlides = Array.isArray(props.scene?.presentation?.slides)
		? props.scene.presentation.slides
		: [];

	const components = Array.isArray(props.components) ? props.components : [];
	const componentSlides = buildAutoComponentSlides(components);

	if (explicitSlides.length > 0) {
		if (strictRender.value) {
			return explicitSlides;
		}

		const explicitFocusIdSet = new Set(
			explicitSlides.map((slide) => toSlideComponentId(slide?.focusComponentId)).filter(Boolean),
		);
		const missingSlides = componentSlides.filter(
			(slide) => !explicitFocusIdSet.has(toSlideComponentId(slide.focusComponentId)),
		);
		return [...explicitSlides, ...missingSlides];
	}

	if (components.length === 0) {
		return [
			{
				id: "default-hero",
				type: "hero",
				title: props.scene?.title || "AI 展示畫面",
				subtitle: props.scene?.objective || "請在左側輸入需求，AI 將自動生成輪播內容。",
				durationSec: 10,
			},
		];
	}

	// 戰情室模式：有組件時直接輪播內容，無首頁包裝
	return componentSlides;
});

const componentById = computed(() => {
	const map = new Map();
	for (const item of props.components || []) {
		if (item?.id) map.set(toSlideComponentId(item.id), item);
	}
	return map;
});

const componentByName = computed(() => {
	const map = new Map();
	for (const item of props.components || []) {
		const key = String(item?.name || "").trim();
		if (key && !map.has(key)) {
			map.set(key, item);
		}
	}
	return map;
});

const getSlideComponent = (slide, slideIndex = 0) => {
	if (!["component", "map"].includes(slide?.type)) return null;

	const byId = componentById.value.get(toSlideComponentId(slide?.focusComponentId));
	if (byId) return byId;

	const byTitle = componentByName.value.get(String(slide?.title || "").trim());
	if (byTitle) return byTitle;

	const list = Array.isArray(props.components) ? props.components : [];
	if (list.length === 0) return null;

	const fallbackIndex = Math.max(slideIndex - 1, 0);
	return list[fallbackIndex] || list[0] || null;
};

const isUnknownSlideType = (slide) => !["hero", "component_explain", "component", "map"].includes(slide?.type);

const syncMapLayersForSlide = (slide) => {
	if (slide?.type !== "map") return;
	const targetComponent = getSlideComponent(slide, activeIndex.value);
	const mapConfig = targetComponent?.dashboardConfig?.map_config;
	if (!Array.isArray(mapConfig) || mapConfig.length === 0 || !mapConfig[0]) return;

	const activeCity = targetComponent?.city || targetComponent?.dashboardConfig?.city || "taipei";
	const setupMapLayers = () => {
		mapStore.updateMapViewForCity(activeCity);
		mapStore.addToMapLayerList(mapConfig);
	};

	if (mapStore.map?.loaded?.()) {
		setupMapLayers();
		return;
	}

	mapStore.map?.once?.("load", setupMapLayers);
};

const trackStyle = computed(() => ({
	transform: `translateX(-${activeIndex.value * 100}%)`,
}));

const clearTimer = () => {
	if (timer) {
		clearInterval(timer);
		timer = null;
	}
};

const clearControlsTimer = () => {
	if (controlsTimer) {
		clearTimeout(controlsTimer);
		controlsTimer = null;
	}
};

const handlePointerActivity = () => {
	if (!props.isImmersive) return;
	controlsVisible.value = true;
	clearControlsTimer();
	controlsTimer = setTimeout(() => {
		controlsVisible.value = false;
	}, 1500);
};

const nextSlide = (options = {}) => {
	if (slides.value.length <= 1) return;
	const { resetAutoplay = false } = options;
	activeIndex.value = (activeIndex.value + 1) % slides.value.length;
	if (resetAutoplay) {
		setupTimer();
	}
};

const prevSlide = (options = {}) => {
	if (slides.value.length <= 1) return;
	const { resetAutoplay = true } = options;
	activeIndex.value = (activeIndex.value - 1 + slides.value.length) % slides.value.length;
	if (resetAutoplay) {
		setupTimer();
	}
};

const jumpTo = (index, options = {}) => {
	if (index < 0 || index >= slides.value.length) return;
	const { resetAutoplay = true } = options;
	activeIndex.value = index;
	if (resetAutoplay) {
		setupTimer();
	}
};

const resetProgress = () => {
	progressWidth.value = 0;
	progressDuration.value = 0;
	progressRunKey.value += 1;
	const enabled = Boolean(props.scene?.presentation?.autoplay?.enabled);
	if (!enabled || !isPlaying.value || slides.value.length <= 1) return;
	requestAnimationFrame(() => {
		requestAnimationFrame(() => {
			progressDuration.value = autoplayMs.value;
			progressWidth.value = 100;
		});
	});
};

const setupTimer = () => {
	clearTimer();
	const enabled = Boolean(props.scene?.presentation?.autoplay?.enabled);
	if (!enabled || !isPlaying.value || slides.value.length <= 1) return;
	timer = setInterval(() => {
		nextSlide();
	}, autoplayMs.value);
};

watch([slides, autoplayMs, isPlaying, () => props.scene?.presentation?.autoplay?.enabled], () => {
	if (activeIndex.value >= slides.value.length) {
		activeIndex.value = 0;
	}
	setupTimer();
	resetProgress();
});

watch(activeIndex, (newVal) => {
	resetProgress();
	syncMapLayersForSlide(slides.value[newVal]);
}, { immediate: true });

watch(() => props.isImmersive, (nextValue) => {
	if (nextValue) {
		controlsVisible.value = true;
		handlePointerActivity();
		return;
	}
	controlsVisible.value = true;
	clearControlsTimer();
}, { immediate: true });

onMounted(() => {
	setupTimer();
});

onBeforeUnmount(() => {
	clearTimer();
	clearControlsTimer();
});
</script>

<template>
  <div
    class="presentation-canvas"
    :class="themeClass"
		@mousemove="handlePointerActivity"
  >
    <div class="presentation-stage">
      <div
        class="presentation-track"
        :style="trackStyle"
      >
        <section
          v-for="(slide, index) in slides"
          :key="slide.id || index"
          class="presentation-slide"
          :class="{ 
            'is-active': index === activeIndex,
            'is-prev': index < activeIndex,
            'is-next': index > activeIndex 
          }"
        >
          <div class="slide-inner-stage">
						<div
							class="slide-glass-panel"
							:class="{ 'slide-glass-panel--component': slide.type === 'component' }"
						>
              <div class="panel-border-glow" />
              <div class="panel-noise" />
              
							<div
								class="slide-content"
								:class="{
								'slide-content--component': slide.type === 'component' || slide.type === 'map',
									'slide-content--hero': slide.type === 'hero' || slide.type === 'component_explain' || isUnknownSlideType(slide),
								}"
							>
                <div class="slide-header">
                  <div class="slide-pagination">
                    <span class="current">{{ String(index + 1).padStart(2, '0') }}</span>
                    <span class="separator">/</span>
                    <span class="total">{{ String(slides.length).padStart(2, '0') }}</span>
                  </div>
                </div>

								<div
									class="slide-main"
									:class="{
									'slide-main--component': slide.type === 'component' || slide.type === 'map',
										'slide-main--hero': slide.type === 'hero' || slide.type === 'component_explain' || isUnknownSlideType(slide),
									}"
								>
									<div
										v-if="slide.type === 'hero'"
										class="slide-info slide-info--hero"
									>
                    <h2 class="slide-title">
                      {{ slide.title || scene.title }}
                    </h2>
                    <p
                      v-if="slide.subtitle"
                      class="slide-subtitle"
                    >
                      {{ slide.subtitle }}
                    </p>
                  </div>

								<div
									v-if="slide.type === 'component_explain'"
									class="slide-info slide-info--hero"
								>
									<h2 class="slide-title">
										{{ slide.title || '組件說明' }}
									</h2>
									<p
										v-if="slide.subtitle"
										class="slide-subtitle"
									>
										{{ slide.subtitle }}
									</p>
									<p class="slide-subtitle">
										{{ getSlideComponent(slide, index)?.dashboardConfig?.short_desc || '可切換到圖表牆查看完整組件內容與互動細節。' }}
									</p>
								</div>

<!-- component / map 投影片：統一渲染 DashboardComponent -->
                  <div
								v-if="(slide.type === 'component' || slide.type === 'map') && getSlideComponent(slide, index)?.dashboardConfig"
                    class="slide-chart-container"
                  >
								<div class="slide-component-meta">
									<h3 class="slide-component-title">
										{{ slide.title || getSlideComponent(slide, index)?.name || "重點圖表" }}
									</h3>
									<p
										v-if="slide.subtitle"
										class="slide-component-subtitle"
									>
										{{ slide.subtitle }}
									</p>
								</div>
                    <div class="chart-glass-base">
                      <DashboardComponent
										:config="getSlideComponent(slide, index).dashboardConfig"
										:active-city="getSlideComponent(slide, index).city || getSlideComponent(slide, index).dashboardConfig.city"
										:city-tag="cityManager?.getTagList(getSlideComponent(slide, index).city || getSlideComponent(slide, index).dashboardConfig.city)"
										:presentation-mode="true"
										:initial-chart-type="slide.chartType || ''"
                        :style="{ height: '100%', width: '100%' }"
                      />
                    </div>
                  </div>

								<div
									v-if="(slide.type === 'component' || slide.type === 'map') && !getSlideComponent(slide, index)?.dashboardConfig"
									class="slide-component-empty"
								>
									<h3>{{ slide.title || '圖表準備中' }}</h3>
									<p>此投影片對應的組件資料尚未完成載入，請稍後重試或切換回圖表牆檢查。</p>
								</div>

									<div
										v-if="isUnknownSlideType(slide)"
										class="slide-info slide-info--hero"
									>
										<h2 class="slide-title">
											{{ slide.title || '展示頁內容準備中' }}
										</h2>
										<p class="slide-subtitle">
											{{ slide.subtitle || '此頁的投影片型別尚未定義渲染規則，已改為文字頁顯示。' }}
										</p>
									</div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>

    <!-- Controls -->
    <div
			class="controls-layer"
			:class="{ 'controls-layer--hidden': isImmersive && !controlsVisible }"
			v-if="slides.length > 1"
		>
      <button
        class="glass-control prev"
        aria-label="Previous"
				@click="prevSlide({ resetAutoplay: true })"
      >
        <span class="material-icons-round">chevron_left</span>
      </button>

      <div class="dots-navigation">
        <button
          v-for="(slide, index) in slides"
          :key="`dot-${slide.id || index}`"
          class="nav-dot"
          :class="{ active: index === activeIndex }"
					@click="jumpTo(index, { resetAutoplay: true })"
        />
      </div>

      <button
        class="glass-control next"
        aria-label="Next"
				@click="nextSlide({ resetAutoplay: true })"
      >
        <span class="material-icons-round">chevron_right</span>
      </button>
    </div>

    <!-- Play/Pause & Progress -->
    <div class="status-footer">
      <div class="progress-container">
        <div
			:key="progressRunKey"
          class="progress-fill"
          :style="{ width: progressWidth + '%', transitionDuration: progressDuration + 'ms' }"
        />
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
/* ── Variables & Tokens ───────────────────────────────────────── */
$accent: #38bdf8;
$accent-glow: rgba(56, 189, 248, 0.4);
$glass-bg: rgba(15, 23, 42, 0.45);
$glass-border: rgba(255, 255, 255, 0.12);
$text-bright: #f8fafc;
$text-dim: #94a3b8;

/* ── Base Container ──────────────────────────────────────────── */
.presentation-canvas {
	position: relative;
	height: 100%;
	width: 100%;
	display: flex;
	flex-direction: column;
	background: #020617;
	color: $text-bright;
	overflow: hidden;
	font-family: "Outfit", "Inter", sans-serif;
	perspective: 1200px;
}

/* ── Industry Themes ─────────────────────────────────────────── */
.presentation-canvas.industry-transport {
	background:
		radial-gradient(circle at 80% 20%, rgba(16, 185, 129, 0.18) 0%, transparent 45%),
		radial-gradient(circle at 20% 80%, rgba(20, 184, 166, 0.15) 0%, transparent 45%);
}

.presentation-canvas.industry-senior-care {
	background:
		radial-gradient(circle at 20% 20%, rgba(245, 158, 11, 0.15) 0%, transparent 45%),
		radial-gradient(circle at 80% 80%, rgba(217, 119, 6, 0.12) 0%, transparent 45%);
}

.presentation-canvas.industry-education {
	background:
		radial-gradient(circle at 75% 15%, rgba(96, 165, 250, 0.2) 0%, transparent 45%),
		radial-gradient(circle at 25% 85%, rgba(59, 130, 246, 0.15) 0%, transparent 45%);
}

.presentation-canvas.industry-health {
	background:
		radial-gradient(circle at 15% 15%, rgba(248, 113, 113, 0.15) 0%, transparent 45%),
		radial-gradient(circle at 85% 85%, rgba(239, 68, 68, 0.12) 0%, transparent 45%);
}

/* ── Stage & Track ───────────────────────────────────────────── */
.presentation-stage {
	position: relative;
	flex: 1;
	min-height: 0;
	z-index: 10;
	overflow: hidden;
}

.presentation-track {
	display: flex;
	height: 100%;
	min-height: 0;
	transition: transform 0.85s cubic-bezier(0.2, 0.8, 0.2, 1);
	transform-style: preserve-3d;
}

/* ── Slide Styling ───────────────────────────────────────────── */
.presentation-slide {
	position: relative;
	min-width: 100%;
	height: 100%;
	display: flex;
	padding: 10px 12px 18px;
	box-sizing: border-box;
	transition: opacity 0.8s ease, transform 0.85s cubic-bezier(0.2, 0.8, 0.2, 1);
	opacity: 0.15;
	transform: scale(0.85) translateZ(-100px);

	&.is-active {
		opacity: 1;
		transform: scale(1) translateZ(0);
	}

	&.is-prev {
		transform: rotateY(15deg) scale(0.9) translateZ(-50px);
	}
	
	&.is-next {
		transform: rotateY(-15deg) scale(0.9) translateZ(-50px);
	}
}

.slide-inner-stage {
	width: 100%;
	height: 100%;
	display: flex;
	align-items: center;
	justify-content: center;
}

.slide-glass-panel {
	position: relative;
	width: 100%;
	max-width: none;
	height: 100%;
	background: rgba(15, 23, 42, 0.84);
	backdrop-filter: blur(8px);
	border: 1px solid rgba(255, 255, 255, 0.06);
	border-radius: 18px;
	box-shadow: 
		0 10px 24px rgba(0, 0, 0, 0.28);
	overflow: hidden;
	display: flex;
	flex-direction: column;

	&--component {
		max-width: none;
	}
}

.panel-border-glow {
	display: none;
}

.panel-noise {
	display: none;
}

/* ── Content ─────────────────────────────────────────────── */
.slide-content {
	flex: 1;
	position: relative;
	display: flex;
	flex-direction: column;
	padding: 22px 16px 16px;
	gap: 10px;

	&--hero {
		padding: 10px 16px 14px;
	}

	&--component {
		padding: 20px 12px 12px;
		gap: 8px;
	}
}

.slide-header {
	position: absolute;
	top: 6px;
	right: 12px;
	z-index: 2;
	display: flex;
	justify-content: flex-end;
	align-items: center;
	animation: slideUp 0.6s cubic-bezier(0.23, 1, 0.32, 1) both;
}

.slide-pagination {
	font-family: "JetBrains Mono", monospace;
	font-size: 12px;
	color: rgba(148, 163, 184, 0.78);
	display: flex;
	align-items: center;
	gap: 4px;
	padding: 2px 0;

	.current { color: $accent; font-weight: 700; }
	.separator { opacity: 0.3; }
}

.slide-main {
	flex: 1;
	display: flex;
	flex-direction: column;
	gap: 24px;
	min-height: 0;

	&--component {
		gap: 8px;
	}

	&--map {
		gap: 8px;
	}

	&--hero {
		display: grid;
		place-items: center;
		padding: 0 0 clamp(28px, 5vh, 56px);
	}
}

.slide-map-container {
	flex: 1;
	min-height: 0;
	background: rgba(2, 6, 23, 0.24);
	border-radius: 14px;
	border: 1px solid rgba(255, 255, 255, 0.04);
	overflow: hidden;
	display: flex;
	flex-direction: column;
	animation: slideUpScale 0.8s cubic-bezier(0.23, 1, 0.32, 1) 0.3s both;
}

.slide-map-placeholder {
	flex: 1;
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	padding: 24px;
	text-align: center;
	color: rgba(226, 232, 240, 0.9);

	&__title {
		margin: 0;
		font-size: 1.05rem;
		font-weight: 700;
	}

	&__desc {
		margin: 8px 0 0;
		max-width: 560px;
		font-size: 0.92rem;
		line-height: 1.6;
		color: rgba(148, 163, 184, 0.95);
	}
}

.slide-component-empty {
	flex: 1;
	min-height: 0;
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	text-align: center;
	padding: 20px;
	border-radius: 14px;
	background: rgba(15, 23, 42, 0.42);
	border: 1px dashed rgba(148, 163, 184, 0.45);

	h3 {
		margin: 0;
		font-size: 1.05rem;
		font-weight: 700;
		color: rgba(248, 250, 252, 0.98);
	}

	p {
		margin: 8px 0 0;
		max-width: 640px;
		font-size: 0.9rem;
		line-height: 1.6;
		color: rgba(148, 163, 184, 0.95);
	}
}

.slide-info {
	display: flex;
	flex-direction: column;
	gap: 0;
	max-width: 840px;

	&--hero {
		max-width: 700px;
		margin: 0 auto;
		text-align: center;
		transform: translateY(clamp(-18px, -3.6vh, -42px));
	}
}

.slide-title {
	margin: 0;
	font-size: clamp(1.6rem, 2.5vw, 2.2rem);
	font-weight: 800;
	line-height: 1.15;
	letter-spacing: -0.02em;
	color: #f8fafc;
	animation: slideUp 0.7s cubic-bezier(0.23, 1, 0.32, 1) 0.1s both;
}

.slide-subtitle {
	margin: 8px 0 0;
	font-size: clamp(0.95rem, 1.1vw, 1.05rem);
	color: $text-dim;
	max-width: 680px;
	line-height: 1.5;
	animation: slideUp 0.7s cubic-bezier(0.23, 1, 0.32, 1) 0.2s both;
}

.slide-chart-container {
	flex: 1;
	min-height: 0;
	background: rgba(2, 6, 23, 0.24);
	border-radius: 14px;
	border: 1px solid rgba(255,255,255,0.04);
	overflow: hidden;
	display: grid;
	grid-template-rows: auto minmax(0, 1fr);
	animation: slideUpScale 0.8s cubic-bezier(0.23, 1, 0.32, 1) 0.3s both;
}

.slide-component-meta {
	padding: 8px 10px 0;
	display: flex;
	flex-direction: column;
	gap: 2px;
	flex-shrink: 0;
}

.slide-component-title {
	margin: 0;
	font-size: 1rem;
	font-weight: 700;
	line-height: 1.25;
	color: #f1f5f9;
}

.slide-component-subtitle {
	margin: 0;
	font-size: 0.82rem;
	line-height: 1.35;
	color: rgba(148, 163, 184, 0.95);
	display: -webkit-box;
	-webkit-line-clamp: 2;
	-webkit-box-orient: vertical;
	overflow: hidden;
}

.chart-glass-base {
	width: 100%;
	flex: 1;
	min-height: 0;
	padding: 6px 8px 8px;
	box-sizing: border-box;
}

.slide-chart-container :deep(.dashboardcomponent-fullscreen-container) {
	height: 100%;
}

.slide-chart-container :deep(.dashboardcomponent) {
	height: 100% !important;
	min-height: 0 !important;
	border: none !important;
	box-shadow: none !important;
	background: transparent !important;
	padding: 0 !important;
}

.slide-chart-container :deep(.dashboardcomponent-header) {
	display: none !important;
}

.slide-chart-container :deep(.dashboardcomponent-header h3) {
	font-size: 1.02rem;
	line-height: 1.2;
}

.slide-chart-container :deep(.dashboardcomponent-header h4) {
	font-size: 0.78rem;
	line-height: 1.2;
	opacity: 0.8;
}

.slide-chart-container :deep(.dashboardcomponent-control) {
	display: none !important;
}

.slide-chart-container :deep(.dashboardcomponent-header-button),
.slide-chart-container :deep(.dashboardcomponent-footer),
.slide-chart-container :deep(.fullscreen-btn) {
	display: none !important;
}

.slide-chart-container :deep(.dashboardcomponent-chart) {
	height: 100% !important;
	max-height: none !important;
	min-height: 0 !important;
	padding-top: 0 !important;
	overflow: hidden !important;
}

.slide-chart-container :deep(.donutchart) {
	height: 100% !important;
	width: 100% !important;
}

/* ── Controls ──────────────────────────────────────────── */
.controls-layer {
	position: absolute;
	inset: 0;
	pointer-events: none;
	display: flex;
	align-items: center;
	justify-content: space-between;
	padding: 0 10px;
	z-index: 50;
	opacity: 1;
	transition: opacity 0.2s ease;

	&--hidden {
		opacity: 0;

		.glass-control,
		.dots-navigation {
			pointer-events: none !important;
		}
	}
}

.glass-control {
	width: 38px;
	height: 38px;
	border-radius: 50%;
	background: rgba(15, 23, 42, 0.72);
	backdrop-filter: blur(6px);
	border: 1px solid rgba(255,255,255,0.08);
	color: #fff;
	display: flex;
	align-items: center;
	justify-content: center;
	cursor: pointer;
	pointer-events: auto;
	transition: all 0.3s;
	
	&:hover {
		background: rgba($accent, 0.8);
		transform: scale(1.04);
		border-color: transparent;
	}
	
	span { font-size: 22px; }
}

.dots-navigation {
	position: absolute;
	bottom: 20px;
	left: 50%;
	transform: translateX(-50%);
	display: flex;
	gap: 8px;
	pointer-events: auto;
}

.nav-dot {
	width: 8px;
	height: 8px;
	border-radius: 50%;
	background: rgba(255,255,255,0.2);
	border: none;
	cursor: pointer;
	transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
	
	&.active {
		background: $accent;
			transform: scale(1.25);
			box-shadow: 0 0 10px $accent-glow;
	}
}

/* ── Status Footer ─────────────────────────────────────── */
.status-footer {
	position: absolute;
	bottom: 0;
	left: 0;
	right: 0;
	height: 4px;
	z-index: 60;
}

.progress-container {
	width: 100%;
	height: 100%;
	background: rgba(255,255,255,0.05);
}

.progress-fill {
	height: 100%;
	background: linear-gradient(90deg, $accent, #818cf8);
	width: 0;
	transition-property: width;
	transition-timing-function: linear;
}

/* ── Animations ────────────────────────────────────────── */
@keyframes slideUp {
	from { opacity: 0; transform: translateY(30px); }
	to { opacity: 1; transform: translateY(0); }
}

@keyframes slideUpScale {
	from { opacity: 0; transform: translateY(40px) scale(0.95); }
	to { opacity: 1; transform: translateY(0) scale(1); }
}

/* ── Responsive ────────────────────────────────────────── */
@media (max-width: 900px) {
	.presentation-slide { padding: 8px 8px 14px; }
	.slide-content { padding: 12px; }
	.slide-glass-panel--component { max-width: 100%; }
	.slide-title { font-size: 1.45rem; }
	.chart-glass-base { padding: 6px; }
	.glass-control { width: 44px; height: 44px; }
	.slide-chart-container :deep(.dashboardcomponent-header h3) { font-size: 0.95rem; }
}
</style>

