<!-- Developed by Taipei Urban Intelligence Center 2023-2024-->

<!-- Navigation will be hidden from the navbar in mobile mode and moved to the settingsbar -->

<script setup>
const { VITE_APP_TITLE } = import.meta.env;
import { computed, ref } from "vue";
import { useRoute } from "vue-router";
import { useFullscreen } from "@vueuse/core";
import { useAuthStore } from "../../../store/authStore";
import { useDialogStore } from "../../../store/dialogStore";
import { useContentStore } from "../../../store/contentStore";

import UserSettings from "../../dialogs/UserSettings.vue";
import ContributorsList from "../../dialogs/ContributorsList.vue";
import MobileDashboardSwitcher from "../../dialogs/MobileDashboardSwitcher.vue";

const route = useRoute();
const authStore = useAuthStore();
const contentStore = useContentStore();
const dialogStore = useDialogStore();
const { isFullscreen, toggle } = useFullscreen();

const isDropdownOpen = ref(false);

const toggleDropdown = (state) => {
  if (!(authStore.isMobileDevice && authStore.isNarrowDevice)) {
    isDropdownOpen.value = false;
    return;
  }

  if (state !== undefined) {
    isDropdownOpen.value = state;
  } else {
    isDropdownOpen.value = !isDropdownOpen.value;
  }
};

const linkQuery = computed(() => {
	const { query } = route;
	const indexQuery = `?index=${query.index}`;
	const cityQuery = query.city ? `&city=${query.city}` : '';
	return `${indexQuery}${cityQuery}`;
});

const location = computed(() => {
	return window.location;
});

const isLocalhost = computed(() => {
	return window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1';
});
</script>

