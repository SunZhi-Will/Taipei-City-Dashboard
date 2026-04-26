/**
 * AI Chat Service
 * 提取聊天邏輯層，供多個 Chat 元件共用
 * - TWAI API 調用
 * - 向量檢索
 * - 訊息構建與轉換
 * - 場景生成
 */

import http from "../router/axios";
import { isOfficialComponent } from "../constants/nonOfficialComponentIndexes";
import { getComponentDataTimeframe } from "../assets/utilityFunctions/dataTimeframe";

const MAX_CONTEXT_MESSAGES = 12;
const TWAI_MAX_RETRY = 2;
const TWAI_SESSION_KEY = 'twai_session_id';

const createRandomSessionPart = () => {
	if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
		return crypto.randomUUID().replace(/-/g, '').slice(0, 12);
	}
	return `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 10)}`;
};

const getTwaiSessionId = () => {
	const current = sessionStorage.getItem(TWAI_SESSION_KEY);
	if (current) return current;

	const sessionId = `session_${createRandomSessionPart()}`;
	sessionStorage.setItem(TWAI_SESSION_KEY, sessionId);
	return sessionId;
};

// ═══════════════════════════════════════════════════════════════════
// 工具函數：文字處理
// ═══════════════════════════════════════════════════════════════════

export const normalizeText = (text = '') =>
	String(text)
		.toLowerCase()
		.replace(/[\s\u3000，,。.!！?？、;；:\-_/()（）[\]【】]/g, '');

export const isDirectComponentIntent = (query = '') => {
	const q = String(query || '');
	return /組件|元件|顯示|查看|打開|我要看|幫我找|扶養比及老化指數|長照指標/.test(q);
};

export const buildTwaiFallbackNotice = (reason) => {
	const code = String(reason || 'UNKNOWN');
	if (code === 'HTTP_429') {
		return `AI 對話服務目前流量較高（${code}），已自動切換為組件推薦模式。`;
	}
	if (code === 'NETWORK_OR_TIMEOUT') {
		return `AI 對話連線逾時或網路不穩（${code}），已自動切換為組件推薦模式。`;
	}
	if (code === 'EMPTY_CONTENT' || code === 'EMPTY_RESPONSE') {
		return `AI 對話本次未產生可用內容（${code}），已自動切換為組件推薦模式。`;
	}
	if (/^HTTP_4\d\d$/.test(code)) {
		return `AI 對話請求未通過（${code}），已自動切換為組件推薦模式。`;
	}
	if (/^HTTP_5\d\d$/.test(code)) {
		return `AI 對話服務回應異常（${code}），已自動切換為組件推薦模式。`;
	}
	return `AI 對話暫時不可用（${code}），已自動切換為組件推薦模式。`;
};

// ═══════════════════════════════════════════════════════════════════
// 組件匹配與評分
// ═══════════════════════════════════════════════════════════════════

export const computeComponentMatchScore = (component, query) => {
	const qNorm = normalizeText(query);
	const nameNorm = normalizeText(component?.name || '');
	const idxNorm = normalizeText(component?.index || '');
	let score = Number(component?.score || 0) * 10;

	if (!qNorm) return score;
	if (nameNorm && (nameNorm.includes(qNorm) || qNorm.includes(nameNorm))) score += 120;
	if (idxNorm && (idxNorm.includes(qNorm) || qNorm.includes(idxNorm))) score += 90;

	const terms = String(query)
		.split(/[\s,，、;；/]+/)
		.filter((t) => t && !['的', '及', '與', '跟', '請', '幫我', '我要', '資料', '數據'].includes(t));
	for (const term of terms) {
		const tNorm = normalizeText(term);
		if (!tNorm) continue;
		if (nameNorm.includes(tNorm)) score += 25;
		if (idxNorm.includes(tNorm)) score += 15;
	}

	return score;
};

