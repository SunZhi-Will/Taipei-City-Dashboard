<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from "vue";
import DashboardComponent from "../../dashboardComponent/DashboardComponent.vue";

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
});

const activeIndex = ref(0);
const isPlaying = ref(true);
let timer = null;

const slideAnimKeys = ref({});
const progressWidth = ref(0);
const progressDuration = ref(0);

const resolvedIndustry = computed(() => props.scene?.presentation?.industry || "general");
const autoplayMs = computed(() => {
	const duration = Number(props.scene?.presentation?.autoplay?.intervalMs || 10000);
	return Number.isFinite(duration) && duration >= 2000 ? duration : 10000;
});

const themeClass = computed(() => `industry-${resolvedIndustry.value}`);

const slides = computed(() => {
	const explicitSlides = Array.isArray(props.scene?.presentation?.slides)
		? props.scene.presentation.slides
		: [];
	if (explicitSlides.length > 0) return explicitSlides;

	const components = Array.isArray(props.components) ? props.components : [];
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

	return [
		{
			id: "default-hero",
			type: "hero",
			title: props.scene?.title || "AI 展示畫面",
			subtitle: props.scene?.objective || "根據城市議題自動編排展示內容。",
			durationSec: 10,
		},
		...components.slice(0, 3).map((item, index) => ({
			id: `auto-${item?.id || index}`,
			type: "component",
			title: item?.name || `重點指標 ${index + 1}`,
			subtitle: item?.dashboardConfig?.short_desc || "AI 精選重點圖表",
			focusComponentId: item?.id,
			durationSec: 12,
		})),
	];
});

const componentById = computed(() => {
	const map = new Map();
	for (const item of props.components || []) {
		if (item?.id) map.set(item.id, item);
	}
	return map;
});

const trackStyle = computed(() => ({
	transform: `translateX(-${activeIndex.value * 100}%)`,
}));

const clearTimer = () => {
	if (timer) {
		clearInterval(timer);
		timer = null;
	}
};

const nextSlide = () => {
	if (slides.value.length <= 1) return;
	activeIndex.value = (activeIndex.value + 1) % slides.value.length;
};

const prevSlide = () => {
	if (slides.value.length <= 1) return;
	activeIndex.value = (activeIndex.value - 1 + slides.value.length) % slides.value.length;
};

const jumpTo = (index) => {
	if (index < 0 || index >= slides.value.length) return;
	activeIndex.value = index;
};

