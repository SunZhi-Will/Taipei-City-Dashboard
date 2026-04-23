<script setup>
import { nextTick, onMounted, ref, watch } from "vue";
import SendIcon from "../../icons/SendIcon.vue";

const props = defineProps({
	modelValue: {
		type: String,
		default: "",
	},
	isResponding: {
		type: Boolean,
		default: false,
	},
	compact: {
		type: Boolean,
		default: false,
	},
});

const emit = defineEmits(["update:modelValue", "send"]);

const chatInputRef = ref(null);

const resizeInput = () => {
	const input = chatInputRef.value;
	if (!input) return;
	input.style.height = "auto";
	const nextHeight = Math.min(input.scrollHeight, 120);
	input.style.height = `${nextHeight}px`;
};

const onInput = (event) => {
	emit("update:modelValue", event.target.value);
	resizeInput();
};

const onInputKeydown = (event) => {
	if (event.key === "Enter" && !event.shiftKey) {
		event.preventDefault();
		emit("send");
	}
};

watch(
	() => props.modelValue,
	async () => {
		await nextTick();
		resizeInput();
	},
);

onMounted(() => {
	resizeInput();
});
</script>

<template>
	<div
		class="input-shell"
		:class="{ 'input-shell--compact': compact }"
	>
    <textarea
      ref="chatInputRef"
      :model-value="modelValue"
      class="chat-input"
			:class="{ 'chat-input--compact': compact }"
      rows="1"
      :placeholder="isResponding ? '小幫手回應中...' : '輸入訊息（Shift+Enter 換行）...'"
      aria-label="輸入聊天訊息"
      :disabled="isResponding"
      @input="onInput"
      @keydown="onInputKeydown"
    />
    <button
      type="button"
      class="send-btn"
			:class="{ 'send-btn--compact': compact }"
      :disabled="isResponding || !modelValue.trim()"
      :aria-label="isResponding ? '訊息發送中' : '發送訊息'"
      @click="emit('send')"
    >
      <SendIcon />
    </button>
  </div>
</template>

<style scoped lang="scss">
$border-color: #353a41;
$border-hover: rgba(255, 255, 255, 0.2);
$input-bg: #252a2f;
$text-primary: #f4f4f5;
$transition-standard: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
$btn-size: 40px;
$white: #ffffff;

.input-shell {
	position: absolute;
	left: 0.75rem;
	right: 0.75rem;
	bottom: 0.75rem;
	display: flex;
	align-items: flex-end;
	width: auto;
	min-height: 52px;
	box-sizing: border-box;
	background: transparent;
	padding: 0;
	border: none;
	overflow: visible;
	z-index: 30;
}

.input-shell--compact {
	min-height: 44px;
}

.chat-input {
	width: 100%;
	min-width: 0;
	max-width: none;
	box-sizing: border-box;
	min-height: 52px;
	max-height: 200px;
	resize: none;
	overflow-y: auto;
	border: 1px solid $border-color;
	border-radius: 1.75rem;
	padding: 14px 64px 14px 24px;
	outline: none;
	color: $text-primary;
	background: $input-bg;
	font-size: 14px;
	line-height: 24px;
	font-family: inherit;
	box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.25), 0 10px 10px -5px rgba(0, 0, 0, 0.12);
	transition: $transition-standard;

	&::placeholder {
		color: #707078;
	}

	&:hover:not(:focus) {
		border-color: $border-hover;
	}

	&:focus {
		border-color: #5a6068;
		box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 10px 10px -5px rgba(0, 0, 0, 0.15);
	}
}

.chat-input--compact {
	min-height: 44px;
	max-height: 160px;
	border-radius: 999px;
	padding: 10px 56px 10px 16px;
	line-height: 20px;
	font-size: 13px;
}

.send-btn {
	position: absolute;
	right: 4px;
	top: 50%;
	bottom: auto;
	width: $btn-size;
	height: $btn-size;
	display: flex;
	align-items: center;
	justify-content: center;
	background: $white;
	border: none;
	border-radius: 999px;
	cursor: pointer;
	box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.15), 0 4px 6px -2px rgba(0, 0, 0, 0.08);
	transition: $transition-standard;
	transform: translateY(-50%);

	:deep(svg) {
		width: 28px;
		height: 28px;
	}

	:deep(svg circle) {
		display: none;
	}

	:deep(svg path) {
		fill: #1a1a1a;
	}

	&:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	&:hover:not(:disabled) {
		background: #f5f5f5;
		transform: translateY(-50%) scale(1.05);
		box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.12), 0 10px 10px -5px rgba(0, 0, 0, 0.06);
	}

	&:active:not(:disabled) {
		transform: translateY(-50%) scale(0.95);
	}
}

.send-btn--compact {
	width: 34px;
	height: 34px;
	right: 6px;
}

.send-btn--compact :deep(svg) {
	width: 24px;
	height: 24px;
}

@media (max-width: 768px) {
	.input-shell {
		left: 0.5rem;
		right: 0.5rem;
		bottom: 0.5rem;
	}

	.chat-input {
		padding: 12px 56px 12px 16px;
	}

	.send-btn {
		width: 40px;
		height: 40px;
		right: 4px;
	}
}
</style>
