import { ref, watch } from 'vue';
import { defineStore } from 'pinia';
import {
	queryByTwai,
	queryByVector,
	componentsFromAgentResult,
	ensureDashboardConfigs,
	selectFocusedComponents,
	fetchDashboardComponentsByVector,
	buildComponentNarrative,
	resolveSceneFromAI,
	resolveSceneFromDisplayPlan,
	saveChatLog as aiChatServiceSaveChatLog,
	isDirectComponentIntent,
	buildTwaiFallbackNotice,
} from '../services/aiChatService';

const USE_TWAI_CHAT = (import.meta.env.VITE_USE_TWAI_CHAT ?? 'true') !== 'false';

export const useAiStudioChatStore = defineStore('aiStudioChat', () => {
	const defaultChatData = [
		{
			id: 1,
			role: 'bot',
			isDefault: true,
			content:
				'您好，我是【AI Studio 助手】，很高興為您服務！\n 我可以幫助您：\n\n • 深入分析城市議題與數據\n • 推薦相關儀表板組件\n • 生成自訂場景展示\n\n 📩 有任何問題，隨時告訴我吧！\n',
		},
	];

	const recommendComponents = ref([]);
	const isResponding = ref(false);
	const savedChatData = JSON.parse(sessionStorage.getItem('aiStudioChatData')) || [];
	const chatData = ref([...defaultChatData, ...savedChatData]);

	watch(
		chatData,
		(newVal) => {
			sessionStorage.setItem(
				'aiStudioChatData',
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
				scene: resolveSceneFromAI(question, '', topK, 'presentation'),
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
				const twaiResult = await queryByTwai(newChatData.content, chatData.value, { appMode: 'ai_studio' });
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
					const plannedScene = resolveSceneFromDisplayPlan(
						newChatData.content,
						twaiResult.displayPlan,
						components,
					);

					chatData.value.push({
						id: chatData.value.length + 1,
						role: 'bot',
						isDefault: false,
						content: finalContent,
						answerMode: twaiResult.answerMode,
						selectionReason: twaiResult.agentResult?.selection_reason,
						usedTools: twaiResult.tools,
						toolTimeline: twaiResult.toolTimeline,
						displayPlan: twaiResult.displayPlan || undefined,
						meta: twaiResult.meta,
						scene:
							plannedScene ||
							resolveSceneFromAI(
								newChatData.content,
								twaiResult.content,
								components,
								components.length > 0 ? 'presentation' : 'web',
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
		sessionStorage.removeItem('aiStudioChatData');
		isResponding.value = false;
	};

	return {
		chatData,
		isResponding,
		addChatData,
		addQueryData,
		saveChatLog,
		clearChatHistory,
	};
});
