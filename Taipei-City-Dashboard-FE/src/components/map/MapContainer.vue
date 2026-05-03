<!-- Developed by Taipei Urban Intelligence Center 2023-2024-->

<script setup>
/* global gtag */
import { onMounted, onBeforeUnmount, ref, computed, watch } from "vue";
import { useRoute } from "vue-router";
import { useAuthStore } from "../../store/authStore";
import { useContentStore } from "../../store/contentStore";
import { useDialogStore } from "../../store/dialogStore";
import { useMapStore } from "../../store/mapStore";
import http from "../../router/axios";

import AddViewPoint from "../dialogs/AddViewPoint.vue";
import MobileLayers from "../dialogs/MobileLayers.vue";
import IncidentReport from "../dialogs/IncidentReport.vue";
import FindClosestPoint from "../dialogs/FindClosestPoint.vue";
import { savedLocations } from "../../assets/configs/mapbox/savedLocations.js";

const authStore = useAuthStore();
const mapStore = useMapStore();
const dialogStore = useDialogStore();
const contentStore = useContentStore();
const route = useRoute();

defineOptions({ inheritAttrs: false });

const districtLayer = ref(false);
const villageLayer = ref(false);
const locationQuery = ref("");
const isLocating = ref(false);
const isAIResolving = ref(false);
const isSearchExpanded = ref(false);
const isAISearchMode = ref(false);

const MAX_LNG = 180;
const MIN_LNG = -180;
const MAX_LAT = 90;
const MIN_LAT = -90;
const TAIPEI_BBOX = "121.3,24.9,121.75,25.3";

const LANDMARK_ALIASES = {
	台北花博公園: [121.52173, 25.07059],
	臺北花博公園: [121.52173, 25.07059],
	花博公園: [121.52173, 25.07059],
	圓山花博公園: [121.52173, 25.07059],
	花博: [121.52173, 25.07059],
	台北101: [121.5645, 25.0338],
	臺北101: [121.5645, 25.0338],
	台北101大樓: [121.5645, 25.0338],
	臺北101大樓: [121.5645, 25.0338],
	101: [121.5645, 25.0338],
};

const canUseFindClosestPoint = computed(() => {
	let pointLayerCount = 0;

	mapStore.currentVisibleLayers.forEach((layer) => {
		if (["circle", "symbol"].includes(layer.split("-")[1])) {
			pointLayerCount++;
		}
	});

	return pointLayerCount === 1;
});

function toggleDistrictLayer() {
	districtLayer.value = !districtLayer.value;
	mapStore.toggleDistrictBoundaries(districtLayer.value);
	// 載入區界時觸發GA自訂事件
	gtag('event','map_actions', {
		action_type: "載入區界",
		time: Date.now(),
  	})
}

function toggleVillageLayer() {
	villageLayer.value = !villageLayer.value;
	mapStore.toggleVillageBoundaries(villageLayer.value);
	// 載入里界時觸發GA自訂事件
	gtag('event','map_actions', {
		action_type: "載入里界",
		time: Date.now(),
  	})
}

// 尋找最近點時觸發GA自訂事件
function findClosestPointGA() {
	gtag('event','map_actions', {
		action_type: "尋找最近點",
		time: Date.now(),
  	})
}

function parseCoordinateInput(rawInput) {
	if (!rawInput) return null;

	const tokens = rawInput
		.trim()
		.replace(/[，；、]/g, ",")
		.split(/[\s,]+/)
		.filter(Boolean);

	if (tokens.length !== 2) return null;

	const first = Number(tokens[0]);
	const second = Number(tokens[1]);

	if (Number.isNaN(first) || Number.isNaN(second)) return null;

	const isLngLat =
		first >= MIN_LNG && first <= MAX_LNG && second >= MIN_LAT && second <= MAX_LAT;
	const isLatLng =
		first >= MIN_LAT && first <= MAX_LAT && second >= MIN_LNG && second <= MAX_LNG;

	if (!isLngLat && !isLatLng) return null;

	if (isLngLat && !isLatLng) {
		return [first, second];
	}

	if (!isLngLat && isLatLng) {
		return [second, first];
	}

	return [first, second];
}

function normalizeQueryText(rawInput) {
	return String(rawInput || "")
		.trim()
		.toLowerCase()
		.replace(/\s+/g, "")
		.replace(/臺/g, "台");
}

