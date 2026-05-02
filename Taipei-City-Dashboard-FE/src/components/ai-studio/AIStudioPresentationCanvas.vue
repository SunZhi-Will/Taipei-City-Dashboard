<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from "vue";
import DashboardComponent from "../../dashboardComponent/DashboardComponent.vue";
import { useMapStore } from "../../store/mapStore";
import http from "../../router/axios";

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

const emit = defineEmits(['map-slide-active']);

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

// Per-slide duration: respect each slide's durationSec, fall back to scene-level interval
const currentSlideDurationMs = computed(() => {
	const slide = slides.value[activeIndex.value];
	const sec = Number(slide?.durationSec);
	return Number.isFinite(sec) && sec >= 2 ? sec * 1000 : autoplayMs.value;
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
				title: props.scene?.title || "AI 專題展示",
				subtitle: props.scene?.objective || "請在左側輸入需求，AI 將自動生成輪播內容。",
				durationSec: 10,
			},
		];
	}

	// 戰情室模式：回歸 AI 決策，若 AI 未提供 slides 則由組件直接生成
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

const isUnknownSlideType = (slide) => !["hero", "component_explain", "component", "map", "text"].includes(slide?.type);

// Map chart types — used to auto-resolve initial-chart-type for map slides
const MAP_CHART_TYPES = new Set(['map_legend', 'map_pin', 'map_heat', 'map_layer', 'map_district']);

// Normalizes CamelCase chart type names to snake_case for comparison.
// e.g. "MapLegend" → "map_legend", "map_legend" → "map_legend"
const toSnakeCase = (t) => t.replace(/([A-Z])/g, (m, c) => '_' + c.toLowerCase()).replace(/^_/, '').toLowerCase();
const isMapChartType = (t) => t && (MAP_CHART_TYPES.has(t) || MAP_CHART_TYPES.has(toSnakeCase(t)));

/**
 * Returns the best chart type for a slide:
 * - map slides: checks if the component actually supports map chart types.
 *   Returns the exact DB string (e.g. "MapLegend") for DashboardComponent compatibility.
 *   If component has no map support → degrade to its primary chart type.
 * - other slides: returns slide.chartType as-is.
 */
const resolveChartTypeForSlide = (slide, component) => {
	if (slide?.type !== 'map') return slide?.chartType || '';

	const types = component?.dashboardConfig?.chart_config?.types;
	// Find first map type from the component's DB types (case-insensitive via isMapChartType)
	const mapType = Array.isArray(types) ? types.find((t) => isMapChartType(t)) : null;

	// Component has no map support — degrade gracefully to its primary chart type
	if (!mapType) {
		// If AI already specified a non-map chart_type for this slide, honour it
		if (slide?.chartType && !isMapChartType(slide.chartType)) return slide.chartType;
		return Array.isArray(types) && types.length > 0 ? types[0] : '';
	}

	// Component has map support — always return the exact DB map type string
	// (avoids case mismatches: AI uses "map_legend" but DashboardComponent needs "MapLegend")
	return mapType;
};

// ── Map Location Resolution ─────────────────────────────────────────
// Cache resolved coordinates per slide.id to avoid re-fetching on every slide change
const resolvedLocationCache = new Map();

/**
 * Move the map to [lng, lat] with a smooth flyTo animation and place the marker.
 */
const moveMapToLocation = (lng, lat) => {
	if (!mapStore.map) return;
	mapStore.map.flyTo({
		center: [lng, lat],
		zoom: Math.max(mapStore.map.getZoom?.() ?? 12, 14),
		duration: 1400,
		essential: true,
	});
	if (mapStore.marker) {
		mapStore.marker.setLngLat([lng, lat]).addTo(mapStore.map);
	}
};

/**
 * Resolve a location query string via AI geocode endpoint (same as MapContainer).
 * Returns { name, coordinates: [lng, lat] } or null on failure.
 */