export const selectFocusedComponents = (components, query) => {
	const list = Array.isArray(components) ? components : [];
	if (list.length <= 1) {
		return list.map((item, idx) => ({ ...item, isPrimary: idx === 0 }));
	}

	const ranked = [...list]
		.map((item) => ({ ...item, __matchScore: computeComponentMatchScore(item, query) }))
		.sort((a, b) => b.__matchScore - a.__matchScore);

	const top = ranked[0];
	const second = ranked[1];
	const directIntent = isDirectComponentIntent(query);
	const dominant = !second || (top.__matchScore - second.__matchScore >= 25);
	const limit = directIntent ? 3 : 4;
	const selected = ranked.slice(0, limit);
	const normalized = selected.map((item, idx) => ({
		...item,
		isPrimary: idx === 0,
	}));

	if (directIntent && dominant) {
		return normalized;
	}

	return normalized;
};

// ═══════════════════════════════════════════════════════════════════
// 組件配置和數據豐富化
// ═══════════════════════════════════════════════════════════════════

export const pickConfigByCity = (configs, city) => {
	if (!Array.isArray(configs) || configs.length === 0) return null;
	return configs.find((item) => item?.city === city) || configs[0];
};

export const buildChartParams = (component) => ({
	city: component?.city,
	...(!['static', 'current', 'demo'].includes(component?.time_from)
		? getComponentDataTimeframe(component?.time_from, component?.time_to, true)
		: {}),
});

export const fetchCompleteDashboardConfig = async (componentId, city) => {
	if (!componentId) return null;

	try {
		const detailResp = await http.get(`/component/${componentId}/all`);
		const candidates = Array.isArray(detailResp?.data?.data) ? detailResp.data.data : [];
		const dashboardConfig = pickConfigByCity(candidates, city);
		if (!dashboardConfig) return null;

		try {
			const chartResp = await http.get(`/component/${dashboardConfig.id}/chart`, {
				params: buildChartParams(dashboardConfig),
			});
			dashboardConfig.chart_data = chartResp?.data?.data ?? [];
			if (chartResp?.data?.categories) {
				dashboardConfig.chart_config.categories = chartResp.data.categories;
			}
		} catch (err) {
			console.warn('Load dashboard chart data failed:', dashboardConfig?.id, err);
			dashboardConfig.chart_data = [];
		}

		return dashboardConfig;
	} catch (err) {
		console.warn('Load dashboard config failed:', componentId, err);
		return null;
	}
};

export const hydrateDashboardComponents = async (vectorResults = []) => {
	const normalized = Array.isArray(vectorResults) ? vectorResults : [];
	const enriched = await Promise.all(
		normalized.map(async (item, idx) => {
			const dashboardConfig = item?.id
				? await fetchCompleteDashboardConfig(item.id, item.city)
				: null;

			return {
				id: item.id || `vector-${item.index || idx}`,
				name: item.name || '未知組件',
				index: item.index,
				city: item.city,
				score: item.score,
				category: 'dashboard_component',
				description:
					dashboardConfig?.short_desc ||
					item.description ||
					`城市: ${item.city || 'N/A'}，相關性: ${item.score || 0}`,
				props: {
					index: item.index,
					score: item.score,
				},
				usage_example: '',
				dashboardConfig,
			};
		}),
	);

	return enriched;
};

export const ensureDashboardConfigs = async (components = []) => {
	const list = Array.isArray(components) ? components : [];
	const enriched = await Promise.all(
		list.map(async (item, idx) => {
			if (item?.dashboardConfig) return item;

			const maybeDashboard = item?.category === 'dashboard_component' || Boolean(item?.id);
			if (!maybeDashboard) return item;

			const dashboardConfig = item?.id
				? await fetchCompleteDashboardConfig(item.id, item.city)
				: null;

			return {
				...item,
				id: item.id || `component-${item.index || idx}`,
				category: item.category || 'dashboard_component',
				dashboardConfig,
			};
		}),
	);

	return enriched;
};

// ═══════════════════════════════════════════════════════════════════
// 組件推薦邏輯
// ═══════════════════════════════════════════════════════════════════

