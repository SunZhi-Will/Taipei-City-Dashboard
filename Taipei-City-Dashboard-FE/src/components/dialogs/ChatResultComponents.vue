<script setup>
import { computed } from "vue";
import DashboardComponent from "../../dashboardComponent/DashboardComponent.vue";
import { useContentStore } from "../../store/contentStore";

const props = defineProps({
	components: {
		type: Array,
		default: () => [],
	},
	selectionReason: {
		type: String,
		default: '',
	},
});
const emit = defineEmits(["copy", "explore"]);
const contentStore = useContentStore();

const normalizedComponents = computed(() =>
	Array.isArray(props.components) ? props.components : [],
);

const primaryComponent = computed(() =>
	normalizedComponents.value.find((item) => item?.isPrimary) || normalizedComponents.value[0] || null,
);

const secondaryComponents = computed(() =>
	normalizedComponents.value.filter((item) => item && item !== primaryComponent.value),
);

const isDashboardPreview = (comp) =>
	comp?.category === "dashboard_component" && comp?.dashboardConfig;

const cityTags = (config) => {
	if (!config?.city) return [];
	return contentStore.cityManager.getTagList(config.city);
};

const onExplore = (comp) => {
	if (!comp?.name) return;
	emit("explore", comp.name);
};
</script>

<template>
	<div class="component-cards-area">
		<div
			v-if="primaryComponent"
			:key="`${primaryComponent.id}-${primaryComponent.index || primaryComponent.name}`"
			class="component-card"
		>
			<div v-if="isDashboardPreview(primaryComponent)" class="dashboard-focus-card">
				<DashboardComponent
					:config="primaryComponent.dashboardConfig"
					mode="large"
					:show-index="false"
					:city-tag="cityTags(primaryComponent.dashboardConfig)"
					:info-btn="false"
					:add-btn="false"
					:favorite-btn="false"
					:footer="false"
					:fullscreen-btn="false"
				/>
			</div>

			<div v-else class="generic-card generic-card-primary">
				<div class="component-header">
					<h4 class="component-name">{{ primaryComponent.name }}</h4>
				</div>
				<div class="component-body">
					<p class="component-description">{{ primaryComponent.description }}</p>
				</div>
			</div>
		</div>

		<div v-if="secondaryComponents.length > 0" class="secondary-section">
			<p class="secondary-title">也可以延伸查看這些相關指標：</p>
			<div class="secondary-links">
				<button
					v-for="comp in secondaryComponents"
					:key="`${comp.id}-${comp.index || comp.name}`"
					type="button"
					class="secondary-link"
					:title="`查看 ${comp.name}`"
					@click="onExplore(comp)"
				>
					<span class="secondary-link-name">{{ comp.name }}</span>
				</button>
			</div>
		</div>
	</div>
</template>

<style scoped lang="scss">
.component-cards-area {
	margin: 12px 0;
	display: flex;
	flex-direction: column;
	gap: 14px;
}

.component-card {
	border-radius: 10px;
	overflow: hidden;
}

.dashboard-focus-card {
	background: rgba(255, 255, 255, 0.03);
	border: 1px solid rgba(255, 255, 255, 0.12);
	border-radius: 10px;
	padding: 8px;
}

.generic-card {
	border: 1px solid rgba(255, 255, 255, 0.14);
	border-radius: 10px;
	padding: 14px;
	background: rgba(255, 255, 255, 0.04);
}

.generic-card-primary {
	background: rgba(255, 255, 255, 0.06);
	border-color: rgba(255, 255, 255, 0.18);
}

.component-header {
	display: flex;
	align-items: center;
	margin-bottom: 8px;
	padding-bottom: 6px;
}

.component-name {
	font-size: 16px;
	font-weight: 600;
	color: #f0f3f8;
	margin: 0;
}

.component-body {
	display: flex;
	flex-direction: column;
	gap: 8px;
}

.component-description {
	font-size: 14px;
	color: #c8d0db;
	line-height: 1.5;
	margin: 0;
}

.secondary-section {
	display: flex;
	flex-direction: column;
	gap: 10px;
}

.secondary-title {
	margin: 0;
	font-size: 13px;
	line-height: 1.5;
	color: #d7dde6;
}

.secondary-links {
	display: flex;
	flex-direction: column;
	gap: 10px;
	align-items: flex-start;
}

.secondary-link {
	padding: 0;
	border: none;
	background: transparent;
	display: inline-flex;
	flex-direction: column;
	align-items: flex-start;
	gap: 4px;
	cursor: pointer;
	text-align: left;
	width: fit-content;
}


.secondary-link-name {
	margin: 0;
	font-size: 14px;
	line-height: 1.4;
	font-weight: 600;
	color: #cfe4ff;
	text-decoration: underline;
	text-underline-offset: 3px;
	text-decoration-thickness: 1px;
	transition: color 0.2s ease;
}

.secondary-link:hover .secondary-link-name {
	color: #ffffff;
}
</style>
