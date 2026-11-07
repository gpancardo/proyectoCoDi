// Configuración compartida por el bot (index.js), el diagnóstico (diagnostico.js) y vincular.js.
// Modelos verificados contra el SDK de OpenAI instalado (openai@7.53).

// Agente: el mini más reciente del SDK (rápido y barato, buen manejo de herramientas).
// Si tu cuenta de OpenAI no lo tiene: OPENAI_MODEL=gpt-5-mini en bot/.env
export const MODELO = process.env.OPENAI_MODEL || 'gpt-5.4-mini'
export const TRANSCRIPCION = 'gpt-4o-mini-transcribe' // notas de voz → texto
export const VOZ = 'gpt-4o-mini-tts'                  // texto → nota de voz
export const EMBEDDINGS = 'text-embedding-3-small'    // 1536 dimensiones: coincide con supabase/migrations

// Llave secreta de Supabase (sb_secret_...). SUPABASE_SERVICE_ROLE_KEY se acepta por compatibilidad.
export const SUPABASE_KEY = process.env.SUPABASE_SECRET_KEY ?? process.env.SUPABASE_SERVICE_ROLE_KEY
