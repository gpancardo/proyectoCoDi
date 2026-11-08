// Única configuración de la web. La llave PUBLICABLE es pública por diseño: la protege RLS y solo
// permite dar de alta negocios. NUNCA pongas aquí una llave secreta (sb_secret_...).
window.BARRIO = {
  SUPABASE_URL: 'https://bjbfcxodapjaudawlsvg.supabase.co',
  SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_NgLPAn_eJDSyvkXrNVAhrA_VvAAoSYz',
  API_URL: 'https://bjbfcxodapjaudawlsvg.supabase.co/functions/v1/api', // API de Barrio (Edge Function); nunca llaves secretas aquí
  BOT: '5200000000000', // WhatsApp del bot, con 52 y sin +. Se llena al vincular el número.
}
