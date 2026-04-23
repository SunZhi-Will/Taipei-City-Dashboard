import { computed, ref, watch } from "vue";
import { useRoute } from "vue-router";
import { useAuthStore } from "../../../store/authStore";
import { useContentStore } from "../../../store/contentStore";
import { useDialogStore } from "../../../store/dialogStore";
import { useMapStore } from "../../../store/mapStore";
import http from "../../../router/axios";

export function useMapLayerSidebarContent(emit) {
	const authStore = useAuthStore();
	const contentStore = useContentStore();
	const dialogStore = useDialogStore();
	const mapStore = useMapStore();
	const route = useRoute();

	const privateCollapsed = ref(false);
	const publicCollapsed = ref(false);
	const favoriteCollapsed = ref(false);
	const personalCollapsed = ref(false);
	const selectedPublicCity = ref("taipei");

	const expandedDashboardMap = ref({});
	const loadingDashboardKey = ref("");
	const dashboardComponentsCache = ref({});
	const componentToggles = ref({});
	const activatedOpenComponentId = ref(null);
	const queuedOpenComponentId = ref(null);

	const favoriteDashboard = computed(() => {
		return contentStore.favorites?.index ? contentStore.favorites : null;
	});

	const favoriteDashboards = computed(() => {
		return favoriteDashboard.value ? [favoriteDashboard.value] : [];
	});

	const personalDashboards = computed(() => {
		return contentStore.personalDashboards.filter(
			(item) => item.icon !== "favorite",
		);
	});

	const publicCityOptions = computed(() => {
		return ["taipei", "metrotaipei"].filter((city) =>
			contentStore.cityManager.isCityEnabled(city),
		);
	});

	const publicDashboards = computed(() => {
		return contentStore.getDashboardsByCity(selectedPublicCity.value);
	});

	function buildDashboardKey(scope, index, city) {
		return `${scope}:${city || "private"}:${index}`;
	}

	function componentKey(dashboard, city, component) {
		return `${dashboard.index}:${city || component.city || "na"}:${component.id}`;
	}

	function hasMapConfig(component) {
		return (
			Array.isArray(component?.map_config) &&
			component.map_config.length > 0 &&
			Boolean(component.map_config[0])
		);
	}

	function isComponentVisible(component) {
		if (!hasMapConfig(component)) return false;
		return component.map_config.some((item) =>
			mapStore.currentVisibleLayers.includes(
				`${item.index}-${item.type}-${item.city}`,
			),
		);
	}

	function findOpenComponentById(openComponentId) {
		const targetId = String(openComponentId);
		const current = (contentStore.currentDashboard.components || []).find(
			(item) => String(item.id) === targetId,
		);
		if (current) return current;

		const mapLayer = (contentStore.mapLayers || []).find(
			(item) => String(item.id) === targetId,
		);
		if (mapLayer) return mapLayer;

		const dashboardIndex = String(route.query.index || "");
		const cached = (dashboardComponentsCache.value[dashboardIndex] || []).find(
			(item) => String(item.id) === targetId,
		);
		return cached || null;
	}

	function activateOpenComponent(component, openComponentId) {
		const targetId = String(openComponentId);
		if (
			activatedOpenComponentId.value === targetId &&
			isComponentVisible(component)
		) {
			return;
		}

		const applyActivation = () => {
			if (
				activatedOpenComponentId.value === targetId &&
				isComponentVisible(component)
			) {
				return;
			}
			mapStore.addToMapLayerList(component.map_config);
			const key = componentKey(
				{ index: contentStore.currentDashboard.index },
				contentStore.currentDashboard.city,
				component,
			);
			componentToggles.value[key] = true;
			activatedOpenComponentId.value = targetId;
			queuedOpenComponentId.value = null;
		};

		const {map} = mapStore;
		if (!map) return;

		if (map.isStyleLoaded?.()) {
			applyActivation();
			return;
		}

		if (queuedOpenComponentId.value === targetId) return;
		queuedOpenComponentId.value = targetId;
		map.once("load", applyActivation);
	}

	function getUniquePrivateComponents(components) {
		const sortedData = [...components].sort((a, b) => {
			if (a.id !== b.id) return 0;
			if (a.city === "taipei" && b.city !== "taipei") return -1;
			if (a.city !== "taipei" && b.city === "taipei") return 1;
			return 0;
		});

		return [...new Map(sortedData.map((item) => [item.id, item])).values()];
	}

	function getDashboardComponents(dashboard, city) {
		const raw = dashboardComponentsCache.value[dashboard.index] || [];
		if (city) {
			return raw.filter((item) => item.city === city);
		}
		return getUniquePrivateComponents(raw);
	}

	async function ensureDashboardComponents(dashboardIndex) {
		if (dashboardComponentsCache.value[dashboardIndex]) return;

		loadingDashboardKey.value = dashboardIndex;
		try {
			const response = await http.get(`/dashboard/${dashboardIndex}`);
			dashboardComponentsCache.value[dashboardIndex] = response.data.data || [];
		} catch (error) {
			console.error("Failed to load dashboard components", error);
			dialogStore.showNotification("error", "讀取儀表板組件失敗");
		} finally {
			loadingDashboardKey.value = "";
		}
	}

	async function toggleDashboardExpand(scope, dashboard, city) {
		const key = buildDashboardKey(scope, dashboard.index, city);
		const next = !expandedDashboardMap.value[key];
		expandedDashboardMap.value[key] = next;
		if (next) {
			await ensureDashboardComponents(dashboard.index);
		}
	}

	function switchDashboard(scope, dashboard, city) {
		emit("switch-dashboard", { scope, dashboard, city });
	}

	async function handleDashboardRowClick({ scope, dashboard, city }) {
		await toggleDashboardExpand(scope, dashboard, city);
	}

	function handleComponentSyncToggle({ checked, dashboard, city, component }) {
		const key = componentKey(dashboard, city, component);

		if (!hasMapConfig(component)) {
			if (checked) {
				dialogStore.showNotification("info", "本組件沒有空間資料，不會渲染地圖");
			}
			componentToggles.value[key] = false;
			return;
		}

		if (checked) {
			mapStore.addToMapLayerList(component.map_config);
		} else {
			mapStore.clearByParamFilter(component.map_config);
			mapStore.turnOffMapLayerVisibility(component.map_config);
		}

		componentToggles.value[key] = checked;
	}

	watch(
		() => publicCityOptions.value,
		(cities) => {
			if (!cities.includes(selectedPublicCity.value) && cities.length > 0) {
				selectedPublicCity.value = cities[0];
			}
		},
		{ immediate: true },
	);

	watch(
		() => route.query.city,
		(city) => {
			if (city && publicCityOptions.value.includes(city)) {
				selectedPublicCity.value = city;
			}
		},
		{ immediate: true },
	);

	watch(
		() => [route.query.index, route.query.city],
		([index, city]) => {
			if (!index) return;

			const scope = city ? "public" : "private";
			const key = buildDashboardKey(scope, index, city);
			expandedDashboardMap.value[key] = true;
			ensureDashboardComponents(index);
		},
		{ immediate: true },
	);

	watch(
		() => [
			route.query.openComponentId,
			route.query.openTrigger,
			contentStore.currentDashboard.index,
			contentStore.currentDashboard.city,
			contentStore.currentDashboard.components?.length || 0,
			contentStore.mapLayers?.length || 0,
			Boolean(mapStore.map),
		],
		([openComponentId]) => {
			if (!openComponentId) return;

			const component = findOpenComponentById(openComponentId);

			if (!component || !hasMapConfig(component)) return;

			activateOpenComponent(component, openComponentId);
		},
		{ immediate: true },
	);

	return {
		authStore,
		contentStore,
		privateCollapsed,
		publicCollapsed,
		favoriteCollapsed,
		personalCollapsed,
		selectedPublicCity,
		expandedDashboardMap,
		loadingDashboardKey,
		componentToggles,
		favoriteDashboards,
		personalDashboards,
		publicCityOptions,
		publicDashboards,
		buildDashboardKey,
		componentKey,
		hasMapConfig,
		getDashboardComponents,
		handleDashboardRowClick,
		handleComponentSyncToggle,
	};
}