function resolveKnownLandmark(rawInput) {
	const normalizedInput = normalizeQueryText(rawInput);
	const aliasEntries = Object.entries(LANDMARK_ALIASES);

	for (const [alias, coordinates] of aliasEntries) {
		if (normalizeQueryText(alias) === normalizedInput) {
			return { alias, coordinates };
		}
	}

	for (const [alias, coordinates] of aliasEntries) {
		if (normalizedInput.includes(normalizeQueryText(alias))) {
			return { alias, coordinates };
		}
	}

	return null;
}

function containsTaipeiKeyword(rawInput) {
	const normalized = normalizeQueryText(rawInput);
	return normalized.includes("台北") || normalized.includes("臺北");
}

function scoreGeocodeCandidate(feature, input) {
	const placeName = String(feature?.place_name || "");
	const normalizedPlaceName = normalizeQueryText(placeName);
	const normalizedInput = normalizeQueryText(input);
	const isTaipeiIntent = containsTaipeiKeyword(input);
	const isPoi = Array.isArray(feature?.place_type)
		? feature.place_type.includes("poi")
		: false;

	let score = 0;

	if (normalizedPlaceName.includes(normalizedInput)) {
		score += 120;
	}

	const queryTokens = normalizedInput.split(/[^\u4e00-\u9fa5a-z0-9]+/).filter(Boolean);
	if (queryTokens.length > 0) {
		const matchedTokenCount = queryTokens.filter((token) =>
			normalizedPlaceName.includes(token),
		).length;
		score += matchedTokenCount * 18;
	}

	if (isPoi) {
		score += 35;
	}

	if (isTaipeiIntent) {
		if (placeName.includes("臺北市") || placeName.includes("台北市")) {
			score += 80;
		}
		if (placeName.includes("新北市")) {
			score -= 55;
		}
	}

	if (normalizedInput.includes("101") && normalizedPlaceName.includes("101")) {
		score += 20;
	}

	return score;
}

function pickBestGeocodeResult(features, input) {
	if (!Array.isArray(features) || features.length === 0) return null;

	const scored = features
		.map((feature) => ({
			feature,
			score: scoreGeocodeCandidate(feature, input),
		}))
		.sort((a, b) => b.score - a.score);

	return scored[0]?.feature || null;
}

function moveMapToLocation(lng, lat) {
	if (!mapStore.map) return;

	mapStore.map.flyTo({
		center: [lng, lat],
		zoom: Math.max(mapStore.map.getZoom(), 15),
		duration: 1200,
		essential: true,
	});

	if (mapStore.marker) {
		mapStore.marker.setLngLat([lng, lat]).addTo(mapStore.map);
	}
}

function parseAIResolvedLocation(content, fallbackName = "目標位置") {
	if (!content) return null;

	const rawContent = String(content).trim();
	if (!rawContent) return null;

	const jsonMatch = rawContent.match(/\{[\s\S]*\}/);
	const jsonText = jsonMatch ? jsonMatch[0] : rawContent;

	try {
		const parsed = JSON.parse(jsonText);
		const lng = Number(parsed?.longitude ?? parsed?.lng ?? parsed?.lon);
		const lat = Number(parsed?.latitude ?? parsed?.lat);

		if (
			Number.isFinite(lng) &&
			Number.isFinite(lat) &&
			lng >= MIN_LNG &&
			lng <= MAX_LNG &&
			lat >= MIN_LAT &&
			lat <= MAX_LAT
		) {
			return {
				name: parsed?.location_name || parsed?.name || fallbackName,
				coordinates: [lng, lat],
			};
		}
	} catch (_error) {
		return null;
	}

	return null;
}

async function resolveLocationByAI(input) {
	isAIResolving.value = true;

	try {
		const response = await http.post("/ai/chat/twai", {
			session: `map-search-${Date.now()}`,
			app_mode: "map_search",
			stream: false,
			max_new_tokens: 120,
			temperature: 0.1,
			tool_choice: "none",
			tools: [],
			messages: [
				{
					role: "system",
					content:
						"你是地圖定位助手。請解析使用者地點並只回傳 JSON：{\"location_name\":\"地點名\",\"longitude\":121.5,\"latitude\":25.0}。不可回傳任何其他文字。",
				},
				{
					role: "user",
					content: `請解析以下地點並輸出座標：${input}`,
				},
			],
		});

		const aiContent = response?.data?.data?.content;
		return parseAIResolvedLocation(aiContent, input);
	} catch (error) {
		console.error("AI location resolve failed:", error);
		return null;
	} finally {
		isAIResolving.value = false;
	}
}

