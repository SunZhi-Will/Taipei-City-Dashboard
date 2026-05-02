<!-- Developed By Taipei Urban Intelligence Center 2023-2024 -->
<!-- Map View - Main container for map page -->

<script setup>
/* global gtag */
import { computed, onMounted, onBeforeUnmount, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useAuthStore } from "../store/authStore";
import { useMapStore } from "../store/mapStore";
import MapContainer from "../components/map/MapContainer.vue";
import MapLayerSidebar from "../components/map/MapLayerSidebar.vue";
import MapAnalysisPanel from "../components/map/MapAnalysisPanel.vue";
import MoreInfo from "../components/dialogs/MoreInfo.vue";
import ReportIssue from "../components/dialogs/ReportIssue.vue";

const { VITE_APP_TITLE } = import.meta.env;

const authStore = useAuthStore();
const mapStore = useMapStore();
const route = useRoute();
const router = useRouter();

const islandCollapsed = ref(false);
const selectedAnalysisComponent = ref(null);

const dashboardRoute = computed(() => {
	const nextQuery = {};

	if (route.query.index) {
		nextQuery.index = route.query.index;
	}

	if (route.query.city) {
		nextQuery.city = route.query.city;
	}

	return {
		name: "dashboard",
		...(Object.keys(nextQuery).length > 0 ? { query: nextQuery } : {}),
	};
});

const mapRoute = computed(() => {
	const nextQuery = {};

	if (route.query.index) {
		nextQuery.index = route.query.index;
	}

	if (route.query.city) {
		nextQuery.city = route.query.city;
	}

	return {
		name: "mapview",
		...(Object.keys(nextQuery).length > 0 ? { query: nextQuery } : {}),
	};
});

const aiStudioRoute = computed(() => {
	const nextQuery = {};

	if (route.query.index) {
		nextQuery.index = route.query.index;
	}

	if (route.query.city) {
		nextQuery.city = route.query.city;
	}

	return {
		path: "/ai-studio",
		...(Object.keys(nextQuery).length > 0 ? { query: nextQuery } : {}),
	};
});

function returnToDashboard() {
	router.push(dashboardRoute.value);
}

function handleSwitchDashboard({ scope, dashboard, city }) {
	const nextQuery = { index: dashboard.index };
	if (city) {
		nextQuery.city = city;
	}
	router.push({ name: "mapview", query: nextQuery });

	if (scope === "public") {
		gtag("event", "popular_thematic_layer", {
			dashboard_city: city,
			layer_name: dashboard.name,
			city_layer: `${city}-${dashboard.name}`,
			time: Date.now(),
		});
	}
}

function handleOpenAnalysis({ component }) {
	selectedAnalysisComponent.value = component || null;
}

function handleCloseAnalysisByToggle({ component }) {
	if (!component) {
		selectedAnalysisComponent.value = null;
		return;
	}

	if (String(selectedAnalysisComponent.value?.id || "") === String(component.id || "")) {
		selectedAnalysisComponent.value = null;
	}
}

function handleCloseAnalysis() {
	selectedAnalysisComponent.value = null;
}

onMounted(() => {
	// Initialize map
});

onBeforeUnmount(() => {
	// Clean up map and all related resources when leaving the page
	mapStore.destroyMapBox();
});
</script>

<template>
  <div class="map-page">
    <!-- Map Container (full screen) -->
    <MapContainer class="map-page-map" />

    <!-- Home Button -->
    <button
      class="map-logo-btn"
      title="返回儀表板"
      @click="returnToDashboard"
    >
      <img
        src="../assets/images/TUIC.svg"
        alt="TUIC logo"
      >
    </button>

    <!-- Navigation Capsule -->
    <nav class="map-nav-capsule hide-if-mobile">
      <router-link
        :to="dashboardRoute"
        class="map-nav-link"
      >
        儀表板總覽
      </router-link>
      <router-link
        :to="mapRoute"
        class="map-nav-link"
      >
        地圖交叉比對
      </router-link>
      <router-link
        :to="aiStudioRoute"
        class="map-nav-link"
      >
        AI Studio
      </router-link>
    </nav>

    <!-- Layer Sidebar -->
		<!-- Left Column: Sidebar + Analysis Panel (unified block, no overlap) -->
		<div class="map-left-column">
			<MapLayerSidebar
      :is-collapsed="islandCollapsed"
      @update:is-collapsed="islandCollapsed = $event"
      @switch-dashboard="handleSwitchDashboard"
			@open-analysis="handleOpenAnalysis"
			@close-analysis="handleCloseAnalysisByToggle"
			/>

			<MapAnalysisPanel
				v-if="selectedAnalysisComponent"
				:component="selectedAnalysisComponent"
				@close="handleCloseAnalysis"
			/>
		</div>

    <!-- Dialogs -->
    <MoreInfo />
    <ReportIssue />
  </div>
</template>

<style scoped lang="scss">
.map-page {
	position: relative;
	width: 100vw;
	height: calc(100vh);
	height: calc(var(--vh) * 100);
	overflow: hidden;
	background: #0b0d0f;

	&-map {
		width: 100%;
		height: 100%;
	}
}

.map-logo-btn {
	position: absolute;
	top: 12px;
	left: 12px;
	width: 48px;
	height: 48px;
	border-radius: 50%;
	background: rgba(12, 16, 19, 0.82);
	backdrop-filter: blur(12px);
	border: 1px solid rgba(255, 255, 255, 0.16);
	display: flex;
	align-items: center;
	justify-content: center;
	z-index: 25;
	cursor: pointer;

	img {
		width: 24px;
		height: 24px;
		filter: invert(1);
	}

	&:hover {
		background: rgba(12, 16, 19, 0.95);
		border-color: rgba(255, 255, 255, 0.24);
	}
}

.map-nav-capsule {
	position: absolute;
	top: 12px;
	left: 68px;
	display: flex;
	align-items: center;
	gap: 8px;
	padding: 8px 12px;
	background: rgba(12, 16, 19, 0.82);
	backdrop-filter: blur(12px);
	border: 1px solid rgba(255, 255, 255, 0.16);
	border-radius: 24px;
	z-index: 25;
}

.map-nav-link {
	padding: 6px 12px;
	background: transparent;
	color: #f2f4f8;
	text-decoration: none;
	font-size: 0.75rem;
	border-radius: 16px;
	position: relative;
	transition: background 0.2s ease, color 0.2s ease;

	&:hover {
		background: rgba(255, 255, 255, 0.1);
	}
}

.map-nav-link.router-link-active,
.map-nav-link.router-link-exact-active {
	background: rgba(255, 255, 255, 0.22);
	color: #ffffff;
	font-weight: 600;
	box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.22);
}

.map-left-column {
	position: absolute;
	top: 68px;
	left: 12px;
	bottom: 12px;
	z-index: 20;
	display: flex;
	flex-direction: column;
	gap: 8px;
	align-items: flex-start;
	pointer-events: none;
	overflow: visible;

	> * {
		pointer-events: auto;
	}
}

</style>

