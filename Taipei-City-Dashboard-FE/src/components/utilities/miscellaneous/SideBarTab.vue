<!-- Developed by Taipei Urban Intelligence Center 2023-2024-->

<!-- This component has two modes "expanded" and "collapsed" which is controlled by the prop "expanded" -->

<script setup>
/* global gtag */
import { computed } from "vue";
import { useRoute } from "vue-router";
import { useAuthStore } from "../../../store/authStore";

const route = useRoute();

const props = defineProps({
	icon: { type: String },
	title: { type: String },
	index: { type: String },
	city: { type: String },
	expanded: { type: Boolean },
	level: { type: Number, default: 2 },
});

const authStore = useAuthStore();

const tabLink = computed(() => {
	const isAdminPath = authStore.currentPath === "admin";
	const cityParam = props.city ? `${isAdminPath ? "?" : "&"}city=${props.city}` : "";
	return isAdminPath
		? `/admin/${props.index}${cityParam}`
		: `${route.path}?index=${props.index}${cityParam}`;
});

const linkActiveOrNot = computed(() => {
	const isAdminPath = authStore.currentPath === "admin";
	const isPathMatch = isAdminPath
		? route.path === `/admin/${props.index}`
		: route.query.index === props.index;
	const isCityMatch = props.city
		? route.query.city === props.city
		: true;

	return isPathMatch && isCityMatch;
});

// 點擊側欄儀表板主題時觸發GA自訂事件
const popularThemeGA = (title) => {
	if (props.city && title) {
		gtag('event','popular_theme', {
			dashboard_city:props.city,
			theme_name:title,
			city_theme:`${props.city}-${title}`
  		})
	}
};

</script>

<template>
  <router-link
    :to="tabLink"
    :class="[
      'sidebartab',
      `sidebartab-level-${level}`,
      { 'sidebartab-collapsed': !expanded },
      { 'sidebartab-active': linkActiveOrNot },
    ]"
    :title="!expanded ? title : ''"
    :aria-current="linkActiveOrNot ? 'page' : undefined"
    @click="popularThemeGA(title)"
  >
    <span class="sidebartab-icon">{{ icon }}</span>
    <h3 class="sidebartab-label">
      {{ title }}
    </h3>
  </router-link>
</template>

<style scoped lang="scss">
.sidebartab {
	display: flex;
	align-items: center;
	height: 2.25rem;
	margin: 2px 8px;
	padding: 0 10px;
	border-radius: 999px;
	transition: background-color 0.2s ease, color 0.2s ease, padding 0.32s cubic-bezier(0.4, 0, 0.2, 1), margin 0.24s ease;
	white-space: nowrap;
	text-wrap: nowrap;
	text-decoration: none;
	color: var(--color-normal-text);

	&:hover {
		background-color: var(--color-sidebar-item-hover-bg);
	}

	&-icon {
		width: 17px;
		height: 17px;
		min-width: 17px;
		flex-shrink: 0;
		margin-right: 8px;
		margin-left: 0;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		font-family: var(--font-icon);
		font-size: 17px;
		transition: margin-left 0.32s cubic-bezier(0.4, 0, 0.2, 1), margin-right 0.32s cubic-bezier(0.4, 0, 0.2, 1);
	}

	&-label {
		font-size: var(--font-m);
		font-weight: 400;
		overflow: hidden;
		text-overflow: ellipsis;
		max-width: 13.5rem;
		opacity: 1;
		white-space: nowrap;
		clip-path: inset(0 0 0 0);
		transition: max-width 0.32s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.2s ease, clip-path 0.32s cubic-bezier(0.4, 0, 0.2, 1);
	}

	&-collapsed {
		justify-content: flex-start;
		padding-left: 0;
		padding-right: 0;
		margin: 2px 8px;

		.sidebartab-icon {
			margin-left: calc((3.5rem - 12px - 17px) / 2);
			margin-right: 0;
		}

		.sidebartab-label {
			max-width: 0;
			opacity: 0.35;
			margin: 0;
			clip-path: inset(0 100% 0 0);
		}
	}

	&-active {
		background-color: var(--color-sidebar-item-active-bg);
		box-shadow: inset 0 0 0 1px var(--color-sidebar-item-active-border);

		.sidebartab-icon,
		.sidebartab-label {
			color: var(--color-highlight);
		}
	}

	&-level-2 {
		padding-left: 10px;
	}

	&-level-3 {
		padding-left: 14px;
	}
}
</style>
