<script setup>
import { ref, watch, nextTick, onMounted, onBeforeUnmount } from "vue";
import { storeToRefs } from "pinia";
import SendIcon from "../icons/SendIcon.vue";
import BotLogo from "../icons/BotLogo.vue";
import ChatResultComponents from "./ChatResultComponents.vue";

import { useChatStore } from "../../store/chatStore";
import { useContentStore } from "../../store/contentStore";
import { useAuthStore } from "../../store/authStore";
import http from "../../router/axios";

const props = defineProps({
	showCloseButton: {
		type: Boolean,
		default: false,
	},
});

const emit = defineEmits(["close", "expand"]);

const chatStore = useChatStore();
const contentStore = useContentStore();
const authStore = useAuthStore();
const { addChatData, addQueryData, saveChatLog, clearChatHistory } = chatStore;
const { createDashboard } = contentStore;
const { chatData, isResponding } = storeToRefs(chatStore);
const { editDashboard } = storeToRefs(contentStore);
const { user } = storeToRefs(authStore);

const userMessage = ref("");
const chatAreaRef = ref(null);
const chatInputRef = ref(null);
const isStickyOpen = ref(false);
const isExpanded = ref(false);
const dashboardCreationLoading = ref(false);
const MAX_INPUT_HEIGHT = 120;

// === 建議 Tags ===
const DEFAULT_TAGS = [
	"空氣品質", "交通壅塞", "捷運人流", "垃圾清運", "醫療資源", "老年人口",
];

const suggestedTags = ref([...DEFAULT_TAGS]);
const tagsScrollRef = ref(null);
const showScrollLeft = ref(false);
const showScrollRight = ref(false);

// 點擊 tag 直接送出
const clickTag = async (tag) => {
	if (isResponding.value) return;
	await addQueryData({ role: "user", content: tag });
	await nextTick();
	resizeInput();
};

const updateTagScrollButtons = () => {
	const el = tagsScrollRef.value;
	if (!el) return;
	showScrollLeft.value = el.scrollLeft > 10;
	showScrollRight.value = el.scrollLeft < el.scrollWidth - el.clientWidth - 10;
};

const scrollTagsLeft = () => tagsScrollRef.value?.scrollBy({ left: -200, behavior: "smooth" });
const scrollTagsRight = () => tagsScrollRef.value?.scrollBy({ left: 200, behavior: "smooth" });

const refreshTagButtons = () => {
	nextTick(() => updateTagScrollButtons());
	setTimeout(() => updateTagScrollButtons(), 320);
};

// bot 回覆後，根據內容動態更新相關 tags
watch(
	chatData,
	(newVal) => {
		const lastBot = [...newVal].reverse().find((m) => m.role === "bot" && !m.isDefault);
		if (!lastBot) return;
		const content = (lastBot.content || "") + (lastBot.components?.map((c) => c.name).join(" ") || "");
		const contextMap = [
			{ keywords: ["空氣", "PM2.5", "AQI", "污染"], tags: ["PM2.5 即時", "空氣品質指標", "各站空品"] },
			{ keywords: ["交通", "車流", "速率", "壅塞"], tags: ["路口車流量", "公車即時", "停車場資訊"] },
			{ keywords: ["捷運", "MRT", "地鐵"], tags: ["捷運進出站", "各線人流", "延誤查詢"] },
			{ keywords: ["垃圾", "清運", "廢棄物", "回收"], tags: ["垃圾清運量", "資源回收率", "廚餘處理"] },
			{ keywords: ["老年", "老化", "長照", "扶養"], tags: ["老化指數", "長照資源", "社福補助"] },
			{ keywords: ["醫療", "醫院", "診所", "救護"], tags: ["醫院分布", "AED 位置", "119 統計"] },
			{ keywords: ["水", "用水", "降雨", "水庫"], tags: ["水庫蓄水率", "降雨量統計", "淹水警戒"] },
			{ keywords: ["電", "用電", "能源", "再生"], tags: ["用電量統計", "太陽能發電", "碳排放量"] },
		];
		for (const rule of contextMap) {
			if (rule.keywords.some((k) => content.includes(k))) {
				suggestedTags.value = [...rule.tags, ...DEFAULT_TAGS.filter((t) => !rule.tags.includes(t)).slice(0, 3)];
				return;
			}
		}
		suggestedTags.value = [...DEFAULT_TAGS];
	},
	{ deep: true },
);

