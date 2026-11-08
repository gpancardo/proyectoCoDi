import { embeddingConsulta } from './agent.js';

// Genera el vector de los negocios cuyo catálogo cambió (el trigger de la base los deja en null).
// Se llama al buscar (pocos a la vez) y desde `npm run index:catalog` (todos), así el RAG nunca queda desactualizado.
export async function indexarPendientes(db, { apiKey, model, limite = 5 }) {
  if (!apiKey) return 0;
  let hechos = 0;
  for (const d of (await db.documentosPendientes()).slice(0, limite)) {
    const embedding = await embeddingConsulta({ apiKey, model, query: d.contenido });
    if (!embedding) continue;
    await db.actualizarEmbedding(d.negocio_id, embedding);
    hechos++;
  }
  return hechos;
}