async function handleLocationSearch() {
	const input = locationQuery.value.trim();

	if (!input) {
		dialogStore.showNotification("info", "請輸入地址或座標");
		return;
	}

	if (!mapStore.map) {
		dialogStore.showNotification("fail", "地圖尚未完成初始化");
		return;
	}

	const coordinateResult = parseCoordinateInput(input);
	if (coordinateResult) {
		moveMapToLocation(coordinateResult[0], coordinateResult[1]);
		dialogStore.showNotification("success", "已移動到指定座標");
		return;
	}

	const knownLandmarkMatch = resolveKnownLandmark(input);
	if (knownLandmarkMatch) {
		moveMapToLocation(
			knownLandmarkMatch.coordinates[0],
			knownLandmarkMatch.coordinates[1],
		);
		dialogStore.showNotification("success", `已定位到 ${knownLandmarkMatch.alias}`);
		return;
	}

	if (isAISearchMode.value) {
		const aiResolved = await resolveLocationByAI(input);
		if (aiResolved?.coordinates) {
			moveMapToLocation(aiResolved.coordinates[0], aiResolved.coordinates[1]);
			dialogStore.showNotification("success", `已由AI定位到 ${aiResolved.name}`);
			return;
		}

		dialogStore.showNotification("info", "AI模式解析失敗，改用一般搜尋");
	}

	const mapboxToken = import.meta.env.VITE_MAPBOXTOKEN;
	if (!mapboxToken) {
		dialogStore.showNotification("fail", "找不到地圖搜尋金鑰，請聯絡管理員");
		return;
	}

	isLocating.value = true;

	try {
		const endpoint =
			`https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(
				input,
			)}.json` +
			`?access_token=${mapboxToken}&autocomplete=true&language=zh-TW&limit=8&country=tw&types=poi,address,place,locality,neighborhood&bbox=${TAIPEI_BBOX}`;
		const response = await fetch(endpoint);

		if (!response.ok) {
			throw new Error(`Geocoding request failed: ${response.status}`);
		}

		const data = await response.json();
		const result = pickBestGeocodeResult(data?.features, input);

		if (!result?.center || result.center.length < 2) {
			dialogStore.showNotification("fail", "找不到符合的地址，請換個關鍵字");
			return;
		}

		moveMapToLocation(result.center[0], result.center[1]);
		dialogStore.showNotification("success", `已定位到 ${result.place_name || input}`);
	} catch (error) {
		console.error("Address search failed:", error);
		dialogStore.showNotification("fail", "地址搜尋失敗，請稍後再試");
	} finally {
		isLocating.value = false;
	}
}

function toggleSearchBar() {
	isSearchExpanded.value = !isSearchExpanded.value;

	if (!isSearchExpanded.value) {
		locationQuery.value = "";
	}
}

function setAISearchMode(enabled) {
	const nextValue = Boolean(enabled);
	if (nextValue === isAISearchMode.value) return;

	isAISearchMode.value = nextValue;
	dialogStore.showNotification("info", nextValue ? "AI模式已開啟" : "一般模式已開啟");
}

watch(
	() => route.query?.city,
	(newValue) => {
		newValue 
			? mapStore.updateMapViewForCity(newValue)
			: mapStore.updateMapViewForCity('default');
	}
);

onMounted(() => {
	mapStore.initializeMapBox();
	mapStore.setCurrentLocation();
	route.query.city 
		? mapStore.updateMapViewForCity(route.query.city)
		: mapStore.updateMapViewForCity('default');
});

onBeforeUnmount(() => {
	mapStore.destroyMapBox();
});
</script>