export const componentsFromAgentResult = (agentResult) => {
	if (!agentResult || !agentResult.primary_component) return [];

	const mapCandidate = (item, isPrimary = false) => ({
		id: item?.id,
		name: item?.name || '未知組件',
		index: item?.index,
		city: item?.city,
		score: item?.score,
		category: 'dashboard_component',
		description: '',
		props: {
			index: item?.index,
			score: item?.score,
		},
		usage_example: '',
		isPrimary,
	});

	const primary = mapCandidate(agentResult.primary_component, true);
	const related = Array.isArray(agentResult.related_components)
		? agentResult.related_components.map((item) => mapCandidate(item, false))
		: [];

	return [primary, ...related].filter((item) => item.id);
};

export const fetchDashboardComponentsByVector = async (query, limit = 5, score = 0.78) => {
	const vectorResp = await http.post(
		'/vector/component',
		new URLSearchParams({
			query,
			limit,
			score,
		}),
		{ headers: { 'Content-Type': 'application/x-www-form-urlencoded' } },
	);

	const vectorResults = Array.isArray(vectorResp?.data?.data) ? vectorResp.data.data : [];
	return hydrateDashboardComponents(vectorResults);
};

export const summarizeRelatedComponents = (components = []) => {
	const names = components
		.map((item) => item?.name)
		.filter(Boolean)
		.slice(0, 3);

	if (names.length === 0) return '';
	if (names.length === 1) return `若您要延伸比較，也可以一起看 ${names[0]}。`;
	if (names.length === 2) return `若您要延伸比較，也可以一起看 ${names[0]} 與 ${names[1]}。`;
	return `若您要延伸比較，也可以一起看 ${names.slice(0, -1).join('、')} 與 ${names[names.length - 1]}。`;
};

export const buildComponentNarrative = (question, components = [], aiContent = '') => {
	const list = Array.isArray(components) ? components : [];
	if (list.length === 0) {
		return String(aiContent || '').trim();
	}

	const primary = list.find((item) => item?.isPrimary) || list[0];
	const related = list.filter((item) => item && item !== primary);
	const shortDesc = primary?.dashboardConfig?.short_desc || primary?.description || '';
	const normalizedAiContent = String(aiContent || '').trim();
	const genericAiReply = !normalizedAiContent || /主結果|相關候選|score|rag|tool|index|id|rephrase|rephrase your question|retrieve/i.test(normalizedAiContent);

	const intro = `我先幫您整理成最值得直接查看的圖表：${primary?.name || '相關指標'}。`;
	const summary = shortDesc ? `這個指標重點在於${shortDesc}。` : `這張圖表最能直接回應您剛剛提到的「${question}」。`;
	const relatedHint = summarizeRelatedComponents(related);

	if (genericAiReply) {
		return [intro, summary, relatedHint].filter(Boolean).join(' ');
	}

	return [normalizedAiContent, relatedHint].filter(Boolean).join(' ');
};

// ═══════════════════════════════════════════════════════════════════
// 場景生成
// ═══════════════════════════════════════════════════════════════════

export const extractSceneJson = (text = '') => {
	const rawText = String(text || '');
	const fencedBlocks = [...rawText.matchAll(/```(?:json)?\s*([\s\S]*?)```/gi)]
		.map((item) => item[1])
		.filter(Boolean);

	const candidates = [...fencedBlocks, rawText];
	for (const candidate of candidates) {
		const start = candidate.indexOf('{');
		const end = candidate.lastIndexOf('}');
		if (start === -1 || end === -1 || end <= start) continue;

		try {
			const parsed = JSON.parse(candidate.slice(start, end + 1));
			if (!parsed || typeof parsed !== 'object') continue;
			if (!parsed.layout || !parsed.rightPanelMode && !parsed.layout?.rightPanel) continue;
			return parsed;
		} catch {
			continue;
		}
	}

	return null;
};

