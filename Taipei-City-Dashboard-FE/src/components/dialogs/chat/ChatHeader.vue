<script setup>
import { useAuthStore } from "../../../store/authStore";
import { useDialogStore } from "../../../store/dialogStore";

const authStore = useAuthStore();
const dialogStore = useDialogStore();

const props = defineProps({
	showCloseButton: {
		type: Boolean,
		default: false,
	},
});

const emit = defineEmits(["clear", "expand", "close"]);
</script>

<template>
  <div class="header">
    <h3>臺北城市儀表板小幫手</h3>
    <div class="header-actions">
      <button
        v-if="authStore.user?.is_admin"
        type="button"
        class="action-btn trace-btn"
        title="檢視 AI 思考流程 (管理員)"
        @click="dialogStore.showDialog('aiTrace')"
      >
        <span class="material-icons-round">psychology</span>
      </button>
      <button
        type="button"
        class="action-btn clear-btn"
        title="清除歷史紀錄"
        aria-label="清除聊天歷史"
        @click="emit('clear')"
      >
        <svg
          viewBox="0 0 16 16"
          aria-hidden="true"
        >
          <path d="M2.5 1a1 1 0 0 0-1 1v1a1 1 0 0 0 1 1H3v9a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2V4h.5a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1H10a1 1 0 0 0-1-1H7a1 1 0 0 0-1 1zm3 4a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-1 0v-7a.5.5 0 0 1 .5-.5M8 5a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-1 0v-7A.5.5 0 0 1 8 5m3 .5v7a.5.5 0 0 1-1 0v-7a.5.5 0 0 1 1 0" />
        </svg>
      </button>
      <button
        type="button"
        class="action-btn expand-btn"
        title="展開為全屏"
        aria-label="展開聊天視窗為全屏"
        @click="emit('expand')"
      >
        <svg
          viewBox="0 0 16 16"
          aria-hidden="true"
        >
          <path d="M1.5 1a.5.5 0 0 0-.5.5v4a.5.5 0 0 1-1 0v-4A1.5 1.5 0 0 1 1.5 0h4a.5.5 0 0 1 0 1h-4zM10 .5a.5.5 0 0 1 .5-.5h4A1.5 1.5 0 0 1 16 1.5v4a.5.5 0 0 1-1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 1-.5-.5zM.5 10a.5.5 0 0 1 .5.5v4a.5.5 0 0 0 .5.5h4a.5.5 0 0 1 0 1h-4A1.5 1.5 0 0 1 0 14.5v-4a.5.5 0 0 1 .5-.5zm15 0a.5.5 0 0 1 .5.5v4a1.5 1.5 0 0 1-1.5 1.5h-4a.5.5 0 0 1 0-1h4a.5.5 0 0 0 .5-.5v-4a.5.5 0 0 1 .5-.5z" />
        </svg>
      </button>
      <button
        v-if="props.showCloseButton"
        class="action-btn close-btn"
        type="button"
        aria-label="關閉聊天視窗"
        @click="emit('close')"
      >
        <svg
          viewBox="0 0 16 16"
          aria-hidden="true"
        >
          <path d="M2.146 2.854a.5.5 0 1 1 .708-.708L8 7.293l5.146-5.147a.5.5 0 0 1 .708.708L8.707 8l5.147 5.146a.5.5 0 0 1-.708.708L8 8.707l-5.146 5.147a.5.5 0 0 1-.708-.708L7.293 8z" />
        </svg>
      </button>
    </div>
  </div>
</template>

<style scoped lang="scss">
$panel-bg: #0f1013;
$white: #ffffff;
$text-primary: #f4f4f5;
$radius-8: 8px;
$btn-size-sm: 36px;
$transition-fast: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);

.header {
	height: 3.5rem;
	padding: 0 1rem;
	background: $panel-bg;
	border-bottom: 1px solid rgba(255, 255, 255, 0.18);
	display: flex;
	align-items: center;
	justify-content: space-between;
	flex-shrink: 0;

	h3 {
		font-size: 0.875rem;
		font-weight: 600;
		color: $white;
		margin: 0;
	}

	.header-actions {
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}

	.action-btn {
		width: $btn-size-sm;
		height: $btn-size-sm;
		border-radius: $radius-8;
		border: none;
		background: transparent;
		color: $text-primary;
		font-size: 16px;
		line-height: 1;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: $transition-fast;

		&:hover {
			background: rgba($white, 0.16);
			color: $text-primary;
			transform: scale(1.05);
		}

		&:active {
			transform: scale(0.95);
		}
	}

	.clear-btn,
	.close-btn,
	.expand-btn,
	.trace-btn {
		svg {
			width: 16px;
			height: 16px;
			fill: currentColor;
		}
    span {
      font-size: 18px;
      line-height: 1;
    }
	}
}
</style>
