import test from 'node:test';
import assert from 'node:assert/strict';
import { interpretarConsulta, embeddingConsulta } from '../src/agent.js';

// Simula el proveedor: comprueba que OpenAI y OpenRouter reciben el mismo contrato con distinta URL base.
test('el agente usa chat/completions y la URL base configurada', async () => {
  const real = globalThis.fetch; const llamadas = [];
  globalThis.fetch = async (url, init) => { llamadas.push([String(url), JSON.parse(init.body)]); return { ok: true, json: async () => String(url).endsWith('/embeddings') ? { data: [{ embedding: [0.1, 0.2] }] } : { choices: [{ message: { content: JSON.stringify({ q: 'tacos', zone: null, category: 'Comida', open_now: true, min_amount_minor: null, max_amount_minor: null, answer: 'Busco tacos.' }) } }] } }; };
  try {
    for (const base of [undefined, 'https://openrouter.ai/api/v1/']) {
      if (base) process.env.OPENAI_BASE_URL = base; else delete process.env.OPENAI_BASE_URL;
      const f = await interpretarConsulta({ apiKey: 'k', model: 'm', query: 'tacos' });
      assert.equal(f.category, 'comida'); assert.deepEqual(await embeddingConsulta({ apiKey: 'k', model: 'e', query: 'x' }), [0.1, 0.2]);
    }
    assert.deepEqual(llamadas.map(([u]) => u), ['https://api.openai.com/v1/chat/completions', 'https://api.openai.com/v1/embeddings', 'https://openrouter.ai/api/v1/chat/completions', 'https://openrouter.ai/api/v1/embeddings']);
    assert.equal(llamadas[0][1].response_format.type, 'json_schema');
    assert.equal(await interpretarConsulta({ apiKey: '', model: 'm', query: 'tacos' }), null); // sin llave, sin modelo: búsqueda determinista
  } finally { globalThis.fetch = real; delete process.env.OPENAI_BASE_URL; }
});