export const buildFallbackScene = (question = '', components = [], preferredMode = 'components') => {
	const safeComponents = Array.isArray(components) ? components : [];
	const normalizedQuestion = String(question || '');
	const isShowcaseIntent = /輪播|形象|展示|大螢幕|看板|signage|宣傳|播映/i.test(normalizedQuestion);
	const rightMode = ['components', 'map', 'web', 'presentation'].includes(preferredMode)
		? preferredMode
		: isShowcaseIntent
			? 'presentation'
			: 'components';

	const industry = (() => {
		if (/交通|捷運|公車|車流|壅塞/i.test(normalizedQuestion)) return 'transport';
		if (/老人|高齡|長照|扶養|社福/i.test(normalizedQuestion)) return 'senior-care';
		if (/學校|校園|學生|教育/i.test(normalizedQuestion)) return 'education';
		if (/醫療|健康|醫院|防疫/i.test(normalizedQuestion)) return 'health';
		return 'general';
	})();

	const buildPresentationSlides = () => {
		// 戰情室模式：直接產生所有組件投影片，無首頁/尾頁包裝
		// 若組件有多種圖表類型，各展開一張投影片
		const slides = [];
		safeComponents.forEach((item, index) => {
			const types = item?.dashboardConfig?.chart_config?.types;
			if (Array.isArray(types) && types.length > 1) {
				types.forEach((chartType) => {
					slides.push({
						id: `component-${item?.id || index}-${chartType}`,
						type: 'component',
						title: item?.name || `重點指標 ${index + 1}`,
						subtitle: item?.dashboardConfig?.short_desc || 'AI 選出的高相關指標畫面。',
						focusComponentId: item?.id,
						chartType,
						durationSec: 12,
					});
				});
			} else {
				slides.push({
					id: `component-${item?.id || index}`,
					type: 'component',
					title: item?.name || `重點指標 ${index + 1}`,
					subtitle: item?.dashboardConfig?.short_desc || 'AI 選出的高相關指標畫面。',
					focusComponentId: item?.id,
					chartType: Array.isArray(types) ? types[0] : undefined,
					durationSec: 12,
				});
			}
		});
		return slides;
	};

	return {
		version: '1.0',
		title: `AI 生成展示：${String(question || '').slice(0, 30) || '城市議題'}`,
		objective: '依需求快速組裝可展示儀表板',
		layout: {
			type: 'split',
			leftPanel: {
				collapsed: false,
				width: 380,
			},
			rightPanel: {
				mode: rightMode,
			},
		},
		presentation: {
			style: rightMode === 'presentation' ? (isShowcaseIntent ? 'carousel' : 'briefing') : 'component-grid',
			autoplay: {
				enabled: rightMode === 'presentation',
				intervalMs: 10000,
			},
			audience: 'public-screen',
			industry,
			slides: (rightMode === 'presentation' || safeComponents.length > 0) ? buildPresentationSlides() : [],
		},
		blocks: safeComponents.map((item) => ({
			type: 'component',
			title: item?.name || '未命名組件',
			componentId: item?.id,
			componentIndex: item?.index,
			city: item?.city || item?.dashboardConfig?.city || 'taipei',
		})),
		meta: {
			city: safeComponents[0]?.city || safeComponents[0]?.dashboardConfig?.city || 'taipei',
			theme: 'default',
			updatedAt: new Date().toISOString(),
		},
	};
};

export const resolveSceneFromAI = (question = '', aiRawContent = '', components = [], preferredMode = 'components') => {
	const extracted = extractSceneJson(aiRawContent);
	if (extracted) {
		if (!extracted?.presentation && /輪播|形象|展示|看板|大螢幕|signage/i.test(String(question || ''))) {
			const enhancedMode = extracted?.layout?.rightPanel?.mode || 'presentation';
			return {
				...buildFallbackScene(question, components, enhancedMode),
				...extracted,
				layout: {
					...buildFallbackScene(question, components, enhancedMode).layout,
					...extracted.layout,
					rightPanel: {
						...buildFallbackScene(question, components, enhancedMode).layout.rightPanel,
						...extracted?.layout?.rightPanel,
					},
				},
			};
		}
		return extracted;
	}
	return buildFallbackScene(question, components, preferredMode);
};