const resolveLocationByAI = async (query) => {
	try {
		const response = await http.post('/ai/chat/twai', {
			session: `canvas-map-${Date.now()}`,
			app_mode: 'map_search',
			stream: false,
			max_new_tokens: 120,
			temperature: 0.1,
			tool_choice: 'none',
			tools: [],
			messages: [
				{
					role: 'system',
					content: '你是地圖定位助手。請解析使用者地點並只回傳 JSON：{"location_name":"地點名","longitude":121.5,"latitude":25.0}。不可回傳任何其他文字。',
				},
				{
					role: 'user',
					content: `請解析以下地點並輸出座標：${query}`,
				},
			],
		});
		const raw = String(response?.data?.data?.content || '').trim();
		const jsonMatch = raw.match(/\{[\s\S]*\}/);
		if (!jsonMatch) return null;
		const parsed = JSON.parse(jsonMatch[0]);
		const lng = Number(parsed?.longitude ?? parsed?.lng);
		const lat = Number(parsed?.latitude ?? parsed?.lat);
		if (Number.isFinite(lng) && Number.isFinite(lat)) {
			return { name: parsed?.location_name || parsed?.name || query, coordinates: [lng, lat] };
		}
	} catch (_) { /* silent */ }
	return null;
};

/**
 * For a map slide, resolve its location (mapLng/mapLat or mapQuery) and flyTo.
 * Results are cached per slide.id so repeated slide visits skip the API call.
 */
const resolveLocationAndFly = async (slide) => {
	if (slide?.type !== 'map') return;

	const cacheKey = slide.id || JSON.stringify(slide);

	// Direct coordinates — highest priority
	const lng = Number(slide?.mapLng);
	const lat = Number(slide?.mapLat);
	if (Number.isFinite(lng) && Number.isFinite(lat)) {
		moveMapToLocation(lng, lat);
		return;
	}

	const query = String(slide?.mapQuery || '').trim();
	if (!query) return;

	// Serve from cache
	if (resolvedLocationCache.has(cacheKey)) {
		const cached = resolvedLocationCache.get(cacheKey);
		if (cached) moveMapToLocation(cached[0], cached[1]);
		return;
	}

	const result = await resolveLocationByAI(query);
	if (result?.coordinates) {
		resolvedLocationCache.set(cacheKey, result.coordinates);
		moveMapToLocation(result.coordinates[0], result.coordinates[1]);
	} else {
		resolvedLocationCache.set(cacheKey, null); // mark as unresolvable to avoid repeated calls
	}
};

const syncMapLayersForSlide = (slide) => {
	if (slide?.type !== "map") return;
	const targetComponent = getSlideComponent(slide, activeIndex.value);
	const mapConfig = targetComponent?.dashboardConfig?.map_config;

	const setupMapLayers = () => {
		if (!mapStore.map?.loaded?.()) return;
		const activeCity = targetComponent?.city || targetComponent?.dashboardConfig?.city || "taipei";
		mapStore.updateMapViewForCity(activeCity);
		if (Array.isArray(mapConfig) && mapConfig.length > 0 && mapConfig[0]) {
			mapStore.addToMapLayerList(mapConfig);
		}
	};

	// Add data layers — guard against null map (race condition: map not yet initialized)
	if (mapStore.map?.loaded?.()) {
		setupMapLayers();
	} else if (mapStore.map) {
		// Map exists but loading
		mapStore.map.once("load", setupMapLayers);
	}
	// If mapStore.map is null, the watch(() => mapStore.map) watcher below will retry

	// Fly to location if slide has mapQuery or direct coordinates
	if (slide.mapQuery || (slide.mapLng && slide.mapLat)) {
		const doFly = () => resolveLocationAndFly(slide);
		if (mapStore.map?.loaded?.()) {
			doFly();
		} else if (mapStore.map) {
			mapStore.map.once("load", doFly);
		}
	}
};

const trackStyle = computed(() => ({
	transform: `translateX(-${activeIndex.value * 100}%)`,
}));

const clearTimer = () => {
	if (timer) {
		clearTimeout(timer);
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
			progressDuration.value = currentSlideDurationMs.value;
			progressWidth.value = 100;
		});
	});
};

const setupTimer = () => {
	clearTimer();
	const enabled = Boolean(props.scene?.presentation?.autoplay?.enabled);
	if (!enabled || !isPlaying.value || slides.value.length <= 1) return;
	// Use per-slide durationSec so each slide controls its own screen time
	timer = setTimeout(() => {
		nextSlide();
		setupTimer();
	}, currentSlideDurationMs.value);
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
	emit('map-slide-active', slides.value[newVal]?.type === 'map');
}, { immediate: true });