// tags 更新後重算捲動按鈕狀態
watch(suggestedTags, () => nextTick(() => updateTagScrollButtons()));

const resizeInput = () => {
	const input = chatInputRef.value;
	if (!input) return;
	input.style.height = "auto";
	const nextHeight = Math.min(input.scrollHeight, MAX_INPUT_HEIGHT);
	input.style.height = `${nextHeight}px`;
};

const onInputChange = () => {
	resizeInput();
};

const onInputKeydown = (event) => {
	if (event.key === "Enter" && !event.shiftKey) {
		event.preventDefault();
		sendBtnHandler(userMessage.value);
	}
};

const qaBtnHandler = async (text, relations) => {
	if (text === "建立儀表板") {
		if (dashboardCreationLoading.value === true) return;
		dashboardCreationLoading.value = true;
		const response = await http.get(`/dashboard/`);
		if (response.data?.data?.personal?.length > 20) {
			addChatData({
				role: "bot",
				content:
					"您的個人儀表板已超出限制 20 個，請先移除既有儀表板後，重新執行本功能！",
			});
			dashboardCreationLoading.value = false;
			return;
		}
		const components = Array.from(new Set(relations.map((r) => r.id))).map(
			(id) => ({ id }),
		);

		if (user.value.user_id) {
			editDashboard.value = {
				index: "",
				name: "推薦儀表板",
				icon: "star",
				components,
			};
			await createDashboard();
			saveChatLog("建立儀表板", "使用者成功建立儀表板!");
		} else {
			addChatData({
				role: "bot",
				content: "請先登入會員以使用此功能喔！",
			});
		}
		dashboardCreationLoading.value = false;
	}
};

const sendBtnHandler = async () => {
	if (isResponding.value) return;
	const normalizedText = userMessage.value.trim();
	if (!normalizedText) return;
	await addQueryData({
		role: "user",
		content: normalizedText,
	});
	userMessage.value = "";
	await nextTick();
	resizeInput();
};

const toggleSticky = () => {
	isStickyOpen.value = !isStickyOpen.value;
};

const closeWidget = () => {
	emit("close");
};

const toggleExpand = () => {
	isExpanded.value = !isExpanded.value;
	emit("expand", isExpanded.value);
	refreshTagButtons();
};

const onWindowResize = () => {
	refreshTagButtons();
};

const clearChat = () => {
	if (confirm("確定要清除所有聊天紀錄並開新的 Chat 嗎？")) {
		clearChatHistory();
	}
};

const copyToClipboard = async (text) => {
	if (!text) return;
	try {
		await navigator.clipboard.writeText(text);
	} catch (err) {
		console.error("複製失敗:", err);
	}
};

const handleExploreIndicator = async (indicatorName) => {
	if (isResponding.value || !indicatorName) return;
	await addQueryData({ role: "user", content: indicatorName });
	await nextTick();
	resizeInput();
};



const scrollToBottom = async () => {
	await nextTick();
	const chat = chatAreaRef.value;
	if (!chat) return;
	chat.scrollTop = chat.scrollHeight - chat.clientHeight;
};

onMounted(() => {
	scrollToBottom();
	nextTick(() => updateTagScrollButtons());
	window.addEventListener("resize", onWindowResize);
});

onBeforeUnmount(() => {
	window.removeEventListener("resize", onWindowResize);
});

watch(
	() => chatData.value.length,
	async () => {
		scrollToBottom();
	},
	{ deep: true },
);
</script>