export const resolveSceneFromDisplayPlan = (question = '', displayPlan = null, components = []) => {
	if (!displayPlan || typeof displayPlan !== 'object') {
		return null;
	}

	const safeComponents = Array.isArray(components) ? components : [];
	const mode = ['components', 'map', 'web', 'presentation'].includes(displayPlan.mode)
		? displayPlan.mode
		: 'presentation';

	const slides = Array.isArray(displayPlan.slides)
		? displayPlan.slides.map((slide, index) => ({
			id: slide?.id || `plan-${index + 1}`,
			type: slide?.type || 'component',
			title: slide?.title || `投影片 ${index + 1}`,
			subtitle: slide?.summary || '',
			focusComponentId: slide?.focus_component_id || undefined,
			chartType: slide?.chart_type || undefined,
			durationSec: Number(slide?.duration_sec) > 0 ? Number(slide.duration_sec) : 12,
		}))
		: [];

	const blocks = Array.isArray(displayPlan.blocks)
		? displayPlan.blocks.map((block) => ({
			type: block?.type || 'component',
			title: block?.title || '未命名區塊',
			componentId: block?.component_id,
			componentIndex: block?.component_index,
			city: block?.city || safeComponents[0]?.city || 'taipei',
			chartType: block?.chart_type || displayPlan.chart_preference || 'auto',
			summary: block?.summary || '',
		}))
		: [];

	const sceneTitle = String(question || '').trim()
		? `AI 展示規劃：${String(question).slice(0, 30)}`
		: 'AI 展示規劃';

	return {
		version: '1.0',
		title: sceneTitle,
		objective: '由 AI Agent 產生展示策略與播放順序',
		layout: {
			type: 'split',
			leftPanel: {
				collapsed: false,
				width: 380,
			},
			rightPanel: {
				mode,
			},
		},
		presentation: {
			style: typeof displayPlan.style === 'string' ? displayPlan.style : 'carousel',
			autoplay: {
				enabled: mode === 'presentation',
				intervalMs: 10000,
			},
			audience: displayPlan.audience || 'public-screen',
			industry: 'general',
			strictRender: Boolean(displayPlan.strict_render),
			slides,
		},
		blocks,
		meta: {
			city: safeComponents[0]?.city || 'taipei',
			theme: 'default',
			updatedAt: new Date().toISOString(),
		},
	};
};

// ═══════════════════════════════════════════════════════════════════
// TWAI API 相關
// ═══════════════════════════════════════════════════════════════════

export const buildTwaiMessages = (latestUserInput, chatHistory = [], includeHistory = true) => {
	const systemPrompt =
		'你是臺北城市儀表板小幫手。回覆對象是一般使用者，不是工程師。若使用者在查某個指標、圖表、組件或想看資料，必須先呼叫 retrieve_components_by_query，再呼叫 get_component_chart_data 取得實際資料後才能回答。當問題涉及數值、比較、趨勢、最近變化時，答案一定要帶出具體數值與對應時間區間。組件推薦時若有 2 筆以上結果，請使用 Markdown 表格，欄位包括「排名｜城市名｜組件名｜數值」；「數值」欄位請根據工具回傳的數據填充。不要暴露 RAG、tool、score、index、id、主結果、候選、檢索排序等中繼資訊。';

	if (!includeHistory) {
		return [
			{
				role: 'system',
				content: systemPrompt,
			},
			{ role: 'user', content: latestUserInput },
		];
	}

	const recent = chatHistory
		.filter((item) => !item.isDefault && (item.role === 'user' || item.role === 'bot'))
		.slice(-MAX_CONTEXT_MESSAGES)
		.map((item) => ({
			role: item.role === 'user' ? 'user' : 'assistant',
			content: item.content || '',
		}))
		.filter((item) => item.content.trim().length > 0);

	if (!recent.length || recent[recent.length - 1].role !== 'user') {
		recent.push({ role: 'user', content: latestUserInput });
	}

	return [
		{
			role: 'system',
			content: systemPrompt,
		},
		...recent,
	];
};

