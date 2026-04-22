<!-- Developed by Taipei Urban Intelligence Center 2023-2024-->

<script setup>
import { onMounted, ref } from "vue";
import { useMapStore } from "../../../store/mapStore";
import { useContentStore } from "../../../store/contentStore";

import SideBarTab from "../miscellaneous/SideBarTab.vue";

const mapStore = useMapStore();
const contentStore = useContentStore();

// The expanded state is also stored in localstorage to retain the setting after refresh
const isExpanded = ref(true);

function toggleExpand() {
	isExpanded.value = isExpanded.value ? false : true;
	localStorage.setItem("isExpandedAdmin", isExpanded.value);
	mapStore.resizeMap();
}

onMounted(() => {
	const storedExpandedState = localStorage.getItem("isExpandedAdmin");
	if (storedExpandedState === "false") {
		isExpanded.value = false;
	} else {
		isExpanded.value = true;
	}
});
</script>

<template>
  <div
    :class="{
      adminsidebar: true,
      'adminsidebar-collapse': !isExpanded,
    }"
  >
    <button
      class="adminsidebar-collapse-button"
      @click="toggleExpand"
    >
      <span>{{
        isExpanded
          ? "keyboard_double_arrow_left"
          : "keyboard_double_arrow_right"
      }}</span>
    </button>
		<div class="adminsidebar-content">
    <h2>{{ isExpanded ? `儀表板設定` : `表板` }}</h2>
    <template
      v-for="city in contentStore.cityManager.activeCities"
      :key="city"
    >
      <SideBarTab
        icon="dashboard"
        :title="`${contentStore.cityManager.getExpandedNameName(city)}`"
        index="dashboard"
        :expanded="isExpanded"
        :city="city"
      />
    </template>
    <h2>{{ isExpanded ? `組件設定` : `組件` }}</h2>
    <SideBarTab
      icon="edit_note"
      title="編輯公開組件"
      :expanded="isExpanded"
      index="edit-component"
    />
    <h2>{{ isExpanded ? `問題回報` : `問題` }}</h2>
    <SideBarTab
      icon="bug_report"
      title="待回覆問題"
      :expanded="isExpanded"
      index="issue"
    />
    <SideBarTab
      icon="flood"
      title="民眾災害通報"
      :expanded="isExpanded"
      index="disaster"
    />
    <h2>{{ isExpanded ? `系統總覽` : `系統` }}</h2>
    <SideBarTab
      icon="person"
      title="使用者資訊"
      :expanded="isExpanded"
      index="user"
    />
    <SideBarTab
      icon="handshake"
      title="貢獻者資訊"
      :expanded="isExpanded"
      index="contributor"
    />
    <h2>{{ isExpanded ? `AI 監控` : `AI` }}</h2>
    <SideBarTab
      icon="query_stats"
      title="AI 問答統計"
      :expanded="isExpanded"
      index="ai-stats"
    />
		</div>
  </div>
</template>

<style scoped lang="scss">
.adminsidebar {
	width: 180px;
	min-width: 180px;
	height: calc(100vh - 80px);
	height: calc(var(--vh) * 100 - 80px);
	max-height: calc(100vh - 80px);
	max-height: calc(var(--vh) * 100 - 80px);
	position: relative;
	z-index: 15;
	margin-top: 20px;
	padding: 0 10px 0 var(--font-m);
	border-right: 1px solid var(--color-border);
	transition: min-width 0.2s ease-out;
	overflow: visible;
	user-select: none;

	&-content {
		height: 100%;
		overflow-y: scroll;
		overflow-x: hidden;
	}

	h2 {
		color: var(--color-complement-text);
		font-weight: 400;
		cursor: pointer;
		margin-left: 8px;
		padding: 4px 8px;
		border-radius: 4px;
		transition: all 0.2s ease;

		&:hover {
			background-color: var(--color-component-background);
			color: var(--color-highlight);
		}
	}

	&-sub {
		margin-bottom: var(--font-s);

		&-add {
			width: 100%;
			display: flex;

			button {
				display: flex;
				align-items: center;
				margin-left: 0.5rem;
				padding: 2px 6px;
				border-radius: 5px;
				background-color: var(--color-highlight);
				color: var(--color-normal-text);

				span {
					margin-right: 4px;
					font-family: var(--font-icon);
				}
			}
		}
	}

	&-collapse {
		width: 45px;
		min-width: 45px;
		transition: width 0.3s ease;

		h2 {
			margin-left: 2px;
			padding: 4px 2px;
		}

		&-button {
			position: absolute;
			top: 14px;
			right: -18px;
			display: flex;
			align-items: center;
			justify-content: center;
			width: 28px;
			height: 28px;
			background-color: var(--color-highlight);
			border: 2px solid var(--color-background);
			border-radius: 50%;
			font-size: var(--font-ms);
			transition: transform 0.2s ease, box-shadow 0.2s ease;
			z-index: 10;
			box-shadow: 0 2px 6px rgba(0, 0, 0, 0.2);

			&:hover {
				transform: scale(1.08);
				box-shadow: 0 4px 10px rgba(0, 0, 0, 0.24);
			}

			span {
				font-family: var(--font-icon);
				font-size: var(--font-m);
				color: #fff;
			}
		}
	}
}
</style>
