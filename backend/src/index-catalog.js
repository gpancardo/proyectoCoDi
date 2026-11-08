import { Supabase } from './supabase.js';
import { indexarPendientes } from './indexar.js';

const { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY, OPENAI_API_KEY, OPENAI_EMBEDDING_MODEL = 'text-embedding-3-small' } = process.env;
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !SUPABASE_ANON_KEY || !OPENAI_API_KEY) {
  console.error('Faltan SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY u OPENAI_API_KEY.'); process.exit(1);
}
const db = new Supabase({ url: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY, anonKey: SUPABASE_ANON_KEY });
const n = await indexarPendientes(db, { apiKey: OPENAI_API_KEY, model: OPENAI_EMBEDDING_MODEL, limite: 100 });
console.log(`${n} documento(s) indexado(s).`);
