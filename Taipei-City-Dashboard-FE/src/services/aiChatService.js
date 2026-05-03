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
	// 主要組件遠勝其餘時，縮減 related 數量以避免顯示不相關組件
	const limit = dominant ? 2 : (directIntent ? 3 : 4);

	return ranked.slice(0, limit).map((item, idx) => ({
		...item,
		isPrimary: idx === 0,
	}));
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

// 從 AI Markdown 表格中擷取指定組件名的「數值」欄
// 表格格式：排名 | 城市名 | 組件名 | 數值  → cells[0]、cells[1]、cells[2]、cells[3]
const extractValueFromTable = (aiContent, componentName) => {
	const allRows = (aiContent.match(/^\|[^\n]+\|$/gm) || []);
	const dataRows = allRows
		.filter(row => !/^\|[\s|:-]+\|$/.test(row)) // 排除 separator row
		.slice(1); // 排除 header row
	for (const row of dataRows) {
		const cells = row.split('|').map(c => c.trim()).filter(Boolean);
		if (cells.length >= 3 && cells[2] === componentName) {
			return cells.length >= 4 ? cells[3] : null;
		}
	}
	return null;
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

	// 偵測 AI 表格是否「過包含」：即 AI 表格內的資料列數 > 我們已過濾的 components 數量
	// Pattern：對比 Markdown pipe 表格中的 data rows（排除 separator 列、排除 header 列）
	const allPipeRows = (normalizedAiContent.match(/^\|[^\n]+\|$/gm) || []);
	const contentPipeRows = allPipeRows.filter(row => !/^\|[\s|:-]+\|$/.test(row));
	const aiTableDataCount = Math.max(0, contentPipeRows.length - 1); // 減去 header row
	const tableIsOverInclusive = aiTableDataCount > 0 && aiTableDataCount > list.length;

	// 僅將有關鍵字相關性（__matchScore ≥ 20）的組件列為「延伸推薦」，排除純向量相似但語意無關的組件
	const keywordRelated = related.filter((item) => (item?.__matchScore ?? 0) >= 20);
	const relatedHint = summarizeRelatedComponents(keywordRelated);

	const CLOSING = '若有其他問題，歡迎繼續詢問！';

	if (genericAiReply || tableIsOverInclusive) {
		// 若表格過包含，嘗試從 AI 表格擷取 primary 組件的實際數值（保留有用資訊）
		const primaryValue = tableIsOverInclusive && primary?.name
			? extractValueFromTable(normalizedAiContent, primary.name)
			: null;
		const valuePart = primaryValue ? `（最新數值：${primaryValue}\uff09` : '';
		const intro = `您好！根據您關於「${question}」的查詢，為您找到最相關的指標：`;
		const mainDesc = shortDesc
			? `**${primary?.name || '相關指標'}**${valuePart}：${shortDesc}。`
			: `**${primary?.name || '相關指標'}**${valuePart} 最能直接回應您的查詢。`;
		return [intro, mainDesc, relatedHint, CLOSING].filter(Boolean).join('\n\n');
	}

	// 若 AI 回覆未以親切語句開頭（如直接從表格開始），補上開場引語
	const hasNaturalOpening = /^(您好|根據|以下|我已|很高興|這裡|依據|幫您)/.test(normalizedAiContent);
	const prefix = hasNaturalOpening ? '' : `根據您的查詢，以下是相關資訊：\n\n`;

	// 避免重複：若 AI 已提及「延伸比較」建議，不再附加
	const alreadyHasHint = /若您要延伸比較|延伸比較/.test(normalizedAiContent);
	const hint = alreadyHasHint ? '' : relatedHint;

	// 若 AI 回覆無鼓勵性結語，自動附加
	const hasClosing = /歡迎繼續|若有.*問題|希望.*幫助|有任何疑問|隨時.*詢問/.test(normalizedAiContent);
	const closing = hasClosing ? '' : CLOSING;

	return [prefix + normalizedAiContent, hint, closing].filter(Boolean).join(' ');
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
			mapQuery: slide?.map_query || '',
			mapLng: Number.isFinite(Number(slide?.map_lng)) ? Number(slide.map_lng) : undefined,
			mapLat: Number.isFinite(Number(slide?.map_lat)) ? Number(slide.map_lat) : undefined,
			bullets: Array.isArray(slide?.bullets) ? slide.bullets : [],
			highlight: slide?.highlight || '',
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
		'你是臺北城市儀表板小幫手。回覆對象是一般使用者，不是工程師。' +
		'若使用者在查某個指標、圖表、組件或想看資料，必須先呼叫 retrieve_components_by_query，再呼叫 get_component_chart_data 取得實際資料後才能回答。' +
		'當問題涉及數值、比較、趨勢、最近變化時，答案一定要帶出具體數值與對應時間區間。' +
		'重要：若 retrieve_components_by_query 回傳結果為空（count 為 0 或 results 為空陣列），請直接告知使用者「目前找不到與您查詢相關的儀表板組件」，並建議換用不同關鍵詞重試，絕對不可捏造不存在的組件名稱或數值。' +
		'若第一次搜尋無結果，可嘗試降低 score 至 0.75 再搜尋一次。' +
		'主題相關性自我檢查：收到 retrieve_components_by_query 結果後，必須逐一判斷每個組件是否與使用者查詢主題直接相關。若某組件名稱或描述顯然屬於不同主題領域（例如：查詢「交通」卻出現「空氣品質測站」；查詢「年齡分布」卻出現「地圖測站」；查詢「人口」卻出現「水質監測」），必須將該組件從推薦清單中完全排除，不得列入表格、不得呼叫其 get_component_chart_data，也不得在回覆文字中提及。' +
		'組件推薦時若達條件且有 2 筆以上相關結果，請使用 Markdown 表格，欄位包括「排名｜城市名｜組件名｜數值」；「數值」欄位請根據工具回傳的數據填充，若尚未取得數值請留空而非填寫估算值。' +
		'不要暴露 RAG、tool、score、index、id、主結果、候選、檢索排序等中繼資訊。' +
		'每次回覆必須以親切的開場白開始（例如「您好！」），並以一句鼓勵繼續詢問的結語作結（例如「若有其他問題，歡迎繼續詢問！」）；回覆中不要自行加入「若您要延伸比較」的建議，系統已自動附加。';

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

	// For AI Studio follow-up queries: inject current scene state so the AI knows
	// which slides already exist and can intelligently modify/extend the scene
	// rather than starting from scratch every time.
	const contextualQuestion = (() => {
		if (options.appMode !== 'ai_studio' || !options.sceneContext) return question;
		const slides = options.sceneContext?.presentation?.slides;
		if (!Array.isArray(slides) || slides.length === 0) return question;
		const compSlides = slides.filter(s => s.type === 'component' || s.type === 'map');
		if (compSlides.length === 0) return question;
		const summary = compSlides
			.slice(0, 6)
			.map(s => `"${s.title}"(component_id:${s.focusComponentId || '?'})`)
			.join('、');
		return `[現有展示場景：共${slides.length}張投影片，圖表類：${summary}]\n${question}`;
	})();

	const createPayload = (includeHistory = true) => ({
		session: getTwaiSessionId(),
		app_mode: options.appMode || '',
		stream: false,
		messages: buildTwaiMessages(includeHistory ? contextualQuestion : question, chatHistory, includeHistory),
		max_new_tokens: includeHistory ? 1500 : 700,
		temperature: options.appMode === 'ai_studio' ? 0.5 : 0.35,
		tools: [
			{
				type: 'function',
				function: {
					name: 'retrieve_components_by_query',
					description:
						'Search Taipei City Dashboard components by natural language query using vector similarity. ' +
						'ALWAYS call this tool FIRST whenever the user asks about any city data, metrics, indicators, statistics, trends, comparisons, or wants to see a chart. ' +
						'Returns a list of matching components. IMPORTANT FIELDS in each result: ' +
						'(1) id — use as focus_component_id in display_plan slides; ' +
						'(2) chart_types — the EXACT strings you MUST use in the chart_type field of display_plan (e.g. "BarChart", "ColumnChart", "DonutChart", "map_legend"); ' +
						'(3) has_map — ONLY set slide type="map" when this is true; if false, always use type="component". ' +
						'If this returns 0 results, inform the user no matching components were found and suggest rephrasing. ' +
						'Use descriptive Chinese keywords for best results (e.g. "空氣品質", "交通流量", "老年人口").',
					parameters: {
						type: 'object',
						properties: {
							query: {
								type: 'string',
								description: 'Natural language description of the data topic in Chinese or English, e.g. "空氣品質 AQI" or "交通壅塞 車流量"',
							},
							limit: {
								type: 'integer',
								minimum: 1,
								maximum: 10,
								description: 'Number of components to return (default 5, max 10)',
							},
							score: {
								type: 'number',
								minimum: 0,
								maximum: 1,
								description: 'Minimum similarity score threshold between 0.75 and 0.88 (default 0.82). Lower this to 0.75 if first search returns 0 results.',
							},
						},
						required: ['query'],
					},
				},
			},
			{
				type: 'function',
				function: {
					name: 'get_component_chart_data',
					description:
						'Fetch actual chart data (numbers, time-series, categories) for a specific dashboard component. ' +
						'Must be called AFTER retrieve_components_by_query to obtain the component_id. ' +
						'Required for answering questions that need precise numbers, recent trends, or comparisons. ' +
						'Returns a summary field with the latest value for quick table filling. ' +
						'Defaults to last 30 days if no time range is specified.',
					parameters: {
						type: 'object',
						properties: {
							component_id: {
								type: 'integer',
								description: 'Component ID obtained from retrieve_components_by_query results',
							},
							city: {
								type: 'string',
								enum: ['taipei', 'metrotaipei'],
								description: '"taipei" for Taipei City data, "metrotaipei" for greater Taipei area data. Match the city field from retrieve results.',
							},
							time_from: {
								type: 'string',
								description: 'Start of time range in ISO-8601 format e.g. 2026-03-01T00:00:00+08:00. Omit to default to 30 days ago.',
							},
							time_to: {
								type: 'string',
								description: 'End of time range in ISO-8601 format e.g. 2026-04-30T23:59:59+08:00. Omit to default to current time.',
							},
						},
						required: ['component_id'],
					},
				},
			},
			{
				type: 'function',
				function: {
					name: 'get_current_time',
					description:
						'Get the current date and time in Taipei (Asia/Taipei timezone, UTC+8). ' +
						'Call this when the user asks about current time, or when you need to compute relative date ranges for data queries.',
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
					description:
						'Get annual population age distribution statistics (young/working-age/elderly) for Taipei or New Taipei City. ' +
						'Use for demographic questions about population structure, aging index, dependency ratio, or elderly care needs.',
					parameters: {
						type: 'object',
						properties: {
							city: {
								type: 'string',
								enum: ['taipei', 'new_taipei'],
								description: '"taipei" for Taipei City, "new_taipei" for New Taipei City',
							},
							year: {
								type: 'integer',
								description: 'Year of population data (e.g. 2024, 2025)',
							},
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
		// 重用 TWAI session ID，確保同一瀏覽器 session 的日誌可追溯
		const sessionId = getTwaiSessionId();

		formData.append("session", sessionId);
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