export const stripDisplayPlanBlock = (content = '') => {
	const text = String(content || '').trim();
	if (!text) return '';

	const jsonFenceIndex = text.indexOf('```json');
	if (jsonFenceIndex >= 0) {
		const prefix = text.slice(0, jsonFenceIndex).trim();
		if (prefix) return prefix;
	}

	const modeIndex = text.indexOf('"mode"');
	if (modeIndex > 0) {
		const braceIndex = text.lastIndexOf('{', modeIndex);
		if (braceIndex >= 0) {
			const prefix = text.slice(0, braceIndex).trim();
			if (prefix) return prefix;
		}
	}

	return text;
};

export const queryByTwai = async (question, chatHistory = [], options = {}) => {
	const shouldRetry = (error) => {
		const status = error?.response?.status;
		if (!status) return true;
		return [408, 429, 500, 502, 503, 504].includes(status);
	};

	const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

	const createPayload = (includeHistory = true) => ({
		session: getTwaiSessionId(),
		app_mode: options.appMode || '',
		stream: false,
		messages: buildTwaiMessages(question, chatHistory, includeHistory),
		max_new_tokens: includeHistory ? 512 : 256,
		temperature: 0.35,
		tools: [
			{
				type: 'function',
				function: {
					name: 'retrieve_components_by_query',
					description: 'Retrieve relevant Taipei dashboard components by vector similarity search',
					parameters: {
						type: 'object',
						properties: {
							query: { type: 'string' },
							limit: { type: 'integer', minimum: 1, maximum: 10 },
							score: { type: 'number', minimum: 0, maximum: 1 },
						},
						required: ['query'],
					},
				},
			},
			{
				type: 'function',
				function: {
					name: 'get_component_chart_data',
					description: 'Get chart data for a dashboard component by component_id and city',
					parameters: {
						type: 'object',
						properties: {
							component_id: { type: 'integer' },
							city: { type: 'string', enum: ['taipei', 'metrotaipei'] },
							time_from: { type: 'string', description: 'ISO-8601 time format, e.g. 2026-04-01T00:00:00+08:00' },
							time_to: { type: 'string', description: 'ISO-8601 time format, e.g. 2026-04-24T23:59:59+08:00' },
						},
						required: ['component_id'],
					},
				},
			},
			{
				type: 'function',
				function: {
					name: 'get_current_time',
					description: 'Get current Taipei time',
					parameters: {
						type: 'object',
						properties: {},
					},
				},
			},
			{
				type: 'function',
				function: {
					name: 'get_population_summary',
					description: 'Get city population summary for specified year',
					parameters: {
						type: 'object',
						properties: {
							city: { type: 'string', enum: ['taipei', 'new_taipei'] },
							year: { type: 'integer' },
						},
						required: ['year'],
					},
				},
			},
		],
		tool_choice: 'auto',
	});

	try {
		const payload = createPayload(true);
		let response = null;
		let lastError = null;

		for (let attempt = 0; attempt <= TWAI_MAX_RETRY; attempt++) {
			try {
				response = await http.post('/ai/chat/twai', payload);
				break;
			} catch (error) {
				lastError = error;
				if (attempt >= TWAI_MAX_RETRY || !shouldRetry(error)) {
					throw error;
				}
				await wait(300 * (attempt + 1));
			}
		}

		if (!response?.data?.data) {
			if (lastError) throw lastError;
			return { ok: false, reason: 'EMPTY_RESPONSE' };
		}

		const { content } = response.data.data;
		const answerMode = response.data.data.answer_mode || 'agent_chat';
		const tools = Array.isArray(response.data.data.tools) ? response.data.data.tools : [];
		const agentResult = response.data.data.agent_result || null;
		const displayPlan = response.data.data.display_plan || null;

		if (!content || !String(content).trim()) {
			return { ok: false, reason: 'EMPTY_CONTENT' };
		}

		const cleanContent = stripDisplayPlanBlock(String(content));
		return {
			ok: true,
			content: cleanContent || String(content),
			answerMode,
			tools,
			toolTimeline: response.data.data.tool_timeline || [],
			agentResult,
			displayPlan,
			meta: {
				latency_ms: response.data.data.latency_ms,
				model: response.data.data.model,
				usage: response.data.data.usage,
			},
		};
	} catch (error) {
		const status = error?.response?.status;
		const reason = status ? `HTTP_${status}` : 'NETWORK_OR_TIMEOUT';
		console.error('TwaiChatError:', reason, error);

		try {
			const minimalResp = await http.post('/ai/chat/twai', createPayload(false));
			const minimalContent = minimalResp?.data?.data?.content;
			const minimalAnswerMode = minimalResp?.data?.data?.answer_mode || 'agent_chat';
			const minimalTools = Array.isArray(minimalResp?.data?.data?.tools) ? minimalResp.data.data.tools : [];
			const minimalAgentResult = minimalResp?.data?.data?.agent_result || null;
			const minimalDisplayPlan = minimalResp?.data?.data?.display_plan || null;
			if (minimalContent && String(minimalContent).trim()) {
				const cleanMinimalContent = stripDisplayPlanBlock(String(minimalContent));
				return {
					ok: true,
					content: cleanMinimalContent || String(minimalContent),
					answerMode: minimalAnswerMode,
					tools: minimalTools,
					agentResult: minimalAgentResult,
					displayPlan: minimalDisplayPlan,
				};
			}
		} catch (minimalError) {
			console.error('TwaiChatMinimalContextError:', minimalError);
		}

		return { ok: false, reason };
	}
};

