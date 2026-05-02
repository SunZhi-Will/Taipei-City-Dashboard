<!-- Developed by Taipei Urban Intelligence Center 2023-2024-->

<script setup>
import { ref, computed, onUnmounted } from "vue";
import { useMapStore } from "../../store/mapStore";
import { useTimeStore } from "../../store/timeStore";
import bus from "../assets/map/bus.png";
import metro from "../assets/map/metro.png";
import triangle_green from "../assets/map/triangle_green.png";
import triangle_white from "../assets/map/triangle_white.png";
import bike_green from "../assets/map/bike_green.png";
import bike_orange from "../assets/map/bike_orange.png";
import bike_red from "../assets/map/bike_red.png";
import cross_bold from "../assets/map/cross_bold.png";
import cross_normal from "../assets/map/cross_normal.png";
import cctv from "../assets/map/cctv.png";
import live from "../assets/map/live.png";

const props = defineProps([
	"chart_config",
	"series",
	"map_config",
	"map_filter",
	"map_filter_on",
]);
const emits = defineEmits([
	"filterByParam",
	"filterByLayer",
	"clearByParamFilter",
	"clearByLayerFilter",
	"fly"
]);

const mapStore  = useMapStore();
const timeStore = useTimeStore();

const mapSyncIndex = computed(() => props.map_config?.[0]?.index ?? null);

const availableMonths = computed(() =>
	mapSyncIndex.value ? timeStore.getAvailableMonths(mapSyncIndex.value) : [],
);

const showAnimControls = computed(() => availableMonths.value.length > 1);
// sliderMonths: oldest→newest (left→right on slider)
const sliderMonths = computed(() => [...availableMonths.value].reverse());

const isPlaying    = ref(false);
const currentMonth = computed(() => timeStore.selectedMonth ?? availableMonths.value[0] ?? null);

const sliderIdx = computed(() => {
	const m = currentMonth.value;
	if (!m) return sliderMonths.value.length - 1;
	const idx = sliderMonths.value.indexOf(m);
	return idx >= 0 ? idx : sliderMonths.value.length - 1;
});

function formatMonthLabel(ym) {
	if (!ym) return "最新";
	const [y, m] = ym.split("-");
	return `${y} 年 ${parseInt(m, 10)} 月`;
}

function togglePlay() {
	if (!mapSyncIndex.value) return;
	if (isPlaying.value) {
		mapStore.stopMonthAnimation();
		isPlaying.value = false;
	} else {
		mapStore.animateMonths(mapSyncIndex.value, 1500);
		isPlaying.value = true;
	}
}

function onSliderInput(e) {
	const idx   = parseInt(e.target.value);
	const month = sliderMonths.value[idx];
	if (!month || !mapSyncIndex.value) return;
	if (isPlaying.value) {
		mapStore.stopMonthAnimation();
		isPlaying.value = false;
	}
	mapStore.setMapMonth(mapSyncIndex.value, month);
}

onUnmounted(() => {
	if (isPlaying.value) mapStore.stopMonthAnimation();
});

function returnIcon(name) {
	switch (name) {
	case "bus":
		return bus;
	case "metro":
		return metro;
	case "triangle_green":
		return triangle_green;
	case "triangle_white":
		return triangle_white;
	case "bike_green":
		return bike_green;
	case "bike_orange":
		return bike_orange;
	case "bike_red":
		return bike_red;
	case "cross_bold":
		return cross_bold;
	case "cross_normal":
		return cross_normal;
	case "cctv":
		return cctv;
	case "live":
		return live;
	default:
		return "";
	}
}

const selectedIndex = ref(null);

function handleDataSelection(index) {
	if (!props.map_filter || !props.map_filter_on) {
		return;
	}
	if (index !== selectedIndex.value) {
		// Supports filtering by xAxis
		if (props.map_filter.mode === "byParam") {
			emits(
				"filterByParam",
				props.map_filter,
				props.map_config,
				props.series[index].name,
				null
			);
		}
		// Supports filtering by xAxis
		else if (props.map_filter.mode === "byLayer") {
			emits("filterByLayer", props.map_config, props.series[index].name);
		}
		selectedIndex.value = index;
	} else {
		if (props.map_filter.mode === "byParam") {
			emits("clearByParamFilter", props.map_config);
		} else if (props.map_filter.mode === "byLayer") {
			emits("clearByLayerFilter", props.map_config);
		}
		selectedIndex.value = null;
	}
}
</script>