<template>
  <div
    class="mapcontainer"
    v-bind="$attrs"
  >
    <div class="mapcontainer-map">
      <!-- #mapboxBox needs to be empty to ensure Mapbox performance -->
      <div id="mapboxBox" />
      <div class="mapcontainer-layers">
        <button
          :style="{
            color: districtLayer
              ? 'var(--color-highlight)'
              : 'var(--color-component-background)',
          }"
          @click="toggleDistrictLayer"
        >
          區
        </button>
        <button
          :style="{
            color: villageLayer
              ? 'var(--color-highlight)'
              : 'var(--color-component-background)',
          }"
          @click="toggleVillageLayer"
        >
          里
        </button>

        <button
          v-if="canUseFindClosestPoint"
          :style="{
            color: villageLayer
              ? 'var(--color-highlight)'
              : 'var(--color-component-background)',
          }"
          class="hide-if-mobile"
          type="button"
          @click="dialogStore.showDialog('findClosestPoint'); findClosestPointGA();"
        >
          近
        </button>
        <button
          class="show-if-mobile"
          @click="dialogStore.showDialog('mobileLayers')"
        >
          <span>layers</span>
        </button>
        <div
          v-if="mapStore.loadingLayers.length > 0"
          class="mapcontainer-layers-loading"
        >
          <div />
        </div>
      </div>

      <button
        v-if="authStore.user.is_admin"
        class="mapcontainer-layers-incident"
        title="通報災害"
        @click="dialogStore.showDialog('incidentReport')"
      >
        !
      </button><!-- The key prop informs vue that the component should be updated when switching dashboards -->
      <MobileLayers :key="contentStore.currentDashboard.index" />
      <IncidentReport />
      <FindClosestPoint />

      <div
				class="mapcontainer-quick-locations hide-if-mobile"
				:class="{ 'mapcontainer-quick-locations--raised': isSearchExpanded }"
			>
        <button
          class="mapcontainer-quick-locations-button"
          @click="
            mapStore.easeToLocation([
              [121.536609, 25.044808],
              12.5,
              0,
              0,
            ])
          "
        >
          返回預設
        </button>
        <template v-if="!authStore.user?.user_id">
          <button
            v-for="(item, index) in savedLocations"
            :key="`${item[4]}-${index}`"
            class="mapcontainer-quick-locations-button"
            @click="mapStore.easeToLocation(item)"
          >
            {{ item[4] }}
          </button>
        </template>
        <div
          v-for="(item, index) in mapStore.viewPoints"
          :key="index"
          class="mapcontainer-quick-locations-item"
        >
          <button
            v-if="item.point_type === 'view'"
            class="mapcontainer-quick-locations-button"
            @click="mapStore.easeToLocation(item)"
          >
            {{ item.name }}
          </button>
          <div
            v-if="authStore.user?.user_id"
            class="mapcontainer-quick-locations-delete"
            @click="mapStore.removeViewPoint(item)"
          >
            <span>delete</span>
          </div>
        </div>
        <button
          v-if="authStore.user?.user_id"
          class="mapcontainer-quick-locations-button"
          @click="dialogStore.showDialog('addViewPoint')"
        >
          新增位置
        </button>
				<button
					class="mapcontainer-quick-locations-search-trigger"
					type="button"
					title="搜尋地址或座標"
					@click="toggleSearchBar"
				>
					<span>{{ isSearchExpanded ? "close" : "search" }}</span>
				</button>
      </div>

			<form
				class="mapcontainer-location-search hide-if-mobile"
				:class="{ 'mapcontainer-location-search--open': isSearchExpanded }"
				@submit.prevent="handleLocationSearch"
			>
				<input
					v-model="locationQuery"
					type="text"
					placeholder="輸入地址或座標，例如：台北101 或 121.5654,25.0330"
				>
				<div
					class="mapcontainer-location-search-mode"
					:class="{ 'is-ai': isAISearchMode }"
				>
					<button
						type="button"
						:class="{ 'is-active': !isAISearchMode }"
						@click="setAISearchMode(false)"
					>
						一般
					</button>
					<button
						type="button"
						:class="{ 'is-active': isAISearchMode }"
						@click="setAISearchMode(true)"
					>
						AI
					</button>
				</div>
				<button
					class="mapcontainer-location-search-action"
					type="submit"
					:disabled="isLocating || isAIResolving"
				>
					<span>{{ isLocating || isAIResolving ? "hourglass_top" : "search" }}</span>
				</button>
			</form>
    </div>
  </div>
  <AddViewPoint name="addViewPoint" />
</template>