<template>
	<div
		id="chat-widget-panel"
		class="chat-widget"
		role="dialog"
		aria-label="臺北城市儀表板小幫手"
		tabindex="-1"
	>
		<div class="header">
			<h3>臺北城市儀表板小幫手</h3>
			<div class="header-actions">
				<button
					type="button"
					class="action-btn clear-btn"
					title="清除歷史紀錄"
					aria-label="清除聊天歷史"
					@click="clearChat"
				>
					<svg viewBox="0 0 16 16" aria-hidden="true">
						<path d="M2.5 1a1 1 0 0 0-1 1v1a1 1 0 0 0 1 1H3v9a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2V4h.5a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1H10a1 1 0 0 0-1-1H7a1 1 0 0 0-1 1zm3 4a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-1 0v-7a.5.5 0 0 1 .5-.5M8 5a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-1 0v-7A.5.5 0 0 1 8 5m3 .5v7a.5.5 0 0 1-1 0v-7a.5.5 0 0 1 1 0" />
					</svg>
				</button>
				<button
					type="button"
					class="action-btn expand-btn"
					title="展開為全屏"
					aria-label="展開聊天視窗為全屏"
					@click="toggleExpand"
				>
					<svg viewBox="0 0 16 16" aria-hidden="true">
						<path d="M1.5 1a.5.5 0 0 0-.5.5v4a.5.5 0 0 1-1 0v-4A1.5 1.5 0 0 1 1.5 0h4a.5.5 0 0 1 0 1h-4zM10 .5a.5.5 0 0 1 .5-.5h4A1.5 1.5 0 0 1 16 1.5v4a.5.5 0 0 1-1 0v-4a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 1-.5-.5zM.5 10a.5.5 0 0 1 .5.5v4a.5.5 0 0 0 .5.5h4a.5.5 0 0 1 0 1h-4A1.5 1.5 0 0 1 0 14.5v-4a.5.5 0 0 1 .5-.5zm15 0a.5.5 0 0 1 .5.5v4a1.5 1.5 0 0 1-1.5 1.5h-4a.5.5 0 0 1 0-1h4a.5.5 0 0 0 .5-.5v-4a.5.5 0 0 1 .5-.5z" />
					</svg>
        </button>
			<button
				v-if="props.showCloseButton"
				class="action-btn close-btn"
				type="button"
				aria-label="關閉聊天視窗"
				@click="closeWidget"
			>
				<svg viewBox="0 0 16 16" aria-hidden="true">
					<path d="M2.146 2.854a.5.5 0 1 1 .708-.708L8 7.293l5.146-5.147a.5.5 0 0 1 .708.708L8.707 8l5.147 5.146a.5.5 0 0 1-.708.708L8 8.707l-5.146 5.147a.5.5 0 0 1-.708-.708L7.293 8z" />
				</svg>
			</button>
      </div>
    </div>

    <!-- 聊天區 -->
    <div
      ref="chatAreaRef"
      class="chat-area scrollbar-custom"
			role="log"
			aria-live="polite"
			aria-label="對話紀錄"
    >
      <!-- 置頂訊息 -->
      <div class="chat-message sticky-message">
        <div
          class="sticky-header"
          @click="toggleSticky"
        >
          <span>置頂公告：小幫手使用須知</span>
					<button
						class="toggle-btn"
						type="button"
						:aria-expanded="isStickyOpen"
						aria-label="切換置頂公告內容"
					>
            {{ isStickyOpen ? "-" : "+" }}
          </button>
        </div>
        <div
          v-show="isStickyOpen"
          class="sticky-body"
        >
					<span>小幫手目前支援 AI 對話與組件推薦兩種模式。預設會先嘗試 AI 對話，若服務繁忙會自動切換為組件推薦，協助您不中斷查詢。<br><br>
						若涉及即時資料或專業判讀，建議您搭配圖表與官方資料來源交叉確認。</span>
        </div>
      </div>
			<div
				v-if="chatData.length === 0 && !isResponding"
				class="empty-state"
			>
				<div class="empty-icon" aria-hidden="true">
					<svg viewBox="0 0 16 16">
						<path d="M5 8a1 1 0 1 1-2 0 1 1 0 0 1 2 0m4 0a1 1 0 1 1-2 0 1 1 0 0 1 2 0m3 1a1 1 0 1 0 0-2 1 1 0 0 0 0 2" />
					</svg>
				</div>
				<p class="empty-text">您好！請輸入想查詢的城市議題，我會協助推薦相關組件與說明。</p>
			</div>
      <div
        v-for="chat in chatData"
        :key="chat.id"
        class="message"
      >
        <!-- 機器人訊息 -->
        <div
          v-if="chat.role === 'bot'"
          class="bot"
        >
          <div class="content">
            <div
              v-if="chat.content"
							class="message--plain"
            >
              <p>{{ chat.content }}</p>
            </div>
						<ChatResultComponents
							v-if="chat.components && chat.components.length > 0"
							:components="chat.components"
							@copy="copyToClipboard"
							@explore="handleExploreIndicator"
						/>

            <!-- 儀表板卡片區 -->
            <div
              v-if="chat.relations && chat.relations.length > 0"
              class="dashboard-cards-area"
            >
              <div
                v-for="(item, index) in chat.relations"
                :key="index"
                class="dashboard-card"
              >
                <div class="card-content">
                  <h4 class="card-title">{{ item.name }}</h4>
                  <div class="card-meta">
                    <span class="card-city">
                      {{ item.city === "taipei" ? "🏙️ 臺北" : "🌆 雙北" }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
            <div
              v-if="chat.button"
              v-horizontal-wheel
              class="message--button scrollbar-x-hide"
            >
              <button
                v-for="btn in chat.button"
                :key="btn.id"
                @click="qaBtnHandler(btn.text, chat.relations)"
              >
                {{ btn.text }}
              </button>
            </div>
          </div>
        </div>
        <!-- 使用者訊息 -->
        <div
          v-else
          class="user"
        >
          <div
            v-if="chat.content"
            class="content"
          >
            <div class="message--bubble">
              <p>{{ chat.content }}</p>
            </div>
          </div>
        </div>
      </div>
			<div
				v-if="isResponding"
				class="responding-state"
			>
				<div class="avatar">
					<BotLogo />
				</div>
				<div class="typing-dots" aria-label="小幫手回應中">
					<span class="typing-dot" />
					<span class="typing-dot" />
					<span class="typing-dot" />
				</div>
			</div>
    </div>

    <!-- 輸入區 -->
    <div class="input-area">
			<!-- 建議 Tags -->
			<div
				v-if="!isResponding && suggestedTags.length > 0"
				class="tags-area"
				role="list"
				aria-label="建議查詢主題"
			>
				<button
					class="tag-scroll-btn tag-scroll-left"
					type="button"
					aria-hidden="true"
					:style="{ opacity: showScrollLeft ? '1' : '0', pointerEvents: showScrollLeft ? 'auto' : 'none' }"
					@click="scrollTagsLeft"
				>
					<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 16 16">
						<path fill-rule="evenodd" d="M11.354 1.646a.5.5 0 0 1 0 .708L5.707 8l5.647 5.646a.5.5 0 0 1-.708.708l-6-6a.5.5 0 0 1 0-.708l6-6a.5.5 0 0 1 .708 0z"/>
					</svg>
				</button>
				<div
					ref="tagsScrollRef"
					class="tags-scroll scrollbar-x-hide"
					@scroll="updateTagScrollButtons"
				>
					<button
						v-for="tag in suggestedTags"
						:key="tag"
						class="tag-chip"
						type="button"
						role="listitem"
						@click="clickTag(tag)"
					>
						{{ tag }}
					</button>
				</div>
				<button
					class="tag-scroll-btn tag-scroll-right"
					type="button"
					aria-hidden="true"
					:style="{ opacity: showScrollRight ? '1' : '0', pointerEvents: showScrollRight ? 'auto' : 'none' }"
					@click="scrollTagsRight"
				>
					<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" fill="currentColor" viewBox="0 0 16 16">
						<path fill-rule="evenodd" d="M4.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L10.293 8 4.646 2.354a.5.5 0 0 1 0-.708z"/>
					</svg>
				</button>
			</div>
			<div class="input-shell">
				<textarea
					ref="chatInputRef"
					v-model="userMessage"
					class="chat-input"
					rows="1"
					:placeholder="isResponding ? '小幫手回應中...' : '輸入訊息（Shift+Enter 換行）...'"
					aria-label="輸入聊天訊息"
					:disabled="isResponding"
					@input="onInputChange"
					@keydown="onInputKeydown"
				/>
				<button
					type="button"
					class="send-btn"
					:disabled="isResponding || !userMessage.trim()"
					:aria-label="isResponding ? '訊息發送中' : '發送訊息'"
					@click="sendBtnHandler"
				>
					<SendIcon />
				</button>
			</div>
		</div>
	</div>
</template>

<style lang="scss" scoped>
/* === 色彩系統（對齊 AIChatHub Widget） === */
$bg-dark: #18191d;
$panel-bg: #0f1013;
$card-bg: #252a2f;
$border-color: #353a41;
$border-hover: rgba(255, 255, 255, 0.2);
$input-bg: #252a2f;
$white: #ffffff;
$text-primary: #f4f4f5;
$text-secondary: #d0d0d8;
$text-muted: #a1a1aa;
$scroll-thumb-hover: #505560;

/* === 圓角系統 === */
$radius-8: 8px;
$radius-10: 10px;
$radius-15: 15px;
$radius-20: 20px;

/* === 動畫標準 === */
$transition-standard: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
$transition-fast: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);

