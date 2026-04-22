import http from 'node:http';

function postJson(url, data) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(data);
    const req = http.request(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      },
      timeout: 120000,
    }, (res) => {
      let raw = '';
      res.setEncoding('utf8');
      res.on('data', (chunk) => (raw += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(raw);
          resolve({ status: res.statusCode, data: parsed });
        } catch (e) {
          resolve({ status: res.statusCode, raw, parseError: String(e) });
        }
      });
    });

    req.on('timeout', () => {
      req.destroy(new Error('Request timeout'));
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

const tools = [
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
      name: 'get_current_time',
      description: 'Get current Taipei time',
      parameters: { type: 'object', properties: {} },
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
];

const base = 'http://localhost:8088/api/v1/ai/chat/twai';
const session = 'session_repro_20260417';
const systemMessage = {
  role: 'system',
  content: '你是臺北城市儀表板小幫手。回答城市資料問題時，請先優先使用工具檢索再回答；若檢索無結果，需明確告知限制並提供下一步建議。',
};

const run = async () => {
  const turn1 = {
    session,
    stream: false,
    messages: [systemMessage, { role: 'user', content: 'HI' }],
    max_new_tokens: 512,
    temperature: 0.35,
    tools,
    tool_choice: 'auto',
  };

  const r1 = await postJson(base, turn1);
  console.log('TURN1 status=', r1.status, 'ok=', r1.data?.status, 'len=', (r1.data?.data?.content || '').length);

  const assistantReply = r1.data?.data?.content || '';

  const turn2 = {
    session,
    stream: false,
    messages: [
      systemMessage,
      { role: 'user', content: 'HI' },
      { role: 'assistant', content: assistantReply },
      { role: 'user', content: '調取扶養比' },
    ],
    max_new_tokens: 512,
    temperature: 0.35,
    tools,
    tool_choice: 'auto',
  };

  const r2 = await postJson(base, turn2);
  console.log('TURN2 status=', r2.status, 'ok=', r2.data?.status, 'len=', (r2.data?.data?.content || '').length);
  if (r2.parseError) {
    console.log('TURN2 parseError=', r2.parseError);
    console.log('TURN2 rawHead=', String(r2.raw).slice(0, 300));
  } else {
    console.log('TURN2 answerMode=', r2.data?.data?.answer_mode);
    console.log('TURN2 tools=', r2.data?.data?.tools);
    console.log('TURN2 contentHead=', String(r2.data?.data?.content || '').slice(0, 160));
  }
};

run().catch((e) => {
  console.error('REPRO_ERROR', e?.message || e);
  process.exit(1);
});
