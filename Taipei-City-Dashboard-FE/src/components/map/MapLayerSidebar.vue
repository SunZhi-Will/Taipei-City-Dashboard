<!-- Map Layer Sidebar Component -->
<!-- Handles dashboard and component selection for map layers -->

<script setup>
import { ref, watch } from "vue";
import MapLayerSidebarContent from "./MapLayerSidebarContent.vue";

const props = defineProps({
	isCollapsed: Boolean,
});

const emit = defineEmits(["update:isCollapsed", "switch-dashboard"]);

const islandCollapsed = ref(props.isCollapsed);
function switchDashboard(scope, dashboard, city) {
	emit("switch-dashboard", { scope, dashboard, city });
}

watch(
	() => props.isCollapsed,
	(newVal) => {
		islandCollapsed.value = newVal;
	},
);

watch(islandCollapsed, (newVal) => {
	emit("update:isCollapsed", newVal);
});

</script>

<template>
  <div class="map-island-shell hide-if-mobile">
    <aside
      class="map-island"
      :class="{ 'map-island-collapsed': islandCollapsed }"
    >
			<MapLayerSidebarContent @switch-dashboard="switchDashboard" />
    </aside>

    <button
      class="map-island-toggle"
      :class="{ 'map-island-toggle-collapsed': islandCollapsed }"
      type="button"
      @click="islandCollapsed = !islandCollapsed"
    >
      <span>{{ islandCollapsed ? 'chevron_right' : 'chevron_left' }}</span>
    </button>
  </div>
</template>

<style scoped lang="scss">
.map-island-shell {
	position: absolute;
	top: 68px;
	left: 12px;
	z-index: 20;
	overflow: visible;
}

.map-island {
	width: 260px;
	max-height: calc(100vh - 80px);
	display: flex;
	flex-direction: column;
	background: rgba(12, 16, 19, 0.82);
	backdrop-filter: blur(12px);
	border: 1px solid rgba(255, 255, 255, 0.16);
	border-radius: 22px;
	overflow: hidden;
	transform: translateX(0);
	transition: transform 0.22s ease, opacity 0.22s ease;

	&-collapsed {
		transform: translateX(calc(-100% - 18px));
		opacity: 0.4;
		pointer-events: none;
	}
}

.map-island-toggle {
	position: absolute;
	top: 18px;
	left: 242px;
	width: 36px;
	height: 36px;
	padding: 0;
	border: 1px solid rgba(255, 255, 255, 0.16);
	border-radius: 50%;
	background: rgba(12, 16, 19, 0.92);
	backdrop-filter: blur(12px);
	color: #dce1e8;
	cursor: pointer;
	display: flex;
	align-items: center;
	justify-content: center;
	box-shadow: 0 10px 24px rgba(0, 0, 0, 0.22);
	transition: left 0.18s ease, background 0.2s ease, border-color 0.2s ease;

	span {
		font-family: var(--font-icon);
		font-size: 0.95rem;
	}

	&:hover {
		background: rgba(20, 26, 32, 0.98);
		border-color: rgba(255, 255, 255, 0.24);
	}

	&-collapsed {
		left: 0;
	}
}
</style>