/* === 尺寸標準 === */
$btn-size: 40px;
$btn-size-sm: 36px;

/* === Scrollbar === */
.scrollbar-x-hide {
	scrollbar-width: none;

	&::-webkit-scrollbar {
		display: none;
	}
}

.scrollbar-custom {
	&::-webkit-scrollbar {
		width: 2px;
		background: transparent;
	}

	&::-webkit-scrollbar-thumb {
		background: $white;
		border-radius: 8px;
	}

	&::-webkit-scrollbar-thumb:hover {
		background: $scroll-thumb-hover;
	}
}

/* === 主要樣式 === */
.chat-widget {
	width: 420px;
	max-width: 100%;
	height: 100%;
	border-radius: 16px;
	overflow: hidden;
	background: $bg-dark;
	border: 1px solid $border-color;
	display: flex;
	flex-direction: column;
	font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Roboto", sans-serif;
	color: #18181b;
	box-shadow: 0 20px 60px rgba(0, 0, 0, 0.16);

	&, * {
		box-sizing: border-box;
	}

	:where(div, p, span, button, table, thead, tbody, tr, th, td, svg, path) {
		overflow: visible;
	}

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

		.clear-btn {
			svg {
				width: 16px;
				height: 16px;
				fill: currentColor;
			}
		}

		.close-btn {
			svg {
				width: 16px;
				height: 16px;
				fill: currentColor;
			}
		}

		.expand-btn {
			svg {
				width: 16px;
				height: 16px;
				fill: currentColor;
			}
		}
	}

	.chat-area {
		flex: 1;
		min-height: 0;
		padding: 0 0 0.5rem;
		overflow-y: auto;
		overflow-x: hidden;
		background: $bg-dark;
		color: $white;

		.chat-message {
			padding: 0;
			margin: 0;
			border-radius: 0;
			background: transparent;
		}

		.empty-state {
			display: flex;
			flex-direction: column;
			align-items: center;
			justify-content: center;
			text-align: center;
			padding: 1.5rem 1.25rem;
			margin: 0 1rem;
			min-height: 180px;
			animation: fadeIn 0.3s ease-out;
		}

		.empty-icon {
			width: 48px;
			height: 48px;
			color: #909099;
			margin-bottom: 1rem;
			animation: scaleIn 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);

			svg {
				width: 100%;
				height: 100%;
				fill: currentColor;
			}
		}

		.empty-text {
			font-size: 14px;
			line-height: 1.5;
			color: $text-muted;
			margin: 0;
		}

		// 置頂訊息
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

		.message {
			padding: 0.75rem 1rem;
			animation: slideIn 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
			margin-bottom: 0.25rem;
			transition: $transition-fast;

			.bot,
			.user {
				display: flex;
				gap: 0.25rem;
				align-items: flex-start;
				width: 100%;

				&.user {
					justify-content: flex-end;
				}

				.content {
					display: flex;
					flex-direction: column;
					gap: 0.5rem;
					max-width: 100%;

					.dashboard-cards-area {
						display: grid;
						grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
						gap: 12px;
						margin-top: 12px;
						margin-bottom: 12px;

						.dashboard-card {
							position: relative;
							background: linear-gradient(135deg, #1f2a33 0%, #252a2f 100%);
							border: 1px solid $border-color;
							border-radius: $radius-10;
							padding: 12px;
							cursor: pointer;
							transition: $transition-fast;
							overflow: hidden;

							&::before {
								content: '';
								position: absolute;
								top: 0;
								left: 0;
								right: 0;
								height: 3px;
								background: linear-gradient(90deg, #00b4d8, #00d4ff);
								opacity: 0;
								transition: opacity 0.3s ease;
							}

							&:hover {
								border-color: $border-hover;
								transform: translateY(-2px);
								box-shadow: 0 4px 12px rgba(0, 180, 216, 0.15);

								&::before {
									opacity: 1;
								}

								.card-title {
									color: #00d4ff;
								}
							}

							.card-rank {
									display: none;
							}

							.card-title {
								margin: 0;
								font-size: 14px;
								font-weight: 600;
								color: $text-primary;
								transition: color 0.2s;
								word-break: break-word;
								max-height: 2.8em;
								overflow: hidden;
								text-overflow: ellipsis;
								display: -webkit-box;
								line-clamp: 2;
								-webkit-line-clamp: 2;
								-webkit-box-orient: vertical;
							}

							.card-meta {
								display: flex;
								gap: 8px;
								margin-top: 8px;
								flex-wrap: wrap;
								font-size: 12px;

								.card-city {
									background: rgba(0, 180, 216, 0.1);
									color: #00d4ff;
									padding: 2px 6px;
									border-radius: 3px;
									border: 1px solid rgba(0, 180, 216, 0.2);
									white-space: nowrap;
								}
							}
						}
					}

					.message--plain {
						p {
							color: $text-secondary;
							white-space: pre-line;
							margin: 0;
							padding: 0;
							font-size: 14px;
							line-height: 1.7;
						}
					}

					.message--bubble {
						border: none;
						border-radius: 1rem;
						background: #2a3f52;
						box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);

						p {
							color: $white;
							white-space: pre-line;
							margin: 0;
							padding: 0.75rem 1rem;
							font-size: 14px;
							line-height: 1.55;
						}
					}

					.message--button {
						display: flex;
						gap: 0.5rem;
						overflow-x: auto;

						button {
							padding: 0.5rem 0.875rem;
							border-radius: $radius-10;
							border: 1px solid $border-color;
							background: $card-bg;
							color: $text-primary;
							font-size: 13px;
							font-weight: 500;
							white-space: nowrap;
							cursor: pointer;
							transition: $transition-fast;

							&:hover {
								background: rgba($white, 0.08);
								border-color: $border-hover;
								filter: brightness(1.12);
								transform: scale(1.02);
							}

							&:active {
								transform: scale(0.98);
							}
						}
					}
				}
			}

			.user {
				.content {
					max-width: 32rem;
				}
			}
		}

		.responding-state {
			display: flex;
			align-items: center;
			gap: 0.5rem;
			padding: 0.75rem 1rem;
			font-size: 13px;
			color: #909099;
			opacity: 0.85;

			.avatar {
				width: 28px;
				height: 28px;
				display: flex;
				align-items: center;
				justify-content: center;
				flex-shrink: 0;

				svg {
					width: 100%;
					height: auto;
				}
			}

			.typing-dots {
				display: flex;
				align-items: center;
				gap: 6px;
				padding: 8px 0;
			}

			.typing-dot {
				width: 8px;
				height: 8px;
				border-radius: 50%;
				background: #7a7a88;
				animation: chat-typing-bounce 1.4s infinite ease-in-out;
			}

			.typing-dot:nth-child(1) {
				animation-delay: 0s;
			}

			.typing-dot:nth-child(2) {
				animation-delay: 0.2s;
			}

			.typing-dot:nth-child(3) {
				animation-delay: 0.4s;
			}
		}
	}

	.input-area {
		padding: 0.5rem 0.75rem 0.75rem;
		background: $bg-dark;
		border-top: 1px solid $border-color;

		.tags-area {
			position: relative;
			width: 100%;
			margin-bottom: 0.5rem;
			animation: fadeIn 0.25s ease-out;

			.tags-scroll {
				display: flex;
				gap: 0.5rem;
				overflow-x: auto;
				overflow-y: hidden;
				padding: 0.25rem 1.75rem;
				scroll-behavior: smooth;
			}

			.tag-chip {
				flex-shrink: 0;
				padding: 0.375rem 0.75rem;
				border-radius: 1rem;
				border: 2px solid rgba($white, 0.28);
				background: rgba($white, 0.06);
				color: $text-secondary;
				font-size: 0.8125rem;
				font-family: inherit;
				white-space: nowrap;
				cursor: pointer;
				transition: $transition-fast;

				&:hover {
					background: rgba($white, 0.11);
					border-color: rgba($white, 0.35);
					color: $text-primary;
				}

				&:active {
					transform: scale(0.98);
				}
			}

			.tag-scroll-btn {
				position: absolute;
				top: 50%;
				transform: translateY(-50%);
				width: 28px;
				height: 28px;
				background: #2a2f36;
				border: 1px solid #4a515a;
				border-radius: 50%;
				display: flex;
				align-items: center;
				justify-content: center;
				cursor: pointer;
				transition: $transition-fast;
				z-index: 10;
				color: #ffffff;
				box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);

				&:hover {
					background: #363d47;
					border-color: #5b6572;
					transform: translateY(-50%) scale(1.05);
				}
			}

			.tag-scroll-left { left: 0; }
			.tag-scroll-right { right: 0; }
		}

		.input-shell {
			position: relative;
			display: flex;
			align-items: flex-end;
			width: 100%;
			min-height: 52px;
			box-sizing: border-box;
			background: transparent;
			padding: 0;
			border: none;
			overflow: visible;
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
	}

}

