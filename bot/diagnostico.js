// Revisa que todo esté conectado antes de arrancar: npm run diagnostico
import OpenAI from 'openai'
import { createClient } from '@supabase/supabase-js'
import { existsSync, readFileSync } from 'node:fs'
import { MODELO, TRANSCRIPCION, VOZ, EMBEDDINGS, SUPABASE_KEY } from './config.js'

let fallas = 0
const ok = (t) => console.log(`  OK     ${t}`)
const aviso = (t) => console.log(`  AVISO  ${t}`)
const falla = (t, ayuda) => { fallas++; console.log(`  FALLA  ${t}${ayuda ? `\n         ${ayuda}` : ''}`) }
async function revisar(nombre, fn) {
  try { ok(`${nombre}${(await fn()) ?? ''}`) } catch (e) { falla(nombre, e.message) }
}

const { OPENAI_API_KEY, SUPABASE_URL, PEY_API_KEY, PEY_MOCK, BOT_PHONE } = process.env

console.log('\nVariables (bot/.env)')
const faltan = [
  [OPENAI_API_KEY, 'OPENAI_API_KEY', 'Llave de platform.openai.com > API keys'],
  [SUPABASE_URL, 'SUPABASE_URL', 'Project URL de Supabase (Settings > API Keys)'],
  [SUPABASE_KEY, 'SUPABASE_SECRET_KEY', 'Llave secreta de Supabase: Settings > API Keys > Secret keys > Copy'],
].filter(([v]) => !v)
for (const [, nombre, ayuda] of faltan) falla(`Falta ${nombre}`, ayuda)
if (!faltan.length) ok('OPENAI_API_KEY, SUPABASE_URL y SUPABASE_SECRET_KEY presentes')
if (SUPABASE_KEY && !SUPABASE_KEY.startsWith('sb_secret_') && !SUPABASE_KEY.startsWith('eyJ')) falla('SUPABASE_SECRET_KEY no parece una llave secreta', 'Debe empezar con sb_secret_ (no uses la publicable)')

if (SUPABASE_URL && SUPABASE_KEY) {
  console.log('\nSupabase')
  const db = createClient(SUPABASE_URL, SUPABASE_KEY)
  for (const tabla of ['compradores', 'negocios', 'ordenes']) {
    await revisar(`Tabla ${tabla}`, async () => {
      const { error, count } = await db.from(tabla).select(tabla === 'ordenes' ? 'id, pey_via' : 'id', { count: 'exact' }).limit(1) // sin HEAD: así el error trae su motivo
      if (error) throw new Error(error.code === '42501'
        ? 'Sin permisos: ¿es la llave secreta y corriste la migración completa (incluye los GRANT a service_role)?'
        : error.code === '42P01' ? 'No existe: corre supabase/migrations/…_init.sql'
        : error.code === '42703' ? 'Falta una columna: corre las migraciones de supabase/migrations/ en orden' : error.message)
      return ` (${count} filas)`
    })
  }
  await revisar('Búsqueda match_negocios', async () => {
    const { error } = await db.rpc('match_negocios', { q: Array(1536).fill(0) })
    if (error) throw new Error(error.message)
  })
  await revisar('Realtime (avisos de pago al instante)', () => new Promise((listo, no) => {
    const ch = db.channel('diagnostico').on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'ordenes' }, () => {})
    let terminado = false // removeChannel vuelve a disparar el callback con CLOSED: sin esto se llama a sí mismo
    const fin = (fn, v) => { if (terminado) return; terminado = true; clearTimeout(t); db.removeChannel(ch); fn(v) }
    const t = setTimeout(() => fin(no, new Error('Sin respuesta en 10 s. El bot igual avisa los pagos, con hasta 30 s de retraso.')), 10e3)
    ch.subscribe((estado, err) => {
      if (estado === 'SUBSCRIBED') fin(listo)
      else if (['CHANNEL_ERROR', 'TIMED_OUT', 'CLOSED'].includes(estado)) fin(no, new Error(`${estado} ${err?.message ?? ''}. El bot igual avisa los pagos, con hasta 30 s de retraso.`))
    })
  }))
}

if (OPENAI_API_KEY) {
  console.log('\nOpenAI')
  const openai = new OpenAI({ timeout: 30e3, maxRetries: 0 })
  for (const [uso, modelo] of [['Agente', MODELO], ['Transcripción', TRANSCRIPCION], ['Voz', VOZ], ['Embeddings', EMBEDDINGS]]) {
    await revisar(`${uso}: ${modelo}`, async () => {
      try { await openai.models.retrieve(modelo) } catch (e) {
        throw new Error(e.status === 401 ? 'Llave de OpenAI inválida'
          : e.status === 404 ? `Tu cuenta no tiene ${modelo}${uso === 'Agente' ? '. Prueba con OPENAI_MODEL=gpt-5-mini en bot/.env' : ''}` : e.message)
      }
    })
  }
  await revisar('Llamada real del agente (Responses API, razonamiento bajo)', async () => {
    await openai.responses.create({ model: MODELO, reasoning: { effort: 'low' }, input: 'Responde solo: ok', max_output_tokens: 64 })
  })
  await revisar('Embedding de 1536 dimensiones', async () => {
    const n = (await openai.embeddings.create({ model: EMBEDDINGS, input: 'tacos' })).data[0].embedding.length
    if (n !== 1536) throw new Error(`Devolvió ${n}; la tabla espera 1536`)
  })
}

console.log('\npey')
if (PEY_MOCK === '1') aviso('PEY_MOCK=1: los cobros son falsos. Para cobrar de verdad pon PEY_API_KEY y quita PEY_MOCK.')
else if (!PEY_API_KEY) falla('Falta PEY_API_KEY', 'Créala en portal.mipey.mx > Desarrollador, o usa PEY_MOCK=1 para probar sin ella')
else {
  await revisar('API key de pey', async () => {
    const r = await fetch('https://api.pey.mx/transaction/api-key', { headers: { Authorization: `Bearer ${PEY_API_KEY}` }, signal: AbortSignal.timeout(15e3) })
    if (r.status === 401 || r.status === 403) throw new Error('pey rechazó la API key (¿es del entorno correcto?). Créala en portal.mipey.mx > Desarrollador')
    if (!r.ok) throw new Error(`pey respondió ${r.status}`)
  })
  aviso('Los cobros reales se prueban con un pedido de $0.01 (un centavo).')
}

console.log('\nWhatsApp')
const creds = 'auth/creds.json'
if (existsSync(creds) && JSON.parse(readFileSync(creds, 'utf8')).registered) ok('Número vinculado (bot/auth/)')
else aviso(`Sin vincular. Al hacer npm start ${BOT_PHONE ? `saldrá un código de 8 caracteres para ${BOT_PHONE}` : 'saldrá un QR'}.`)

console.log(fallas ? `\n${fallas} problema${fallas > 1 ? 's' : ''}. Corrígelos y vuelve a correr npm run diagnostico.\n` : '\nTodo listo. Corre npm start.\n')
process.exit(fallas ? 1 : 0)
