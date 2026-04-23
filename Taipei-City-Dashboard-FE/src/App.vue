<!-- Developed By Taipei Urban Intelligence Center 2023-2024 -->
<!-- 
Lead Developer:  Igor Ho (Full Stack Engineer)
Data Pipelines:  Iima Yu (Data Scientist)
Design and UX: Roy Lin (Fmr. Consultant), Chu Chen (Researcher)
Systems: Ann Shih (Systems Engineer)
Testing: Jack Huang (Data Scientist), Ian Huang (Data Analysis Intern) 
-->
<!-- Department of Information Technology, Taipei City Government -->

<script setup>
import {
	onBeforeMount,
	onMounted,
	onBeforeUnmount,
	ref,
	computed,
	watch,
} from "vue";
import { useRoute } from "vue-router";
import { useAuthStore } from "./store/authStore";
import { useDialogStore } from "./store/dialogStore";
import { useContentStore } from "./store/contentStore";
import { useMapStore } from "./store/mapStore";

import NavBar from "./components/utilities/bars/NavBar.vue";
import SideBar from "./components/utilities/bars/SideBar.vue";
import AdminSideBar from "./components/utilities/bars/AdminSideBar.vue";
import SettingsBar from "./components/utilities/bars/SettingsBar.vue";
import NotificationBar from "./components/dialogs/NotificationBar.vue";
import InitialWarning from "./components/dialogs/InitialWarning.vue";
import ComponentSideBar from "./components/utilities/bars/ComponentSideBar.vue";
import LogIn from "./components/dialogs/LogIn.vue";
import ChatWidgetMount from "./components/chat/ChatWidgetMount.vue";

const authStore = useAuthStore();
const dialogStore = useDialogStore();
const contentStore = useContentStore();

const mapStore = useMapStore();
const route = useRoute();
const updateBoards =
	import.meta.env.VITE_PERSONAL_BOARD_UPDATE?.split(",") || [];
const boardIndex = ref(null);
const board = ref(null);
const frequency = ref(600);
const isMappedToUpdateBoards = ref(false);
// Timers
let chartTimer = null;
let crowdingTimer = null;
let timeTimer = null;
let mrtTimer = null;
// Update 狀態
let isCrowdingUpdating = false;

const updateBoardsMap = computed(() => {
	let needUpdateBoards = [];
	updateBoards.map((board) => {
		const id = board.split(":")[0];
		const updateSeconds = board.split(":")[1];
		needUpdateBoards.push({ id, frequency: updateSeconds });
	});
	return needUpdateBoards;
});

const formattedTimeToUpdate = computed(() => {
	const minutes = Math.floor(contentStore.timeToUpdate / 60);
	const seconds = contentStore.timeToUpdate % 60;
	return `${minutes}:${seconds < 10 ? "0" : ""}${seconds}`;
});

const shouldShowChatWidget = computed(() => {
	return ["dashboard", "mapview"].includes(authStore.currentPath);
});

function reloadChartData() {
	if (!["dashboard", "mapview"].includes(authStore.currentPath)) return;
	contentStore.updateCurrentDashboardAllChartData();
	contentStore.timeToUpdate = frequency.value;

	if (isMappedToUpdateBoards.value) {
		reloadMapData();
	}
}

async function reloadCrowdingChartData() {
	if (!["dashboard", "mapview"].includes(authStore.currentPath)) return;

	if (isCrowdingUpdating) return;

	isCrowdingUpdating = true;
	try {
		await contentStore.updateCurrentDashboardCertainChartData();
	} finally {
		isCrowdingUpdating = false;
	}
}

function updateTimeToUpdate() {
	if (!["dashboard", "mapview"].includes(authStore.currentPath)) return;
	if (contentStore.timeToUpdate <= 0) {
		contentStore.timeToUpdate = 0;
		reloadChartData();
		return;
	}
	contentStore.timeToUpdate -= 5;
}

