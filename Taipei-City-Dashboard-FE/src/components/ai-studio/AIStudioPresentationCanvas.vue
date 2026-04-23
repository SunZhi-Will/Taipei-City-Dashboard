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
    <div class="presentation-stage">
      <div
        class="presentation-track"
        :style="trackStyle"
      >
        <section
          v-for="(slide, index) in slides"
          :key="slide.id || index"
          class="presentation-slide"
          :class="{ 'is-active': index === activeIndex }"
        >
          <div class="slide-overlay" />
          <div class="slide-content" :key="`content-${slideAnimKeys[index] || 0}`">
            <div class="slide-header">
              <span class="slide-chip">AI Agent Curated</span>
              <span class="slide-counter">{{ index + 1 }} / {{ slides.length }}</span>
            </div>

            <h2 class="slide-title">
              {{ slide.title || scene.title }}
            </h2>
            <p
              v-if="slide.subtitle"
              class="slide-subtitle"
            >
              {{ slide.subtitle }}
            </p>

            <div
              v-if="slide.type === 'component' && componentById.get(slide.focusComponentId)?.dashboardConfig"
              class="slide-chart-wrap"
            >
              <DashboardComponent
                :config="componentById.get(slide.focusComponentId).dashboardConfig"
                :active-city="componentById.get(slide.focusComponentId).city || componentById.get(slide.focusComponentId).dashboardConfig.city"
                :city-tag="cityManager?.getTagList(componentById.get(slide.focusComponentId).city || componentById.get(slide.focusComponentId).dashboardConfig.city)"
                :style="{ height: '320px', width: '100%' }"
              />
            </div>

            <div
              v-else
              class="slide-message-wrap"
            >
              <div class="slide-message">
                {{ slide.type === "closing" ? "持續追蹤最新城市變化" : "AI 依需求自動編排，適合大螢幕輪播" }}
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>

    <!-- Left arrow -->
    <button
      v-if="slides.length > 1"
      class="nav-arrow nav-arrow--prev"
      aria-label="上一頁"
      @click="prevSlide"
    >
      <span class="material-icons-round">chevron_left</span>
    </button>

    <!-- Right arrow -->
    <button
      v-if="slides.length > 1"
      class="nav-arrow nav-arrow--next"
      aria-label="下一頁"
      @click="nextSlide"
    >
      <span class="material-icons-round">chevron_right</span>
    </button>

    <!-- Dots overlay -->
    <div v-if="slides.length > 1" class="dots-overlay">
      <button
        v-for="(slide, index) in slides"
        :key="`dot-${slide.id || index}`"
        class="dot"
        :class="{ active: index === activeIndex }"
        :aria-label="`第 ${index + 1} 頁`"
        @click="jumpTo(index)"
      />
    </div>

    <!-- Progress bar -->
    <div class="progress-bar-wrap">
      <div
        class="progress-bar"
        :style="{ width: progressWidth + '%', transitionDuration: progressDuration + 'ms' }"
      />
    </div>
  </div>
</template>