<template>
  <div class="navbar">
    <div class="navbar-logo">
      <a
        href="/"
        class="navbar-logo-link"
      >
        <div class="navbar-logo-image">
          <img
            src="../../../assets/images/TUIC.svg"
            alt="tuic logo"
          >
        </div>
        <div class="navbar-logo-text">
          <h1>{{ VITE_APP_TITLE }}</h1>
          <h2>Taipei City Dashboard</h2>
        </div>
      </a>
      <div class="navbar-logo-titles">
        <span class="navbar-theme-separator">/</span>
        <div
          class="navbar-theme-name"
          :class="{ 'navbar-theme-name--active': isDropdownOpen }"
          @click.stop="toggleDropdown()"
        >
          <span class="navbar-theme-icon material-icons-round">{{ contentStore.currentDashboard.icon }}</span>
          <span class="navbar-theme-text">{{ contentStore.currentDashboard.name }}</span>
          <span
            v-if="authStore.isNarrowDevice"
            class="navbar-theme-arrow material-icons-round"
          >arrow_drop_down_circle</span>
          
          <!-- Immersive Mobile Menu Overlay (Extracted) -->
          <MobileDashboardSwitcher 
            v-if="authStore.isMobileDevice && authStore.isNarrowDevice"
            :is-open="isDropdownOpen"
            @close="toggleDropdown(false)"
          />
        </div>
      </div>
    </div>
    <div
      v-if="authStore.currentPath !== 'admin'"
      class="navbar-tabs"
    >
      <router-link
        v-if="authStore.token"
        :to="`/component`"
        :class="{
          'router-link-active':
            authStore.currentPath.includes('component'),
        }"
      >
        組件瀏覽平台
      </router-link>
      <router-link
        :to="`/dashboard${
          linkQuery.includes('undefined') ? '' : linkQuery
        }`"
      >
        儀表板總覽
      </router-link>
      <router-link
        :to="`/mapview${
          linkQuery.includes('undefined') ? '' : linkQuery
        }`"
      >
        地圖交叉比對
      </router-link>
      <router-link to="/ai-studio">
        AI Studio
      </router-link>
    </div>
    <div class="navbar-user">
      <button
        v-if="!(authStore.isMobileDevice && authStore.isNarrowDevice)"
        class="hide-if-mobile"
        @click="toggle"
      >
        <span>{{
          isFullscreen ? "fullscreen_exit" : "fullscreen"
        }}</span>
      </button>
      <div class="navbar-user-info">
        <button><span>info</span></button>
        <ul>
          <li>
            <a
              :href="isLocalhost ? 'https://citydashboard.taipei/documentation/' : `${location.origin}/documentation/`"
              target="_blank"
              rel="noreferrer"
            >技術文件</a>
          </li>
          <li>
            <button
              @click="dialogStore.showDialog('contributorsList')"
            >
              專案貢獻者
            </button>
          </li>
        </ul>
        <teleport to="body">
          <ContributorsList />
        </teleport>
      </div>
      <div
        v-if="
          authStore.token &&
            !(authStore.isMobileDevice && authStore.isNarrowDevice)
        "
        class="navbar-user-user"
      >
        <button>
          {{ authStore.user.name }}
        </button>
        <ul>
          <li>
            <button @click="dialogStore.showDialog('userSettings')">
              用戶設定
            </button>
          </li>
          <li
            v-if="
              authStore.currentPath !== 'admin' &&
                authStore.user.is_admin
            "
            class="hide-if-mobile"
          >
            <router-link to="/admin">
              管理員後臺
            </router-link>
          </li>
          <li
            v-else-if="authStore.user.is_admin"
            class="hide-if-mobile"
          >
            <router-link to="/dashboard">
              返回儀表板
            </router-link>
          </li>
          <li>
            <button @click="authStore.handleLogout">
              登出
            </button>
          </li>
        </ul>
        <teleport to="body">
          <user-settings />
        </teleport>
      </div>
      <div
        v-else-if="
          !(authStore.isMobileDevice && authStore.isNarrowDevice)
        "
        class="navbar-user-user"
      >
        <button @click="dialogStore.showDialog('login')">
          登入
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.navbar {
	height: 60px;
	width: 100vw;
	display: flex;
	justify-content: space-between;
	align-items: center;
	border-bottom: 1px solid var(--color-border);
	background-color: var(--color-component-background);
	user-select: none;
	position: relative;
	z-index: 2001;
	overflow: visible;

    &-logo {
      display: flex;
      align-items: center;
      height: 100%;

      &-link {
        display: flex;
        align-items: center;
        height: 100%;
        text-decoration: none;
        transition: opacity 0.2s;

        &:hover {
          opacity: 0.8;
        }
      }

      &-text {
        display: flex;
        flex-direction: column;
        justify-content: center;
        height: 100%;
      }

      h1 {
        font-weight: 500;
        font-size: 1.15rem;
        line-height: 1.1;
        margin: 0;
        
        @media screen and (max-width: 500px) {
          display: none;
        }
      }

      h2 {
        font-size: 0.7rem;
        font-weight: 400;
        color: var(--color-complement-text);
        line-height: 1;
        margin: 0;

        @media screen and (max-width: 500px) {
          display: none;
        }
      }

      &-image {
        width: 22.94px;
        height: 45px;
        margin: 0 var(--font-m);
        display: flex;
        align-items: center;

        img {
          height: 45px;
          filter: invert(1);
        }
      }

      &-titles {
        display: flex;
        align-items: center;
        height: 100%;
        gap: 4px;
      }

      &-theme-separator {
        margin: 0 8px;
        opacity: 0.5;
        font-weight: 300;
        display: flex;
        align-items: center;
        height: 100%;

        @media screen and (max-width: 768px) {
          display: none;
        }
      }

      &-theme-name {
        display: flex;
        align-items: center;
        height: 100%;
        gap: 6px;
        font-size: var(--font-s);
        font-weight: 500;
        color: var(--color-highlight);
        line-height: 1;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        max-width: 200px;
        cursor: pointer;
        
        &:active {
          opacity: 0.7;
        }

        @media screen and (max-width: 768px) {
          max-width: 160px;
          background: rgba(255, 255, 255, 0.08);
          padding: 6px 10px;
          border-radius: 8px;
          min-height: 36px;
          height: auto; /* Reset height on mobile to keep the button shape */
        }

        @media screen and (max-width: 480px) {
          max-width: 120px;
          font-size: 0.85rem;
        }
      }

      &-theme-icon {
        font-size: calc(var(--font-m) * var(--font-to-icon));
        display: flex;
        align-items: center;
      }

      &-theme-arrow {
        font-size: 18px;
        color: var(--color-highlight);
        margin-left: 2px;
        transition: transform 0.3s ease;
        display: flex;
        align-items: center;
      }

      &-name--active {
        .navbar-theme-arrow {
          transform: rotate(180deg);
        }
      }
    }

    &-tabs {
      display: flex;
      align-items: center;
      gap: 12px;
      position: absolute;
      left: 50%;
      transform: translateX(-50%);
      pointer-events: auto;

      a {
        padding: 8px 20px;
        display: flex;
        align-items: center;
        background: transparent;
        color: var(--color-complement-text);
        text-decoration: none;
        font-size: var(--font-ms);
        font-weight: 500;
        border-radius: 999px;
        white-space: nowrap;
        transition: background 0.2s ease, color 0.2s ease;

        &:hover {
          background: rgba(255, 255, 255, 0.08);
          color: var(--color-text);
        }
      }

      .router-link-active {
        background: rgba(255, 255, 255, 0.16);
        color: #ffffff;
        font-weight: 600;
        box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.2);

        &:hover {
          background: rgba(255, 255, 255, 0.16);
        }
      }

      /* AI Studio 特殊樣式 */
      a[href*="ai-studio"],
      a[href="/ai-studio"] {
        &:not(.router-link-active) {
          color: #c4b5fd;

          &:hover {
            background: rgba(139, 92, 246, 0.18);
            color: #ddd6fe;
          }
        }

        &.router-link-active {
          background: rgba(124, 58, 237, 0.45);
          color: #ede9fe;
          box-shadow: inset 0 0 0 1px rgba(139, 92, 246, 0.5);
        }
      }

      @media screen and (max-width: 900px) {
        display: none;
      }
    }

    &-user {
      display: flex;
      align-items: center;

      li a,
      button {
        display: flex;
        align-items: center;
        margin-right: var(--font-m);
        padding: 2px 4px;
        border-radius: 4px;
        font-size: var(--font-m);
        transition: background-color 0.25s;
      }

      span {
        font-family: var(--font-icon);
        font-size: calc(var(--font-l) * var(--font-to-icon));
      }

      &-user:hover ul,
      &-info:hover ul {
        display: block;
        opacity: 1;
      }

      &-user,
      &-info {
        height: 60px;
        min-width: 100px;
        display: flex;
        align-items: center;
        justify-content: center;

        @media screen and (max-width: 750px) {
          display: none;
        }
        @media screen and (max-height: 500px) {
          display: none;
        }

        ul {
          min-width: 100px;
          display: none;
          position: absolute;
          right: 20px;
          top: 55px;
          padding: 8px;
          margin: 0;
          list-style: none;
          border-radius: 5px;
          background-color: rgb(85, 85, 85);
          opacity: 0;
          transition: opacity 0.25s;
          z-index: 10;

          li {
            list-style: none;
            border-radius: 5px;
            transition: background-color 0.25s;

            a,
            button {
              padding: 8px 6px;
              width: 100%;
              height: 100%;
            }
          }

          li:hover {
            background-color: var(--color-complement-text);
          }
        }
      }

      &-info {
        min-width: 0;

        ul {
          right: 120px;
          top: 55px;
        }

        @media screen and (max-width: 750px) {
          display: flex;

          ul {
            right: 20px;
            top: 55px;
          }
        }
        @media screen and (max-height: 500px) {
          display: flex;
        }
      }
    }
}
</style>