function reloadMapData() {
	if (!["mapview"].includes(authStore.currentPath)) return;
	mapStore.currentVisibleLayers.forEach((layerName) => {
		mapStore.map.removeLayer(layerName);
		if (mapStore.map.getSource(`${layerName}-source`)) {
			mapStore.map.removeSource(`${layerName}-source`);
		}
		const layerConfig = mapStore.mapConfigs[layerName];

		// 檢查 source
		if (layerConfig.source === "geojson") {
			// 如果 source 是 "geojson"，則使用 fetchLocalGeoJson
			mapStore.fetchLocalGeoJson(layerConfig);
		} else if (layerConfig.source === "raster") {
			// 如果 source 是 "raster"，則使用 addRasterSource
			mapStore.addRasterSource(layerConfig);
		}
	});
}

function reload3DMRTMapData() {
	if (!["mapview"].includes(authStore.currentPath)) return;
	mapStore.currentVisibleLayers.forEach((layerName) => {
		const layerConfig = mapStore.mapConfigs[layerName];
		const lastUpdate = mapStore.layerUpdateTime[layerName];
		const now = Date.now();

		// 只刷新特定組件附屬圖層
		if (
			!layerConfig.title.includes("擁擠程度") ||
			!lastUpdate ||
			now - new Date(lastUpdate).getTime() < 1.5 * 60 * 1000
		) {
			return;
		}

		mapStore.map.removeLayer(layerName);
		if (mapStore.map.getSource(`${layerName}-source`)) {
			mapStore.map.removeSource(`${layerName}-source`);
		}

		// 檢查 source
		if (layerConfig.source === "geojson") {
			// 如果 source 是 "geojson"，則使用 fetchLocalGeoJson
			mapStore.fetchLocalGeoJson(layerConfig);
		} else if (layerConfig.source === "raster") {
			// 如果 source 是 "raster"，則使用 addRasterSource
			mapStore.addRasterSource(layerConfig);
		}
	});
}

const navItems = [
  { name: "儀表板", icon: "dashboard", path: "/dashboard", id: "dashboard" },
  { name: "地圖", icon: "map", path: "/mapview", id: "mapview" },
  { name: "組件", icon: "widgets", path: "/component", id: "component", auth: true },
  { name: "AI", icon: "psychology", path: "/ai-studio", id: "ai-studio" }
];

const filteredNavItems = computed(() => {
  return navItems.filter(item => !item.auth || authStore.token);
});

const isNavItemActive = (itemId) => {
  return authStore.currentPath.includes(itemId);
};

(watch(
	() => route.query,
	(query) => {
		boardIndex.value = query.index;
		board.value = updateBoardsMap.value.find((board) => {
			return board.id === boardIndex.value;
		});
		frequency.value = board.value ? board.value.frequency : 600;
		isMappedToUpdateBoards.value = updateBoardsMap.value.some((board) => {
			return board.id === query.index;
		});
		contentStore.timeToUpdate = frequency.value;
	},
),
{ immediate: true });

onBeforeMount(() => {
	authStore.initialChecks();

	let vh = window.innerHeight * 0.01;
	document.documentElement.style.setProperty("--vh", `${vh}px`);

	window.addEventListener("resize", () => {
		let vh = window.innerHeight * 0.01;
		document.documentElement.style.setProperty("--vh", `${vh}px`);
	});
	// contentStore.wsConnect();
});
onMounted(() => {
	const showInitialWarning = localStorage.getItem("initialWarning");

	if (!showInitialWarning && !window.location.pathname.includes("embed")) {
		dialogStore.showDialog("initialWarning");
	}

	chartTimer = setInterval(reloadChartData, 1000 * frequency.value);
	crowdingTimer = setInterval(reloadCrowdingChartData, 1000 * 60);
	timeTimer = setInterval(updateTimeToUpdate, 1000 * 5);
	mrtTimer = setInterval(reload3DMRTMapData, 1000 * 10);
});
onBeforeUnmount(() => {
	clearInterval(chartTimer);
	clearInterval(crowdingTimer);
	clearInterval(timeTimer);
	clearInterval(mrtTimer);
	// contentStore.wsDisconnect();
});
</script>

