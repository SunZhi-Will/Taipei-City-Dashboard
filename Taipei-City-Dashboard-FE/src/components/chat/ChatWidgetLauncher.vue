<script setup>
import { onMounted, onBeforeUnmount, ref, watch, nextTick } from "vue";
import { useRoute } from "vue-router";
import ChatBox from "../dialogs/ChatBox.vue";
import ChatBotIcon from "../icons/ChatBotIcon.vue";

const isChatOpen = ref(false);
const isChatExpanded = ref(false);
const route = useRoute();
const launcherButtonRef = ref(null);

function toggleChat() {
	isChatOpen.value = !isChatOpen.value;
}

function closeChat() {
	isChatOpen.value = false;
	isChatExpanded.value = false;
	if (launcherButtonRef.value) {
		launcherButtonRef.value.focus();
	}
}

function handleChatExpand(expanded) {
	isChatExpanded.value = !!expanded;
}

function onEscKeydown(event) {
	if (!isChatOpen.value) return;
	if (event.key === "Escape") {
		closeChat();
	}
}

watch(
	() => route.fullPath,
	() => {
		if (isChatOpen.value) {
			closeChat();
		}
	},
);

watch(isChatOpen, async (opened) => {
	if (!opened) return;
	await nextTick();
	const panel = document.getElementById("chat-widget-panel");
	if (panel && typeof panel.focus === "function") {
		panel.focus();
	}
});

onMounted(() => {
	window.addEventListener("keydown", onEscKeydown);
});

onBeforeUnmount(() => {
	window.removeEventListener("keydown", onEscKeydown);
});
</script>

<template>
  <div class="chat-launcher-root">
    <div
      class="chatbot-container"
      role="region"
      aria-label="城市儀表板聊天小幫手"
    >
      <ChatBox
        v-if="isChatOpen"
        :class="['chatbox', { expanded: isChatExpanded }]"
        :show-close-button="true"
        @close="closeChat"
        @expand="handleChatExpand"
      />
      <div
        v-if="!isChatOpen"
        class="chatbot-btn-area"
      >
        <button
          ref="launcherButtonRef"
          class="chatbot-btn"
          type="button"
          :aria-label="isChatOpen ? '收合聊天視窗' : '開啟聊天視窗'"
          aria-controls="chat-widget-panel"
          :aria-expanded="isChatOpen"
          @click="toggleChat"
        >
          <ChatBotIcon />
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.chat-launcher-root {
	position: fixed;
	bottom: max(24px, env(safe-area-inset-bottom));
	right: max(24px, env(safe-area-inset-right));
	z-index: 2147483000;
	pointer-events: none;
	max-width: calc(100vw - 16px);
	overflow: visible;
}

.chatbot-container {
	display: flex;
	align-items: flex-end;
	gap: 1rem;
	pointer-events: auto;
	overflow: visible;
}

.chatbox {
	width: min(420px, calc(100vw - 32px));
	height: min(650px, calc(100vh - 96px));
	margin-bottom: 24px;
	animation: chat-panel-in 0.28s cubic-bezier(0.34, 1.56, 0.64, 1);
	transition: width 0.28s cubic-bezier(0.4, 0, 0.2, 1), height 0.28s cubic-bezier(0.4, 0, 0.2, 1), transform 0.28s cubic-bezier(0.4, 0, 0.2, 1);

	:deep(.chat-widget) {
		width: 100%;
		height: 100%;
	}
}

.chatbox.expanded {
	width: min(900px, calc(100vw - 32px));
	height: min(82vh, 900px);
}

@keyframes chat-panel-in {
	from {
		opacity: 0;
		transform: scale(0.94) translateY(20px);
	}
	to {
		opacity: 1;
		transform: scale(1) translateY(0);
	}
}

.chatbot-btn-area {
	display: flex;
	flex-direction: column;
	align-items: flex-end;
	gap: 0.5rem;
	overflow: visible;
}

.chatbot-btn {
	width: 56px;
	height: 56px;
	display: flex;
	align-items: center;
	justify-content: center;
	border-radius: 28px;
	background-color: #18181b;
	color: #ffffff;
	box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15), 0 4px 8px rgba(0, 0, 0, 0.1);
	transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
	border: none;
	cursor: pointer;
	overflow: visible;
	transform-origin: center;

	&:hover {
		transform: scale(1.05) translateY(-2px);
		box-shadow: 0 12px 32px rgba(0, 0, 0, 0.2);
		filter: brightness(0.92);
	}

	&:active {
		transform: scale(0.95);
	}
}

@media (max-height: 760px) and (min-width: 769px) {
	.chat-launcher-root {
		bottom: max(16px, env(safe-area-inset-bottom));
		right: max(16px, env(safe-area-inset-right));
	}

	.chatbox {
		height: min(650px, calc(100vh - 56px));
		margin-bottom: 12px;
	}

	.chatbox.expanded {
		width: min(900px, calc(100vw - 32px));
		height: calc(100vh - 56px);
	}
}

@media (max-width: 768px) {
	.chat-launcher-root {
		bottom: calc(70px + max(16px, env(safe-area-inset-bottom)));
		right: max(16px, env(safe-area-inset-right));
	}

	.chatbot-container {
		gap: 0;
	}

	.chatbox {
		position: fixed;
		left: 8px;
		right: 8px;
		bottom: calc(70px + 8px);
		height: calc(100vh - 70px - 16px);
		max-height: calc(100vh - 70px - 16px);
		width: auto;
		margin-bottom: 0;
		animation: none;
	}

	.chatbox.expanded {
		left: 8px;
		right: 8px;
		bottom: calc(70px + 8px);
		height: calc(100vh - 70px - 16px);
		max-height: calc(100vh - 70px - 16px);
	}

	.chatbot-btn {
		width: 52px;
		height: 52px;
	}
}
</style>