<style scoped lang="scss">
.mapcontainer {
	position: relative;
	width: 100%;
	height: 100%;
	flex: 1;

	&-map {
		width: 100%;
		height: 100%;
	}

	&-controls {
		display: flex;
		margin-top: 8px;
		overflow: visible;

		button {
			height: 1.5rem;
			width: fit-content;
			margin-right: 6px;
			padding: 4px;
			border-radius: 5px;
			background-color: var(--color-component-background);
			color: var(--color-complement-text);
			cursor: pointer;

			&:focus {
				animation-name: colorfade;
				animation-duration: 4s;
			}
		}

		div {
			position: relative;
			overflow: visible;

			div {
				width: 1.2rem;
				height: 1.2rem;
				position: absolute;
				top: -0.5rem;
				right: -0.3rem;
				display: flex;
				align-items: center;
				justify-content: center;
				border-radius: 50%;
				opacity: 0;
				background-color: var(--color-border);
				box-shadow: 0 0 3px black;
				transition: opacity 0.2s;
				z-index: 10;
				pointer-events: none;
				cursor: pointer;

				span {
					color: rgb(185, 185, 185);
					font-family: var(--font-icon);
					font-size: 0.8rem;
					transition: color 0.2s;
				}

				&:hover span {
					color: rgb(255, 65, 44);
				}
			}

			&:hover div {
				opacity: 1;
				pointer-events: all;
			}
		}

		input {
			height: calc(1.5rem - 4px);
			width: 1.7rem;
			margin-right: 6px;
			padding: 2px 4px;
			border-radius: 5px;
			border: none;
			background-color: rgb(30, 30, 30);
			color: var(--color-complement-text);
			font-size: 0.82rem;

			&:focus {
				width: 5.4rem;
			}
		}
	}

	&-layers {
		position: absolute;
		right: 10px;
		top: 150px;
		z-index: 1;
		display: flex;
		flex-direction: column;
		row-gap: 4px;

		button {
			width: 1.75rem;
			height: 1.75rem;
			display: flex;
			align-items: center;
			justify-content: center;
			border-radius: 50%;
			background-color: white;
			transition: color 0.2s;
		}

		span {
			color: var(--color-component-background);
			font-size: 1.2rem;
			font-family: var(--font-icon);
		}

		&-loading {
			height: 2rem;
			display: flex;
			align-items: center;
			justify-content: center;
			z-index: 20;

			@media (max-width: 1000px) {
				top: 145px;
			}

			div {
				width: 1.3rem;
				height: 1.3rem;
				border-radius: 50%;
				border: solid 4px var(--color-border);
				border-top: solid 4px var(--color-highlight);
				animation: spin 0.7s ease-in-out infinite;
			}
		}

		&-incident {
			position: absolute;
			right: 10px;
			bottom: 60px;
			width: 50px;
			height: 50px;
			border-radius: 50%;
			background-color: var(--color-component-background);
			display: flex;
			align-items: center;
			justify-content: center;
			transition: background-color 0.2s, color 0.2s;
			font-size: var(--font-xl);

			&:hover {
				background-color: var(--color-highlight);
			}
		}
	}
}

.mapcontainer-quick-locations {
	position: absolute;
	bottom: 12px;
	left: 50%;
	transform: translateX(-50%);
	display: flex;
	flex-direction: row;
	flex-wrap: wrap;
	justify-content: center;
	align-items: center;
	gap: 8px;
	z-index: 20;
	max-width: min(90vw, 860px);
	transition: transform 0.24s ease;

	&--raised {
		transform: translateX(-50%) translateY(-52px);
	}

	&-button {
		min-height: 2rem;
		padding: 6px 10px;
		border-radius: 999px;
		background: rgba(12, 16, 19, 0.82);
		backdrop-filter: blur(12px);
		border: 1px solid rgba(255, 255, 255, 0.16);
		color: #f2f4f8;
		font-size: 0.78rem;
		line-height: 1.2;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: flex-start;
		transition: background 0.2s ease, border-color 0.2s ease;
		text-align: left;
		white-space: nowrap;

		&:hover {
			background: rgba(12, 16, 19, 0.95);
			border-color: rgba(255, 255, 255, 0.24);
		}
	}

	&-item {
		position: relative;

		.mapcontainer-quick-locations-delete {
			position: absolute;
			top: -8px;
			right: -8px;
			width: 20px;
			height: 20px;
			border-radius: 50%;
			background: rgba(255, 65, 44, 0.9);
			display: flex;
			align-items: center;
			justify-content: center;
			cursor: pointer;
			opacity: 0;
			transition: opacity 0.2s;
			z-index: 10;

			span {
				color: white;
				font-family: var(--font-icon);
				font-size: 0.7rem;
			}
		}

		&:hover .mapcontainer-quick-locations-delete {
			opacity: 1;
		}
	}

	&-search-trigger {
		width: 2rem;
		height: 2rem;
		border-radius: 50%;
		background: rgba(12, 16, 19, 0.82);
		backdrop-filter: blur(12px);
		border: 1px solid rgba(255, 255, 255, 0.16);
		display: inline-flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		transition: background 0.2s ease, border-color 0.2s ease;

		span {
			font-family: var(--font-icon);
			font-size: 1rem;
			color: #f2f4f8;
		}

		&:hover {
			background: rgba(12, 16, 19, 0.95);
			border-color: rgba(255, 255, 255, 0.24);
		}
	}

}