<style scoped lang="scss">
.presentation-canvas {
	height: 100%;
	display: flex;
	flex-direction: column;
	background: radial-gradient(circle at 20% 20%, rgba(89, 167, 255, 0.15), transparent 45%),
		linear-gradient(135deg, #0f172a 0%, #111827 50%, #1e293b 100%);
	color: #f8fafc;
}

.presentation-canvas.industry-transport {
	background: radial-gradient(circle at 80% 25%, rgba(16, 185, 129, 0.2), transparent 42%),
		linear-gradient(140deg, #052e2b 0%, #0f3d3e 45%, #1f2937 100%);
}

.presentation-canvas.industry-senior-care {
	background: radial-gradient(circle at 22% 22%, rgba(245, 158, 11, 0.18), transparent 44%),
		linear-gradient(145deg, #3a2d14 0%, #4c3a1f 50%, #1f2937 100%);
}

.presentation-canvas.industry-education {
	background: radial-gradient(circle at 78% 18%, rgba(96, 165, 250, 0.25), transparent 45%),
		linear-gradient(145deg, #0d2240 0%, #163d74 45%, #0f172a 100%);
}

.presentation-stage {
	position: relative;
	flex: 1;
	overflow: hidden;
}

.presentation-track {
	display: flex;
	height: 100%;
	transition: transform 0.55s cubic-bezier(0.4, 0, 0.2, 1);
}

.presentation-slide {
	position: relative;
	min-width: 100%;
	height: 100%;
	display: flex;
	padding: 22px 24px 14px;
	box-sizing: border-box;
}

.slide-overlay {
	position: absolute;
	inset: 16px;
	border: 1px solid rgba(248, 250, 252, 0.14);
	border-radius: 16px;
	background: linear-gradient(145deg, rgba(15, 23, 42, 0.65), rgba(30, 41, 59, 0.6));
	backdrop-filter: blur(2px);
}

.slide-content {
	position: relative;
	z-index: 1;
	display: flex;
	flex-direction: column;
	width: 100%;
	height: 100%;
	gap: 10px;

	.slide-header { animation: slideUpFade 0.48s cubic-bezier(0.34, 1.2, 0.64, 1) 0.04s both; }
	.slide-title { animation: slideUpFade 0.52s cubic-bezier(0.34, 1.2, 0.64, 1) 0.14s both; }
	.slide-subtitle { animation: slideUpFade 0.48s cubic-bezier(0.34, 1.2, 0.64, 1) 0.24s both; }
	.slide-chart-wrap,
	.slide-message-wrap { animation: slideUpFade 0.5s cubic-bezier(0.34, 1.2, 0.64, 1) 0.34s both; }
}

.slide-header {
	display: flex;
	justify-content: space-between;
	align-items: center;
}

.slide-chip {
	padding: 5px 10px;
	font-size: 12px;
	border-radius: 999px;
	background: rgba(56, 189, 248, 0.2);
	border: 1px solid rgba(186, 230, 253, 0.35);
}

.slide-counter {
	font-size: 12px;
	opacity: 0.8;
}

.slide-title {
	margin: 0;
	font-size: clamp(1.5rem, 2.5vw, 2.2rem);
	line-height: 1.3;
	font-weight: 700;
}

.slide-subtitle {
	margin: 0;
	font-size: clamp(0.9rem, 1.2vw, 1.1rem);
	opacity: 0.9;
}

.slide-chart-wrap {
	flex: 1;
	min-height: 0;
	padding-top: 8px;
	overflow: hidden;
}

.slide-message-wrap {
	flex: 1;
	display: flex;
	align-items: center;
	justify-content: center;
}

.slide-message {
	font-size: clamp(1.1rem, 1.8vw, 1.6rem);
	padding: 18px 24px;
	border-radius: 12px;
	background: rgba(15, 23, 42, 0.48);
	border: 1px solid rgba(148, 163, 184, 0.24);
}

.nav-arrow {
	position: absolute;
	top: 50%;
	transform: translateY(-50%);
	z-index: 10;
	background: rgba(15, 23, 42, 0.55);
	border: 1px solid rgba(255, 255, 255, 0.2);
	border-radius: 50%;
	width: 44px;
	height: 44px;
	display: flex;
	align-items: center;
	justify-content: center;
	cursor: pointer;
	color: #f1f5f9;
	transition: background 0.2s;

	&:hover {
		background: rgba(15, 23, 42, 0.88);
	}

	&--prev { left: 20px; }
	&--next { right: 20px; }

	.material-icons-round {
		font-size: 1.6rem;
	}
}

.dots-overlay {
	position: absolute;
	bottom: 20px;
	left: 50%;
	transform: translateX(-50%);
	display: flex;
	gap: 8px;
	z-index: 10;
}

.dot {
	width: 9px;
	height: 9px;
	border-radius: 50%;
	border: none;
	background: rgba(148, 163, 184, 0.45);
	cursor: pointer;
	transition: background 0.2s, transform 0.2s;

	&.active {
		background: #38bdf8;
		transform: scale(1.3);
	}
}

@keyframes slideUpFade {
	from {
		opacity: 0;
		transform: translateY(22px);
	}
	to {
		opacity: 1;
		transform: translateY(0);
	}
}

.progress-bar-wrap {
	position: absolute;
	bottom: 0;
	left: 0;
	right: 0;
	height: 3px;
	background: rgba(255, 255, 255, 0.08);
	z-index: 10;
	overflow: hidden;
	border-radius: 0 0 0 0;
}

.progress-bar {
	height: 100%;
	width: 0;
	background: linear-gradient(90deg, #38bdf8, #818cf8);
	transition-property: width;
	transition-timing-function: linear;
}

@media (max-width: 900px) {
	.presentation-slide {
		padding: 10px;
	}

	.slide-overlay {
		inset: 8px;
	}

	.nav-arrow {
		width: 36px;
		height: 36px;
		&--prev { left: 8px; }
		&--next { right: 8px; }
	}
}
</style>