// ═══════════════════════════════════════════════════════════════════
// 向量檢索 API
// ═══════════════════════════════════════════════════════════════════

export const queryByVector = async (question) => {
	try {
		const scoreCandidates = [0.8, 0.78, 0.72];

		for (const score of scoreCandidates) {
			const response = await http.post(
				"/vector/component",
				new URLSearchParams({
					query: question,
					limit: 10,
					score,
				}),
				{
					headers: {
						"Content-Type": "application/x-www-form-urlencoded",
					},
				}
			);

			if (response.data?.data?.length > 0) {
				let results = response.data.data.filter(isOfficialComponent);

				// 去除重複項目存到 result
				const deduplicated = Array.from(
					results.reduce((map, item) => {
						const key = item.index;
						const exist = map.get(key);

						// 如果還沒放過，直接放
						if (!exist) {
							map.set(key, item);
							return map;
						}

						// 如果已存在，但現在的是 metrotaipei，就覆蓋
						if (item.city === 'metrotaipei') {
							map.set(key, item);
						}

						return map;
					}, new Map()).values()
				);

				return deduplicated.sort((a, b) => b.score - a.score);
			}
		}

		return [];
	} catch (error) {
		console.error("VectorAnalysisError :", error);
		return [];
	}
};

// ═══════════════════════════════════════════════════════════════════
// 日誌記錄
// ═══════════════════════════════════════════════════════════════════

export const saveChatLog = async (question, answer, meta = {}) => {
	try {
		const formData = new FormData();
		const d = new Date();
		const todayId =
			d.getFullYear() +
			String(d.getMonth() + 1).padStart(2, "0") +
			String(d.getDate()).padStart(2, "0");

		formData.append("session", "session_" + todayId);
		formData.append("question", question);
		formData.append("answer", JSON.stringify(answer));
		formData.append("answer_mode", meta.answerMode || "unknown");
		formData.append("used_tools", JSON.stringify(Array.isArray(meta.usedTools) ? meta.usedTools : []));

		await http.post("/chatlog/", formData, {
			headers: {
				"Content-Type": "multipart/form-data",
			},
		});
	} catch (error) {
		console.error("saveChatLog error:", error);
	}
};
