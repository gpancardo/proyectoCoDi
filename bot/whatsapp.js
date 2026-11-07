// Opciones de conexión de Baileys compartidas por index.js y vincular.js.
import { fetchLatestBaileysVersion, Browsers } from 'baileys'

export async function opcionesSocket(auth, logger) {
  // La versión de WhatsApp Web viene fija dentro de Baileys y se vuelve vieja: una versión vieja es la causa
  // más común de que WhatsApp rechace la conexión. Se pide la actual; si falla, se usa la incluida.
  let version
  try { ({ version } = await fetchLatestBaileysVersion({ signal: AbortSignal.timeout(8e3) })) } catch { /* sin red a GitHub: la versión incluida */ }
  return {
    auth, logger,
    ...(version && { version }),
    browser: Browsers.macOS('Chrome'), // con un navegador de escritorio reconocido, el código de vinculación funciona
    markOnlineOnConnect: false,         // el bot no debe silenciar las notificaciones del celular
  }
}