@media (max-width: 768px) {
  .chat-widget {
    border-radius: 12px;

    .input-area {
      padding: 0.5rem;

      .chat-input {
        padding: 12px 56px 12px 16px;
      }

      .send-btn {
        width: 40px;
        height: 40px;
        right: 4px;
      }
    }
  }
}

@keyframes chat-msg-in {
	from {
		opacity: 0;
		transform: translateY(10px);
	}
	to {
		opacity: 1;
		transform: translateY(0);
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

@keyframes fadeIn {
	from {
		opacity: 0;
	}
	to {
		opacity: 1;
	}
}

@keyframes scaleIn {
	from {
		opacity: 0;
		transform: scale(0.8);
	}
	to {
		opacity: 1;
		transform: scale(1);
	}
}

@keyframes chat-typing-bounce {
	0%,
	60%,
	100% {
		transform: translateY(0);
		opacity: 0.7;
	}
	30% {
		transform: translateY(-10px);
		opacity: 1;
	}
}

/* Component Cards Styles (NEW) */
.component-cards-area {
	margin: 12px 0;
	display: flex;
	flex-direction: column;
	gap: 10px;
}

.component-card {
	border: 1px solid #ddd;
	border-radius: 8px;
	padding: 12px;
	background: #f9f9f9;
	box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08);
	transition: all 0.3s ease;

	&:hover {
		box-shadow: 0 4px 8px rgba(0, 0, 0, 0.12);
		border-color: #0066cc;
	}
}

.component-header {
	display: flex;
	align-items: center;
	gap: 8px;
	margin-bottom: 8px;
	border-bottom: 1px solid #eee;
	padding-bottom: 8px;
}

.component-name {
	font-size: 14px;
	font-weight: 600;
	color: #333;
	margin: 0;
}

.component-category {
	display: inline-block;
	padding: 2px 8px;
	background: #0066cc;
	color: white;
	border-radius: 4px;
	font-size: 11px;
	font-weight: 500;
}

.component-body {
	display: flex;
	flex-direction: column;
	gap: 10px;
}

.component-description {
	font-size: 12px;
	color: #555;
	line-height: 1.5;
	margin: 0;
}

.props-section,
.code-section {
	margin-top: 8px;

	h5 {
		font-size: 12px;
		font-weight: 600;
		color: #333;
		margin: 0 0 6px 0;
	}
}

.props-table {
	width: 100%;
	font-size: 11px;
	border-collapse: collapse;

	tbody tr {
		border-bottom: 1px solid #eee;

		&:last-child {
			border-bottom: none;
		}

		td {
			padding: 4px 6px;
		}
	}

	.prop-name {
		font-weight: 600;
		color: #333;
		max-width: 100px;
		word-break: break-word;
	}

	.prop-type {
		color: #666;
		font-family: monospace;
		font-size: 10px;
	}
}

.code-block {
	background: #f5f5f5;
	border: 1px solid #ddd;
	border-radius: 4px;
	padding: 8px;
	margin: 6px 0;
	font-size: 11px;
	font-family: 'Monaco', 'Courier New', monospace;
	overflow-x: auto;
	color: #333;
	line-height: 1.4;

	code {
		display: block;
		white-space: pre-wrap;
		word-break: break-all;
	}
}

.copy-btn {
	padding: 4px 10px;
	font-size: 11px;
	background: #0066cc;
	color: white;
	border: none;
	border-radius: 4px;
	cursor: pointer;
	transition: all 0.2s ease;

	&:hover {
		background: #0052a3;
		transform: scale(1.05);
	}

	&:active {
		transform: scale(0.98);
	}
}

.component-actions {
	display: flex;
	gap: 8px;
	margin-top: 8px;
}

.view-source-link {
	display: inline-block;
	padding: 4px 10px;
	font-size: 11px;
	background: #e8f0fe;
	color: #0066cc;
	border: 1px solid #0066cc;
	border-radius: 4px;
	text-decoration: none;
	transition: all 0.2s ease;
	cursor: pointer;

	&:hover {
		background: #0066cc;
		color: white;
	}
}
</style>
