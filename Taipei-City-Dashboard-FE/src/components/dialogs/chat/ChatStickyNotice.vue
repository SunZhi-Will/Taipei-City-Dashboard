<script setup>
const props = defineProps({
	modelValue: {
		type: Boolean,
		default: false,
	},
});

const emit = defineEmits(["update:modelValue"]);

const toggle = () => {
	emit("update:modelValue", !props.modelValue);
};
</script>

<template>
  <div class="chat-message sticky-message">
    <div
      class="sticky-header"
      @click="toggle"
    >
      <span>置頂公告：小幫手使用須知</span>
      <button
        class="toggle-btn"
        type="button"
        :aria-expanded="modelValue"
        aria-label="切換置頂公告內容"
      >
        {{ modelValue ? "-" : "+" }}
      </button>
    </div>
    <div
      v-show="modelValue"
      class="sticky-body"
    >
      <span>
        小幫手目前支援 AI 對話與組件推薦兩種模式。預設會先嘗試 AI 對話，若服務繁忙會自動切換為組件推薦，協助您不中斷查詢。<br><br>
        若涉及即時資料或專業判讀，建議您搭配圖表與官方資料來源交叉確認。
      </span>
    </div>
  </div>
</template>

<style scoped lang="scss">
$card-bg: #252a2f;
$border-color: #353a41;
$text-primary: #f4f4f5;
$text-secondary: #d0d0d8;
$radius-8: 8px;
$radius-10: 10px;
$transition-fast: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
$white: #ffffff;

.chat-message {
	padding: 0;
	margin: 0;
	border-radius: 0;
	background: transparent;
}

.sticky-message {
	margin: 0 0 0.75rem;
	border: 1px solid $border-color;
	border-radius: $radius-10;
	background: $card-bg;
	position: sticky;
	top: 0;
	z-index: 10;
	box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
	transition: $transition-fast;

	.sticky-header {
		display: flex;
		font-weight: 600;
		font-size: 13px;
		color: $text-primary;
		justify-content: space-between;
		align-items: center;
		cursor: pointer;
		padding: 8px 12px;
		background: #1f2328;
		border-bottom: 1px solid $border-color;
		transition: $transition-fast;

		span {
			color: $text-primary;
		}

		&:hover {
			background: rgba($white, 0.05);
		}
	}

	.sticky-body {
		padding: 10px 12px;
		font-weight: 400;
		font-size: 14px;
		color: $text-secondary;
		line-height: 1.65;
		background: $card-bg;
		animation: slideDown 0.3s ease-out;

		span,
		p {
			color: $text-secondary;
		}
	}

	.toggle-btn {
		background: none;
		border: none;
		font-size: 14px;
		cursor: pointer;
		color: #808090;
		width: 24px;
		height: 24px;
		border-radius: $radius-8;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: $transition-fast;

		&:hover {
			background: rgba($white, 0.08);
			color: $text-primary;
		}
	}
}

@keyframes slideDown {
	from {
		opacity: 0;
		max-height: 0;
	}
	to {
		opacity: 1;
		max-height: 500px;
	}
}
</style>