.mapcontainer-location-search {
	position: absolute;
	left: 50%;
	bottom: 12px;
	transform: translateX(-50%);
	z-index: 21;
	display: flex;
	align-items: center;
	gap: 10px;
	width: min(92vw, 560px);
	height: 2.6rem;
	padding: 0 8px 0 14px;
	border-radius: 999px;
	background: linear-gradient(145deg, rgba(19, 24, 29, 0.9), rgba(9, 12, 15, 0.82));
	backdrop-filter: blur(12px);
	border: 1px solid rgba(255, 255, 255, 0.22);
	box-shadow: 0 8px 24px rgba(0, 0, 0, 0.28), inset 0 1px 0 rgba(255, 255, 255, 0.06);
	opacity: 0;
	pointer-events: none;
	transition: opacity 0.24s ease, transform 0.24s ease;
	transform: translateX(-50%) translateY(20px);

	&--open {
		opacity: 1;
		pointer-events: all;
		transform: translateX(-50%) translateY(0);
	}

	input {
		flex: 1;
		min-width: 0;
		height: 100%;
		padding: 0;
		border: none;
		background: transparent;
		color: #f2f4f8;
		font-size: 0.84rem;
		line-height: 1.25;
		outline: none;

		&::placeholder {
			color: rgba(242, 244, 248, 0.66);
		}
	}

	&-action {
		width: 2.1rem;
		height: 2.1rem;
		padding: 0;
		border-radius: 999px;
		border: none;
		background: rgba(255, 255, 255, 0.14);
		color: #ffffff;
		font-size: 1rem;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		transition: background 0.2s ease, transform 0.2s ease;

		span {
			font-family: var(--font-icon);
			font-size: 1rem;
		}

		&:hover:not(:disabled) {
			background: rgba(255, 255, 255, 0.24);
			transform: translateY(-1px);
		}

		&:disabled {
			opacity: 0.6;
			cursor: not-allowed;
		}
	}

	&-mode {
		position: relative;
		width: 5.6rem;
		height: 2.2rem;
		padding: 3px;
		border-radius: 999px;
		background: rgba(255, 255, 255, 0.1);
		border: 1px solid rgba(255, 255, 255, 0.2);
		display: grid;
		grid-template-columns: 1fr 1fr;
		align-items: center;

		&::before {
			content: "";
			position: absolute;
			top: 3px;
			left: 3px;
			width: calc(50% - 3px);
			height: calc(100% - 6px);
			border-radius: 999px;
			background: linear-gradient(160deg, rgba(96, 165, 250, 0.55), rgba(56, 189, 248, 0.38));
			transition: transform 0.2s ease;
			box-shadow: 0 4px 10px rgba(56, 189, 248, 0.2);
		}

		&.is-ai::before {
			transform: translateX(calc(100% - 3px));
		}

		button {
			position: relative;
			z-index: 1;
			height: 100%;
			border: none;
			background: transparent;
			color: rgba(242, 244, 248, 0.74);
			font-size: 0.72rem;
			font-weight: 700;
			letter-spacing: 0.04em;
			cursor: pointer;
			border-radius: 999px;
			transition: color 0.2s ease;

			&.is-active {
				color: #f2f4f8;
			}
		}
	}
}

@media (max-width: 768px) {
	.mapcontainer-location-search {
		bottom: 14px;
		width: min(94vw, 560px);
		height: 2.45rem;
		padding: 0 7px 0 12px;

		input {
			font-size: 0.78rem;
		}

		&-mode {
			width: 5.1rem;
			height: 2rem;
		}

		&-action {
			width: 1.95rem;
			height: 1.95rem;
		}
	}
}

#mapboxBox {
	width: 100%;
	height: 100%;
	border-radius: 5px;
}

@keyframes colorfade {
	0% {
		color: var(--color-highlight);
	}

	75% {
		color: var(--color-highlight);
	}

	100% {
		color: var(--color-complement-text);
	}
}
</style>