<template>
  <div
    class="app-container"
    :class="{ 'is-mobile': authStore.isNarrowDevice }"
  >
    <NotificationBar />
    <NavBar
      v-if="
        authStore.currentPath !== 'embed' &&
          authStore.currentPath !== 'mapview'
      "
    />
    
    <!-- Content wrapper -->
    <div class="app-viewport">
      <!-- /mapview standalone fullscreen layout -->
      <div
        v-if="authStore.currentPath === 'mapview'"
        class="app-mapview-layout"
      >
        <RouterView />
      </div>

      <!-- /dashboard, /admin, /component layouts -->
      <div
        v-else-if="['dashboard', 'admin'].includes(authStore.currentPath) || authStore.currentPath.includes('component')"
        class="app-content"
      >
        <SideBar v-if="authStore.currentPath === 'dashboard'" />
        <AdminSideBar v-else-if="authStore.currentPath === 'admin'" />
        <ComponentSideBar v-else-if="authStore.currentPath.includes('component')" />

        <div class="app-content-main">
          <SettingsBar v-if="authStore.currentPath === 'dashboard'" />
          <div
            class="app-content-body"
            :class="{ 'app-content-body--flush': authStore.currentPath === 'ai-studio' }"
          >
            <RouterView />
          </div>
        </div>
      </div>

      <!-- AI Studio layout -->
      <div
        v-else-if="authStore.currentPath === 'ai-studio'"
        class="app-content"
      >
        <div class="app-content-main">
          <div class="app-content-body app-content-body--flush">
            <RouterView />
          </div>
        </div>
      </div>

      <div v-else>
        <router-view />
      </div>
    </div>

    <!-- Bottom Nav for Mobile -->
    <nav 
      v-if="authStore.isNarrowDevice && authStore.currentPath !== 'embed'"
      class="app-bottom-nav"
    >
      <router-link
        v-for="item in filteredNavItems"
        :key="item.id"
        :to="item.path"
        class="app-bottom-nav-item"
        :class="{ 'is-active': isNavItemActive(item.id) }"
      >
        <span class="app-bottom-nav-icon">{{ item.icon }}</span>
        <span class="app-bottom-nav-label">{{ item.name }}</span>
      </router-link>
    </nav>

    <InitialWarning />
    <LogIn />
    <ChatWidgetMount v-if="shouldShowChatWidget" />
  </div>
</template>

<style scoped lang="scss">
.app {
	&-container {
		display: flex;
		flex-direction: column;
		width: 100vw;
		height: 100vh;
		height: calc(var(--vh) * 100);
		overflow: hidden;
		background-color: var(--color-background);
	}

	&-viewport {
		flex: 1;
		display: flex;
		flex-direction: column;
		min-height: 0;
		overflow: hidden;
	}

	&-mapview-layout {
		width: 100%;
		height: 100%;
	}

	&-content {
		flex: 1;
		display: flex;
		min-height: 0;
		width: 100%;

		&-main {
			flex: 1;
			display: flex;
			flex-direction: column;
			min-width: 0;
			height: 100%;
		}

		&-body {
			flex: 1;
			overflow-y: auto;
			overflow-x: hidden;
			-webkit-overflow-scrolling: touch;
			padding-bottom: 2rem;

			&--flush {
				padding: 0;
			}
		}
	}

  /* Integrated Bottom Nav Styles */
  &-bottom-nav {
    position: fixed;
    bottom: 0;
    left: 0;
    width: 100%;
    height: 70px;
    background-color: var(--color-component-background);
    border-top: 1px solid var(--color-border);
    display: flex;
    justify-content: space-around;
    align-items: center;
    z-index: 100;
    padding-bottom: env(safe-area-inset-bottom);
    box-shadow: 0 -4px 12px rgba(0, 0, 0, 0.2);

    &-item {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: var(--color-complement-text);
      text-decoration: none;
      flex: 1;
      height: 100%;
      transition: var(--transition-fast);

      &.is-active {
        color: var(--color-highlight);
        
        .app-bottom-nav-icon {
          transform: translateY(-2px);
        }
      }
    }

    &-icon {
      font-family: var(--font-icon);
      font-size: 24px;
      margin-bottom: 4px;
      transition: transform 0.2s ease;
    }

    &-label {
      font-size: var(--font-xs);
      font-weight: 500;
    }
  }
}

/* Mobile specific overrides */
.is-mobile {
	.app-content-body {
		padding-bottom: 80px; /* Extra padding for bottom nav */
	}
}
</style>