<template>
  <div class="maplegend">
    <!-- 月份動畫控制：時間上下兩排 -->
    <div
      v-if="showAnimControls"
      class="maplegend-anim"
    >
      <span class="maplegend-anim-month">{{ formatMonthLabel(currentMonth) }}</span>
      <div class="maplegend-anim-bar">
        <button
          class="maplegend-anim-btn"
          :title="isPlaying ? '暫停' : '播放'"
          @click="togglePlay"
        >
          <span class="material-icons-round">{{ isPlaying ? 'pause' : 'play_arrow' }}</span>
        </button>
        <input
          type="range"
          class="maplegend-anim-slider"
          :min="0"
          :max="sliderMonths.length - 1"
          :value="sliderIdx"
          @input="onSliderInput"
        >
      </div>
    </div>
    <div class="maplegend-legend">
      <button
        v-for="(item, index) in series"
        :key="item.name"
        :class="{
          'maplegend-legend-item': true,
          'maplegend-filter': map_filter_on && map_filter,
          'maplegend-selected': map_filter_on && selectedIndex === index,
        }"
        @click="handleDataSelection(index)"
      >
        <div
          v-if="item.type !== 'symbol'"
          :style="{
            backgroundColor: `${chart_config.color[index]}`,
            height: item.type === 'line' ? '0.4rem' : '1rem',
            borderRadius: item.type === 'circle' ? '50%' : '2px',
          }"
        />
        <img
          v-else
          :src="returnIcon(item.icon)"
        >
        <div v-if="item.value">
          <h5>{{ item.name }}</h5>
          <h6>{{ item.value }} {{ chart_config.unit ?? '' }}</h6>
        </div>
        <div v-else>
          <h6>{{ item.name }}</h6>
        </div>
      </button>
    </div>
  </div>
</template>

<style scoped lang="scss">
* {
	margin: 0;
	padding: 0;
	font-family: "微軟正黑體", "Microsoft JhengHei", "Droid Sans", "Open Sans",
		"Helvetica";
	overflow: hidden;
}

button {
	border: none;
	background-color: transparent;
}
.maplegend {
	width: 100%;
	height: 100%;
	min-height: 0;
	display: flex;
	flex-direction: column;
	gap: 4px;
	overflow: hidden;

	&-legend {
		flex: 1;
		min-height: 0;
		width: 100%;
		display: flex;
		flex-direction: column;
		gap: 4px;
		overflow-y: auto;

		&-item {
			display: flex;
			align-items: center;
			padding: 4px 8px;
			border: 1px solid transparent;
			border-radius: 6px;
			transition: box-shadow 0.2s;
			cursor: auto;
			width: 100%;

			div:first-child,
			img {
				width: var(--font-ms);
				flex-shrink: 0;
				margin-right: 0.6rem;
			}

			h5 {
				color: var(--color-complement-text);
				font-size: 0.75rem;
				text-align: left;
			}

			h6 {
				color: var(--color-normal-text);
				font-size: var(--font-ms);
				font-weight: 400;
				text-align: left;
			}
		}
	}

	&-filter {
		border: 1px solid var(--color-border);
		cursor: pointer;

		&:hover {
			box-shadow: 0px 0px 5px black;
		}
	}

	&-selected {
		box-shadow: 0px 0px 5px black;
	}
}

/* 時間控制：上下兩排，優化版 */
.maplegend-anim {
	flex-shrink: 0;
	display: flex;
	flex-direction: column;
	align-items: flex-start;
	gap: 6px;
	padding: 8px 0;
	margin-bottom: 8px;
	border-bottom: 1px solid var(--color-border);

	&-month {
		font-size: 0.85rem;
		font-weight: 700;
		color: var(--color-highlight);
		white-space: nowrap;
		line-height: 1;
		letter-spacing: 0.02em;
	}

	&-bar {
		display: flex;
		align-items: center;
		gap: 10px;
		width: 100%;
	}

	&-btn {
		width: 28px;
		height: 28px;
		background: rgba(var(--color-highlight-rgb, 90, 156, 248), 0.1);
		border: 1px solid rgba(var(--color-highlight-rgb, 90, 156, 248), 0.2) !important;
		border-radius: 50%;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		color: var(--color-highlight);
		transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
		flex-shrink: 0;

		&:hover {
			background: var(--color-highlight);
			color: #fff;
			transform: scale(1.1);
			box-shadow: 0 0 10px rgba(90, 156, 248, 0.4);
		}

		.material-icons-round {
			font-size: 18px;
			line-height: 1;
		}
	}

	&-slider {
		flex: 1;
		min-width: 0;
		height: 6px;
		-webkit-appearance: none;
		appearance: none;
		background: rgba(255, 255, 255, 0.1);
		border-radius: 3px;
		outline: none;
		cursor: pointer;
		position: relative;
		overflow: visible;

		&::-webkit-slider-thumb {
			-webkit-appearance: none;
			appearance: none;
			width: 14px;
			height: 14px;
			border-radius: 50%;
			background: var(--color-highlight);
			border: 2px solid #fff;
			cursor: pointer;
			box-shadow: 0 0 8px rgba(0, 0, 0, 0.5), 0 0 4px var(--color-highlight);
			transition: all 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275);

			&:hover {
				transform: scale(1.25);
				background: #fff;
				border-color: var(--color-highlight);
			}
		}

		&::-moz-range-thumb {
			width: 12px;
			height: 12px;
			border-radius: 50%;
			background: var(--color-highlight);
			border: 2px solid #fff;
			cursor: pointer;
			box-shadow: 0 0 8px rgba(0, 0, 0, 0.5);
			transition: all 0.2s;
		}
	}
}
</style>
