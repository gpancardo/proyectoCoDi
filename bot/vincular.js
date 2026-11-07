// Vincula el WhatsApp del bot sin necesitar ninguna otra llave: npm run vincular
// Con BOT_PHONE (con 52, sin +) da un código de 8 caracteres; sin él, un QR. La sesión queda en bot/auth/.
import makeWASocket, { useMultiFileAuthState, DisconnectReason } from 'baileys'
import qrcode from 'qrcode-terminal'
import pino from 'pino'

const telefono = process.env.BOT_PHONE?.replace(/\D/g, '')
let pidiendoCodigo = false

async function conectar(primera) {
  const { state, saveCreds } = await useMultiFileAuthState('auth')
  if (primera && state.creds.registered) {
    console.log('Este número ya está vinculado (bot/auth/). Corre npm start.')
    process.exit(0)
  }
  const sock = makeWASocket({ auth: state, logger: pino({ level: 'silent' }) })
  sock.ev.on('creds.update', saveCreds)
  sock.ev.on('connection.update', ({ connection, lastDisconnect, qr }) => {
    if (qr && telefono) {
      if (pidiendoCodigo) return
      pidiendoCodigo = true
      sock.requestPairingCode(telefono).then((c) => console.log(
        `\nCódigo de vinculación: ${c.match(/.{1,4}/g).join('-')}\n\nEn el celular del bot: WhatsApp > Dispositivos vinculados > Vincular un dispositivo > Vincular con el número de teléfono, y escribe el código.\n`,
      )).catch((e) => { pidiendoCodigo = false; console.error('No se pudo pedir el código:', e.message) })
    } else if (qr) {
      console.log('\nEscanea con el celular del bot: WhatsApp > Dispositivos vinculados > Vincular un dispositivo\n')
      qrcode.generate(qr, { small: true })
    }
    if (connection === 'open') {
      console.log('\nVinculado. Corre npm start.\n')
      setTimeout(() => process.exit(0), 3000) // deja que se guarden las credenciales
    }
    if (connection === 'close') {
      if (lastDisconnect?.error?.output?.statusCode === DisconnectReason.loggedOut) {
        console.error('WhatsApp rechazó la vinculación. Borra bot/auth/ e inténtalo otra vez.')
        process.exit(1)
      }
      pidiendoCodigo = false // WhatsApp reinicia la conexión justo después de vincular: se reconecta sola
      setTimeout(() => conectar(false), 1000)
    }
  })
}

conectar(true)
