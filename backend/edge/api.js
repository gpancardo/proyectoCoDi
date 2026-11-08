// Adaptador para Supabase Edge Functions (Deno): convierte Request/Response al req/res de node:http que usa server.js.
// `npm run build:edge` lo empaqueta en supabase/functions/api/index.ts. Se despliega con verify_jwt apagado (la API autentica sola).
import { manejarPeticion } from '../src/server.js';

Deno.serve(async (request) => {
  const url = new URL(request.url);
  // /api/api/v1/x (función "api") → /api/v1/x ; /api/webhooks/pey → /webhooks/pey
  const ruta = url.pathname.replace(/^(\/functions\/v1)?\/api(?=\/|$)/, '') || '/';
  const cuerpo = ['GET', 'HEAD', 'OPTIONS'].includes(request.method) ? '' : await request.text();
  const headers = Object.fromEntries([...request.headers].map(([k, v]) => [k.toLowerCase(), v]));
  const req = { method: request.method, url: ruta + url.search, headers: { ...headers, host: url.host }, async *[Symbol.asyncIterator]() { if (cuerpo) yield cuerpo; } };
  return await new Promise((resolve) => {
    let status = 200; let respHeaders = {};
    const res = { writeHead(s, h = {}) { status = s; respHeaders = h; }, end(texto = '') { resolve(new Response(status === 204 ? null : texto, { status, headers: respHeaders })); } };
    manejarPeticion(req, res).catch((e) => { console.error(e.message); resolve(new Response('error', { status: 500 })); });
  });
});