const resetProgress = () => {
	progressWidth.value = 0;
	progressDuration.value = 0;
	const enabled = Boolean(props.scene?.presentation?.autoplay?.enabled);
	if (!enabled || !isPlaying.value || slides.value.length <= 1) return;
	nextTick(() => {
		progressDuration.value = autoplayMs.value;
		progressWidth.value = 100;
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
	slideAnimKeys.value = {
		...slideAnimKeys.value,
		[newVal]: (slideAnimKeys.value[newVal] || 0) + 1,
	};
	resetProgress();
}, { immediate: true });

onMounted(() => {
	setupTimer();
});

onBeforeUnmount(() => {
	clearTimer();
});
</script>

<template>
  <div
    class="presentation-canvas"
    :class="themeClass"
  >
    <!-- Background layers for spatial depth -->
    <div class="canvas-bg-glow" />
    <div class="canvas-mesh-grid" />
    
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
            <div class="slide-glass-panel">
              <div class="panel-border-glow" />
              <div class="panel-noise" />
              
              <div class="slide-content" :key="`content-${slideAnimKeys[index] || 0}`">
                <div class="slide-header">
                  <div class="ai-badge">
                    <span class="ai-badge-icon">auto_awesome</span>
                    <span class="ai-badge-text">AI Agent Curated</span>
                  </div>
                  <div class="slide-pagination">
                    <span class="current">{{ String(index + 1).padStart(2, '0') }}</span>
                    <span class="separator">/</span>
                    <span class="total">{{ String(slides.length).padStart(2, '0') }}</span>
                  </div>
                </div>

                <div class="slide-main">
                  <div class="slide-info">
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
                    v-if="slide.type === 'component' && componentById.get(slide.focusComponentId)?.dashboardConfig"
                    class="slide-chart-container"
                  >
                    <div class="chart-glass-base">
                      <DashboardComponent
                        :config="componentById.get(slide.focusComponentId).dashboardConfig"
                        :active-city="componentById.get(slide.focusComponentId).city || componentById.get(slide.focusComponentId).dashboardConfig.city"
                        :city-tag="cityManager?.getTagList(componentById.get(slide.focusComponentId).city || componentById.get(slide.focusComponentId).dashboardConfig.city)"
                        :style="{ height: '100%', width: '100%' }"
                      />
                    </div>
                  </div>

                  <div
                    v-else
                    class="slide-hero-container"
                  >
                    <div class="hero-message-card">
                      <div class="hero-icon">
                        <span class="material-icons-round">{{ slide.type === 'closing' ? 'analytics' : 'insights' }}</span>
                      </div>
                      <div class="hero-text-wrap">
                        <p class="hero-message">{{ slide.type === "closing" ? "持續追蹤最新城市變化" : "AI 依需求自動編排場景" }}</p>
                        <p class="hero-sub">{{ slide.type === "closing" ? "更多深入資料請至各專題看板" : "最快、最精準的都市數據觀測" }}</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>

    <!-- Controls -->
    <div class="controls-layer" v-if="slides.length > 1">
      <button
        class="glass-control prev"
        aria-label="Previous"
        @click="prevSlide"
      >
        <span class="material-icons-round">chevron_left</span>
      </button>

      <div class="dots-navigation">
        <button
          v-for="(slide, index) in slides"
          :key="`dot-${slide.id || index}`"
          class="nav-dot"
          :class="{ active: index === activeIndex }"
          @click="jumpTo(index)"
        />
      </div>

      <button
        class="glass-control next"
        aria-label="Next"
        @click="nextSlide"
      >
        <span class="material-icons-round">chevron_right</span>
      </button>
    </div>

    <!-- Play/Pause & Progress -->
    <div class="status-footer">
      <div class="progress-container">
        <div
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

/* ── Animated Backgrounds ────────────────────────────────────── */
.canvas-bg-glow {
	position: absolute;
	inset: 0;
	background: 
		radial-gradient(circle at 10% 10%, rgba(56, 189, 248, 0.15) 0%, transparent 40%),
		radial-gradient(circle at 90% 90%, rgba(129, 140, 248, 0.12) 0%, transparent 40%);
	filter: blur(80px);
	z-index: 0;
	pointer-events: none;
}

.canvas-mesh-grid {
	position: absolute;
	inset: 0;
	background-image: 
		linear-gradient(rgba(255,255,255,0.02) 1px, transparent 1px),
		linear-gradient(90deg, rgba(255,255,255,0.02) 1px, transparent 1px);
	background-size: 60px 60px;
	z-index: 0;
	opacity: 0.5;
	mask-image: radial-gradient(circle at 50% 50%, white, transparent 80%);
}

/* ── Industry Themes ─────────────────────────────────────────── */
.presentation-canvas.industry-transport {
	.canvas-bg-glow {
		background: 
			radial-gradient(circle at 80% 20%, rgba(16, 185, 129, 0.18) 0%, transparent 45%),
			radial-gradient(circle at 20% 80%, rgba(20, 184, 166, 0.15) 0%, transparent 45%);
	}
}

.presentation-canvas.industry-senior-care {
	.canvas-bg-glow {
		background: 
			radial-gradient(circle at 20% 20%, rgba(245, 158, 11, 0.15) 0%, transparent 45%),
			radial-gradient(circle at 80% 80%, rgba(217, 119, 6, 0.12) 0%, transparent 45%);
	}
}

.presentation-canvas.industry-education {
	.canvas-bg-glow {
		background: 
			radial-gradient(circle at 75% 15%, rgba(96, 165, 250, 0.2) 0%, transparent 45%),
			radial-gradient(circle at 25% 85%, rgba(59, 130, 246, 0.15) 0%, transparent 45%);
	}
}

.presentation-canvas.industry-health {
	.canvas-bg-glow {
		background: 
			radial-gradient(circle at 15% 15%, rgba(248, 113, 113, 0.15) 0%, transparent 45%),
			radial-gradient(circle at 85% 85%, rgba(239, 68, 68, 0.12) 0%, transparent 45%);
	}
}

/* ── Stage & Track ───────────────────────────────────────────── */
.presentation-stage {
	position: relative;
	flex: 1;
	z-index: 10;
	padding: 40px;
	box-sizing: border-box;
}

.presentation-track {
	display: flex;
	height: 100%;
	transition: transform 0.85s cubic-bezier(0.2, 0.8, 0.2, 1);
	transform-style: preserve-3d;
}

/* ── Slide Styling ───────────────────────────────────────────── */
.presentation-slide {
	position: relative;
	min-width: 100%;
	height: 100%;
	display: flex;
	padding: 0 20px;
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
	max-width: 1100px;
	height: 100%;
	background: $glass-bg;
	backdrop-filter: blur(12px) saturate(180%);
	border: 1px solid $glass-border;
	border-radius: 32px;
	box-shadow: 
		0 20px 50px rgba(0, 0, 0, 0.5),
		0 0 0 1px rgba(255, 255, 255, 0.05) inset;
	overflow: hidden;
	display: flex;
	flex-direction: column;
}

.panel-border-glow {
	position: absolute;
	inset: 0;
	border-radius: 32px;
	box-shadow: 0 0 30px rgba(56, 189, 248, 0.05) inset;
	pointer-events: none;
}

.panel-noise {
	position: absolute;
	inset: 0;
	background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E");
	opacity: 0.03;
	pointer-events: none;
}

/* ── Content ─────────────────────────────────────────────── */
.slide-content {
	flex: 1;
	display: flex;
	flex-direction: column;
	padding: 40px;
	gap: 20px;
}

.slide-header {
	display: flex;
	justify-content: space-between;
	align-items: center;
	animation: slideUp 0.6s cubic-bezier(0.23, 1, 0.32, 1) both;
}

.ai-badge {
	display: flex;
	align-items: center;
	gap: 8px;
	padding: 6px 14px;
	background: rgba(56, 189, 248, 0.15);
	border: 1px solid rgba(56, 189, 248, 0.3);
	border-radius: 99px;
	color: $accent;
	
	&-icon { font-family: "Material Icons Round"; font-size: 16px; }
	&-text { font-size: 12px; font-weight: 600; letter-spacing: 0.05em; text-transform: uppercase; }
}

.slide-pagination {
	font-family: "JetBrains Mono", monospace;
	font-size: 14px;
	color: $text-dim;
	display: flex;
	align-items: center;
	gap: 4px;

	.current { color: $accent; font-weight: 700; }
	.separator { opacity: 0.3; }
}

.slide-main {
	flex: 1;
	display: flex;
	flex-direction: column;
	gap: 24px;
	min-height: 0;
}

.slide-title {
	margin: 0;
	font-size: clamp(1.8rem, 3.5vw, 2.8rem);
	font-weight: 800;
	line-height: 1.1;
	letter-spacing: -0.02em;
	background: linear-gradient(to right, #fff, #94a3b8);
	-webkit-background-clip: text;
	-webkit-text-fill-color: transparent;
	animation: slideUp 0.7s cubic-bezier(0.23, 1, 0.32, 1) 0.1s both;
}

.slide-subtitle {
	margin: 10px 0 0;
	font-size: clamp(1rem, 1.4vw, 1.25rem);
	color: $text-dim;
	max-width: 800px;
	line-height: 1.5;
	animation: slideUp 0.7s cubic-bezier(0.23, 1, 0.32, 1) 0.2s both;
}

.slide-chart-container {
	flex: 1;
	min-height: 0;
	background: rgba(2, 6, 23, 0.3);
	border-radius: 20px;
	border: 1px solid rgba(255,255,255,0.05);
	overflow: hidden;
	animation: slideUpScale 0.8s cubic-bezier(0.23, 1, 0.32, 1) 0.3s both;
}

.chart-glass-base {
	width: 100%;
	height: 100%;
	padding: 20px;
	box-sizing: border-box;
}

.slide-hero-container {
	flex: 1;
	display: flex;
	align-items: center;
	justify-content: center;
	animation: slideUp 0.8s cubic-bezier(0.23, 1, 0.32, 1) 0.3s both;
}

.hero-message-card {
	display: flex;
	align-items: center;
	gap: 30px;
	padding: 40px;
	background: rgba(255,255,255,0.03);
	border: 1px solid rgba(255,255,255,0.05);
	border-radius: 24px;
	max-width: 600px;
}

.hero-icon {
	width: 80px;
	height: 80px;
	background: linear-gradient(135deg, $accent, #818cf8);
	border-radius: 20px;
	display: flex;
	align-items: center;
	justify-content: center;
	box-shadow: 0 10px 25px rgba(56, 189, 248, 0.3);
	
	span { font-size: 40px; color: #fff; }
}

.hero-text-wrap {
	.hero-message { margin: 0; font-size: 22px; font-weight: 700; color: #fff; }
	.hero-sub { margin: 6px 0 0; font-size: 16px; color: $text-dim; }
}

/* ── Controls ──────────────────────────────────────────── */
.controls-layer {
	position: absolute;
	inset: 0;
	pointer-events: none;
	display: flex;
	align-items: center;
	justify-content: space-between;
	padding: 0 30px;
	z-index: 50;
}

.glass-control {
	width: 56px;
	height: 56px;
	border-radius: 50%;
	background: rgba(15, 23, 42, 0.6);
	backdrop-filter: blur(8px);
	border: 1px solid rgba(255,255,255,0.1);
	color: #fff;
	display: flex;
	align-items: center;
	justify-content: center;
	cursor: pointer;
	pointer-events: auto;
	transition: all 0.3s;
	
	&:hover {
		background: rgba($accent, 0.8);
		transform: scale(1.1);
		border-color: transparent;
	}
	
	span { font-size: 32px; }
}

.dots-navigation {
	position: absolute;
	bottom: 50px;
	left: 50%;
	transform: translateX(-50%);
	display: flex;
	gap: 12px;
	pointer-events: auto;
}

.nav-dot {
	width: 10px;
	height: 10px;
	border-radius: 50%;
	background: rgba(255,255,255,0.2);
	border: none;
	cursor: pointer;
	transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);
	
	&.active {
		background: $accent;
		transform: scale(1.5);
		box-shadow: 0 0 15px $accent-glow;
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
	.presentation-stage { padding: 15px; }
	.slide-content { padding: 25px; }
	.slide-title { font-size: 1.8rem; }
	.glass-control { width: 44px; height: 44px; }
	.hero-message-card { padding: 20px; gap: 15px; }
	.hero-icon { width: 50px; height: 50px; span { font-size: 24px; } }
}
</style>