// Fix race condition: when mapStore.map becomes ready, re-run sync for the current map slide
watch(() => mapStore.map, (newMap) => {
	if (!newMap) return;
	const currentSlide = slides.value[activeIndex.value];
	if (currentSlide?.type === 'map') {
		syncMapLayersForSlide(currentSlide);
	}
});

watch(() => props.isImmersive, (nextValue) => {
	if (nextValue) {
		controlsVisible.value = true;
		handlePointerActivity();
		return;
	}
	controlsVisible.value = true;
	clearControlsTimer();
}, { immediate: true });

const handleKeydown = (e) => {
	if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
		e.preventDefault();
		nextSlide({ resetAutoplay: true });
	} else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
		e.preventDefault();
		prevSlide({ resetAutoplay: true });
	} else if (e.key === ' ') {
		e.preventDefault();
		isPlaying.value = !isPlaying.value;
	}
};

onMounted(() => {
	setupTimer();
	window.addEventListener('keydown', handleKeydown);
});

onBeforeUnmount(() => {
	clearTimer();
	clearControlsTimer();
	window.removeEventListener('keydown', handleKeydown);
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
            'is-next': index > activeIndex,
            'presentation-slide--map': slide.type === 'map'
          }"
        >
          <div class="slide-inner-stage">

						<!-- ── MAP SLIDE: transparent glass panel so Mapbox shows through; info footer at bottom ── -->
						<template v-if="slide.type === 'map'">
							<div class="slide-glass-panel slide-glass-panel--map">
								<!-- Transparent middle = map shows through via presentation-stage background hole -->
								<div class="slide-map-body">
									<!-- header with pagination -->
									<div class="slide-map-header">
										<div class="slide-map-pagination-inline">
											<span class="current">{{ String(index + 1).padStart(2, '0') }}</span>
											<span class="separator">/</span>
											<span class="total">{{ String(slides.length).padStart(2, '0') }}</span>
										</div>
										<h3 class="slide-map-title">
											{{ slide.title || getSlideComponent(slide, index)?.name || '空間分析' }}
										</h3>
									</div>
									<!-- Transparent fill area — map visible here -->
									<div class="slide-map-viewport" />
									<!-- footer overlay -->
									<div class="slide-map-footer">
										<p v-if="slide.summary || slide.subtitle" class="slide-map-desc">
											{{ slide.summary || slide.subtitle }}
										</p>
										<div v-if="slide.mapQuery" class="slide-map-location-badge">
											<span class="material-icons-round">location_on</span>
											{{ slide.mapQuery }}
										</div>
									</div>
								</div>
							</div>
						</template>

						<!-- ── NON-MAP SLIDES: glass panel with existing layout ── -->
						<template v-else>
						<div
							class="slide-glass-panel"
							:class="{ 'slide-glass-panel--component': slide.type === 'component' }"
						>
              <div class="panel-border-glow" />
              <div class="panel-noise" />
              
							<div
								class="slide-content"
								:class="{
								'slide-content--component': slide.type === 'component',
									'slide-content--hero': slide.type === 'hero' || slide.type === 'component_explain' || isUnknownSlideType(slide),
									'slide-content--text': slide.type === 'text',
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
									'slide-main--component': slide.type === 'component',
										'slide-main--hero': slide.type === 'hero' || slide.type === 'component_explain' || isUnknownSlideType(slide),
										'slide-main--text': slide.type === 'text',
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
									<p v-if="!slide.subtitle" class="slide-subtitle">
										{{ getSlideComponent(slide, index)?.dashboardConfig?.short_desc || '可切換到圖表牆查看完整組件內容與互動細節。' }}
									</p>
								</div>

								<!-- text 文字分析投影片 -->
								<div
									v-if="slide.type === 'text'"
									class="slide-info slide-info--text"
								>
									<h2 class="slide-title">
										{{ slide.title || '數據分析' }}
									</h2>
									<p
										v-if="slide.subtitle"
										class="slide-subtitle"
									>
										{{ slide.subtitle }}
									</p>
									<div v-if="slide.highlight" class="slide-highlight">
										<span class="highlight-value">{{ slide.highlight }}</span>
									</div>
									<ul v-if="slide.bullets?.length" class="slide-bullets">
										<li
											v-for="(bullet, bIdx) in slide.bullets"
											:key="bIdx"
										>
											{{ bullet }}
										</li>
									</ul>
									<p v-else-if="slide.summary && !slide.subtitle" class="slide-text-body">
										{{ slide.summary }}
									</p>
								</div>

								<!-- component 投影片：渲染 DashboardComponent -->
                  <div
								v-if="slide.type === 'component' && getSlideComponent(slide, index)?.dashboardConfig"
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
										:initial-chart-type="resolveChartTypeForSlide(slide, getSlideComponent(slide, index))"
                        :style="{ height: '100%', width: '100%' }"
                      />
                    </div>
                  </div>

								<div
									v-if="slide.type === 'component' && !getSlideComponent(slide, index)?.dashboardConfig"
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
						</template><!-- end non-map -->
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
          :title="slide.title || `投影片 ${index + 1}`"
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

    <!-- Play/Pause & Progress (Premium Icon-based UI) -->
    <div class="status-footer">
      <div class="status-footer-inner">
        <button
          class="play-pause-icon-btn"
          :title="isPlaying ? '暫停自動播放 (Space)' : '開始自動播放 (Space)'"
          @click="isPlaying = !isPlaying"
        >
          <span class="material-icons-round">{{ isPlaying ? 'pause' : 'play_arrow' }}</span>
        </button>
        <div class="premium-progress-container">
          <div
            :key="progressRunKey"
            class="premium-progress-fill"
            :style="{ width: progressWidth + '%', transitionDuration: progressDuration + 'ms' }"
          />
        </div>
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
// Industry themes must include the base dark color as last value —
// otherwise `background` shorthand overrides `.presentation-canvas`'s #020617.
.presentation-canvas.industry-transport {
	background:
		radial-gradient(circle at 80% 20%, rgba(16, 185, 129, 0.18) 0%, transparent 45%),
		radial-gradient(circle at 20% 80%, rgba(20, 184, 166, 0.15) 0%, transparent 45%),
		#020617;
}

.presentation-canvas.industry-senior-care {
	background:
		radial-gradient(circle at 20% 20%, rgba(245, 158, 11, 0.15) 0%, transparent 45%),
		radial-gradient(circle at 80% 80%, rgba(217, 119, 6, 0.12) 0%, transparent 45%),
		#020617;
}

.presentation-canvas.industry-education {
	background:
		radial-gradient(circle at 75% 15%, rgba(96, 165, 250, 0.2) 0%, transparent 45%),
		radial-gradient(circle at 25% 85%, rgba(59, 130, 246, 0.15) 0%, transparent 45%),
		#020617;
}

.presentation-canvas.industry-health {
	background:
		radial-gradient(circle at 15% 15%, rgba(248, 113, 113, 0.15) 0%, transparent 45%),
		radial-gradient(circle at 85% 85%, rgba(239, 68, 68, 0.12) 0%, transparent 45%),
		#020617;
}

/* ── Map slide: transparent chain so Mapbox shows through glass panel ─── */
/* When a map slide is the active slide, the canvas and stage must be fully
   transparent so the isolated z-index:1 map layer shows through the
   transparent .slide-glass-panel--map.
   CSS :has() supported in Chrome 105+, Safari 15.4+, Firefox 121+. */
.presentation-canvas:has(.presentation-slide--map.is-active),
.presentation-canvas.industry-transport:has(.presentation-slide--map.is-active),
.presentation-canvas.industry-senior-care:has(.presentation-slide--map.is-active),
.presentation-canvas.industry-education:has(.presentation-slide--map.is-active),
.presentation-canvas.industry-health:has(.presentation-slide--map.is-active) {
	background: transparent;
}

/* When a map slide is active, disable 3D compositing context so the z-index
   transparency chain works correctly after repaint (e.g. browser/map zoom).
   transform-style: preserve-3d + perspective promote elements to GPU composite
   layers whose transparent areas composite against an implicit opaque background
   rather than the underlying Mapbox WebGL layer, causing the map to disappear. */
.presentation-canvas:has(.presentation-slide--map.is-active) {
	perspective: none;

	.presentation-track {
		transform-style: flat;
	}

	.presentation-slide--map.is-active {
		transform: none;
		transition: opacity 0.8s ease;
	}
}

/* ── Stage & Track ───────────────────────────────────────────── */
.presentation-stage {
	position: relative;
	flex: 1;
	min-height: 0;
	z-index: 10;
	overflow: hidden;
	/* When map slide is active, :has() on the canvas removes its bg too;
	   stage must also be transparent so the full chain passes through to z-index:1 map. */
	.presentation-canvas:has(.presentation-slide--map.is-active) & {
		background: transparent;
	}
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

	/* Map slide: transparent glass so the persistent Mapbox layer shows through.
	   The massive box-shadow (clipped by presentation-stage overflow:hidden) provides
	   the dark frame around the card in the slide padding area.
	   pointer-events: none allows the underlying map to receive mouse/touch events. */
	&--map {
		background: transparent;
		backdrop-filter: none;
		border: 1px solid rgba(255, 255, 255, 0.18);
		/* box-shadow: inner ring + massive outer spread for dark frame outside card */
		box-shadow:
			0 0 0 1px rgba(56, 189, 248, 0.15),  /* subtle blue ring */
			0 0 0 9999px #020617;                  /* dark mask outside card, clipped by stage overflow:hidden */
		pointer-events: none;
		overflow: hidden;
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

/* ── Text Slide ──────────────────────────────────────────────── */
.slide-content--text {
	padding: 18px 24px 14px;
}

.slide-main--text {
	display: flex;
	flex-direction: column;
	justify-content: center;
	gap: 14px;
	padding: 0 0 clamp(20px, 4vh, 40px);
	overflow: hidden;
	min-height: 0;
}

.slide-info--text {
	max-width: 860px;
	width: 100%;
	margin: 0 auto;
	text-align: left;
	display: flex;
	flex-direction: column;
	gap: 12px;

	.slide-title {
		text-align: left;
		font-size: clamp(1.35rem, 2.1vw, 1.8rem);
	}

	.slide-subtitle {
		text-align: left;
	}
}

.slide-highlight {
	display: flex;
	align-items: baseline;
	gap: 10px;
	animation: slideUp 0.6s cubic-bezier(0.23, 1, 0.32, 1) 0.2s both;
}

.highlight-value {
	font-size: clamp(2rem, 4vw, 3rem);
	font-weight: 900;
	color: $accent;
	font-family: 'JetBrains Mono', monospace;
	line-height: 1;
	text-shadow: 0 0 24px rgba(56, 189, 248, 0.45);
}

.slide-bullets {
	list-style: none;
	margin: 0;
	padding: 0;
	display: flex;
	flex-direction: column;
	gap: 10px;
	animation: slideUp 0.7s cubic-bezier(0.23, 1, 0.32, 1) 0.28s both;

	li {
		position: relative;
		padding-left: 20px;
		font-size: clamp(0.9rem, 1.1vw, 1.02rem);
		line-height: 1.55;
		color: rgba(226, 232, 240, 0.92);

		&::before {
			content: '▸';
			position: absolute;
			left: 0;
			color: $accent;
			font-size: 0.78em;
			top: 0.2em;
		}
	}
}

.slide-text-body {
	margin: 0;
	font-size: clamp(0.95rem, 1.1vw, 1.05rem);
	line-height: 1.7;
	color: rgba(226, 232, 240, 0.85);
	animation: slideUp 0.7s cubic-bezier(0.23, 1, 0.32, 1) 0.3s both;
}

/* ── Map Slide Styles ────────────────────────────────────────── */
/* Map slides keep standard padding so nav arrows remain visible outside the card.
   The glass panel is transparent, letting the persistent Mapbox layer show through.
   pointer-events: none on the glass panel lets the map receive mouse/touch events. */
.presentation-slide--map {
	/* Keep same padding as other slides for consistent framing */
}

/* Internal layout: header → transparent viewport fill → footer */
.slide-map-body {
	display: flex;
	flex-direction: column;
	width: 100%;
	height: 100%;
	pointer-events: none;
}

.slide-map-header {
	flex-shrink: 0;
	display: flex;
	align-items: center;
	gap: 12px;
	padding: 10px 14px 8px;
	background: linear-gradient(to bottom, rgba(2, 6, 23, 0.88) 0%, transparent 100%);
	pointer-events: none;
}

.slide-map-pagination-inline {
	font-family: "JetBrains Mono", monospace;
	font-size: 12px;
	color: rgba(148, 163, 184, 0.78);
	display: flex;
	align-items: center;
	gap: 4px;
	flex-shrink: 0;

	.current { color: $accent; font-weight: 700; }
	.separator { opacity: 0.3; }
}

.slide-map-title {
	margin: 0;
	font-size: clamp(1rem, 1.5vw, 1.35rem);
	font-weight: 700;
	color: #f1f5f9;
	line-height: 1.2;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
	animation: slideUp 0.6s cubic-bezier(0.23, 1, 0.32, 1) 0.1s both;
}

/* Transparent fill area — the map (canvas-persistent-map behind canvas-body) shows here */
.slide-map-viewport {
	flex: 1;
	min-height: 0;
}

.slide-map-footer {
	flex-shrink: 0;
	padding: 24px 14px 10px;
	background: linear-gradient(to top, rgba(2, 6, 23, 0.88) 0%, transparent 100%);
	pointer-events: none;
	display: flex;
	flex-direction: column;
	gap: 6px;
}

.slide-map-desc {
	margin: 0;
	font-size: clamp(0.82rem, 0.95vw, 0.92rem);
	line-height: 1.5;
	color: rgba(226, 232, 240, 0.85);
	animation: slideUp 0.6s cubic-bezier(0.23, 1, 0.32, 1) 0.2s both;
}

.slide-map-location-badge {
	display: inline-flex;
	align-items: center;
	gap: 5px;
	padding: 4px 10px 4px 7px;
	border-radius: 999px;
	background: rgba(56, 189, 248, 0.15);
	border: 1px solid rgba(56, 189, 248, 0.35);
	color: #7dd3fc;
	font-size: 0.82rem;
	font-weight: 600;
	align-self: flex-start;
	animation: slideUp 0.6s cubic-bezier(0.23, 1, 0.32, 1) 0.3s both;

	.material-icons-round { font-size: 0.95rem; color: #38bdf8; }
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

/* ── Status Footer (Premium Icon & Progress) ─────────────── */
.status-footer {
	position: absolute;
	bottom: 12px;
	left: 50%;
	transform: translateX(-50%);
	width: calc(100% - 40px);
	max-width: 900px;
	z-index: 60;
	display: flex;
	align-items: center;
	justify-content: center;
	pointer-events: none;
}

.status-footer-inner {
	display: flex;
	align-items: center;
	gap: 12px;
	width: 100%;
	padding: 6px 12px;
	background: rgba(15, 23, 42, 0.45);
	backdrop-filter: blur(12px);
	border: 1px solid rgba(255, 255, 255, 0.08);
	border-radius: 999px;
	pointer-events: auto;
	box-shadow: 0 8px 32px rgba(0, 0, 0, 0.35);
}

.play-pause-icon-btn {
	width: 32px;
	height: 32px;
	flex-shrink: 0;
	background: rgba($accent, 0.1);
	border: 1px solid rgba($accent, 0.2);
	border-radius: 50%;
	color: $accent;
	display: flex;
	align-items: center;
	justify-content: center;
	cursor: pointer;
	transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);

	&:hover {
		background: $accent;
		color: #fff;
		transform: scale(1.1);
		box-shadow: 0 0 15px rgba($accent, 0.4);
	}

	span {
		font-size: 20px;
		line-height: 1;
	}
}

.premium-progress-container {
	flex: 1;
	height: 4px;
	background: rgba(255, 255, 255, 0.08);
	border-radius: 2px;
	overflow: hidden;
	position: relative;
}

.premium-progress-fill {
	height: 100%;
	background: linear-gradient(90deg, $accent, #818cf8);
	width: 0;
	transition-property: width;
	transition-timing-function: linear;
	box-shadow: 0 0 8px rgba($accent, 0.5);
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

