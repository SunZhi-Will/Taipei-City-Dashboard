import { ref, watch } from 'vue';
import { defineStore } from 'pinia';
import http from '../router/axios';
import {
	queryByTwai,
	queryByVector,
	componentsFromAgentResult,
	ensureDashboardConfigs,
	selectFocusedComponents,
	fetchDashboardComponentsByVector,
	buildComponentNarrative,
	resolveSceneFromAI,
	saveChatLog as aiChatServiceSaveChatLog,
	isDirectComponentIntent,
	buildTwaiFallbackNotice,
} from '../services/aiChatService';

const USE_TWAI_CHAT = (import.meta.env.VITE_USE_TWAI_CHAT ?? 'true') !== 'false';

export const useChatStore = defineStore('chat', () => {
	const defaultChatData = [
		{
			id: 1,
			role: 'bot',
			isDefault: true,
			content:
				'您好，我是【臺北城市儀表板】小幫手，很高興為您服務！\n 您可以： \n\n • 直接提問城市數據問題（AI 對話）\n • 輸入主題描述，我會推薦相關組件並可一鍵建立儀表板\n\n 若 AI 服務暫時忙碌，我會自動切換為組件推薦模式，確保不中斷。\n\n 📩 聯絡信箱：tuic@gov.taipei \n 🏢 臺北大數據中心 \n\n',
		},
	];

	const recommendComponents = ref([]);
	const isResponding = ref(false);
	const savedChatData = JSON.parse(sessionStorage.getItem('chatData')) || [];
	const chatData = ref([...defaultChatData, ...savedChatData]);

	watch(
		chatData,
		(newVal) => {
			sessionStorage.setItem(
				'chatData',
				JSON.stringify(newVal.filter((item) => !item.isDefault)),
			);
		},
		{ deep: true },
	);

	const addChatData = (newChatData) => {
		chatData.value.push({ id: chatData.value.length + 1, isDefault: false, ...newChatData });
	};

	const queryByVectorFallback = async (question) => {
		recommendComponents.value = await queryByVector(question);
		const topK = [...recommendComponents.value].sort((a, b) => b.score - a.score);

		if (topK.length > 0) {
			chatData.value.push({
				id: chatData.value.length + 1,
				role: 'bot',
				isDefault: false,
				button: [{ id: 1, text: '建立儀表板' }],
				content: '您好 😊 \n 以下是根據您的問題，自動為您推薦的「組件清單」。您可以將這些組件整批加入「個人儀表板」，方便日後快速查看與使用。\n',
				relations: topK,
				scene: resolveSceneFromAI(question, '', topK, 'components'),
			});
			chatData.value.push({
				id: chatData.value.length + 1,
				role: 'bot',
				isDefault: false,
				content: '若您有任何新的查詢或想深入探索的內容，都可以隨時在對話框告訴我～\n 我很樂意再協助您 💬✨',
			});
		} else {
			chatData.value.push({
				id: chatData.value.length + 1,
				role: 'bot',
				isDefault: false,
				content: '很抱歉，您提供的描述沒有相似組件，請繼續提問 ! ',
				scene: resolveSceneFromAI(question, '', [], 'web'),
			});
		}

		saveChatLog(question, recommendComponents.value, {
			answerMode: 'vector_fallback',
			usedTools: ['vector_component_search'],
		});
	};

	const addQueryData = async (newChatData) => {
		if (isResponding.value) return;
		isResponding.value = true;
		chatData.value.push({ id: chatData.value.length + 1, isDefault: false, ...newChatData });

		try {
			if (USE_TWAI_CHAT) {
				const twaiResult = await queryByTwai(newChatData.content, chatData.value);
				if (twaiResult?.ok) {
					let components = componentsFromAgentResult(twaiResult.agentResult);
					if (components.length > 0) {
						components = await ensureDashboardConfigs(components);
					}

					const shouldRetrieveComponents =
						(Array.isArray(twaiResult.tools) && twaiResult.tools.includes('retrieve_components_by_query')) ||
						isDirectComponentIntent(newChatData.content);

					if (shouldRetrieveComponents && components.length === 0) {
						components = await fetchDashboardComponentsByVector(newChatData.content, 5, 0.78);
					}

					if (components.length > 0) {
						components = selectFocusedComponents(components, newChatData.content);
					}

					const finalContent = buildComponentNarrative(newChatData.content, components, twaiResult.content);
					chatData.value.push({
						id: chatData.value.length + 1,
						role: 'bot',
						isDefault: false,
						content: finalContent,
						answerMode: twaiResult.answerMode,
						selectionReason: twaiResult.agentResult?.selection_reason,
						usedTools: twaiResult.tools,
						button: components.length > 0 ? [{ id: 1, text: '建立儀表板' }] : undefined,
						relations: components.length > 0 ? components : undefined,
						scene: resolveSceneFromAI(
							newChatData.content,
							twaiResult.content,
							components,
							components.length > 0 ? 'components' : 'web',
						),
						components: components.length > 0 ? components : undefined,
					});

					saveChatLog(newChatData.content, finalContent, {
						answerMode: twaiResult.answerMode,
						usedTools: twaiResult.tools,
					});
					return;
				}

				chatData.value.push({
					id: chatData.value.length + 1,
					role: 'bot',
					isDefault: false,
					content: buildTwaiFallbackNotice(twaiResult?.reason),
				});
			}

			await queryByVectorFallback(newChatData.content);
		} finally {
			isResponding.value = false;
		}
	};

	const saveChatLog = async (question, answer, meta = {}) => {
		await aiChatServiceSaveChatLog(question, answer, meta);
	};

	const clearChatHistory = () => {
		chatData.value = [...defaultChatData];
		sessionStorage.removeItem('chatData');
		isResponding.value = false;
	};

	return { chatData, isResponding, addChatData, addQueryData, saveChatLog, clearChatHistory };
});