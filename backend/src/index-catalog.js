import { Supabase } from './supabase.js';
import { embeddingConsulta } from './agent.js';

const { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY, OPENAI_API_KEY, OPENAI_EMBEDDING_MODEL = 'text-embedding-3-small' } = process.env;
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !SUPABASE_ANON_KEY || !OPENAI_API_KEY) {
  console.error('Faltan SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY u OPENAI_API_KEY.'); process.exit(1);
}
const db = new Supabase({ url: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY, anonKey: SUPABASE_ANON_KEY });
const pendientes = await db.documentosPendientes();
for (const documento of pendientes) {
  const embedding = await embeddingConsulta({ apiKey: OPENAI_API_KEY, model: OPENAI_EMBEDDING_MODEL, query: documento.contenido });
  if (!embedding) throw new Error(`No se generó embedding para ${documento.negocio_id}`);
  await db.actualizarEmbedding(documento.negocio_id, embedding);
  console.log(`Indexado negocio ${documento.negocio_id}`);
}
console.log(`${pendientes.length} documento(s) indexado(s).`);
