// Única configuración de la web. La anon key es pública por diseño (la protege RLS):
// solo permite dar de alta negocios. NUNCA pongas aquí la service_role key.
window.BARRIO = {
  SUPABASE_URL: 'https://TU-PROYECTO.supabase.co',
  SUPABASE_ANON_KEY: 'PEGA-AQUI-LA-ANON-KEY',
  BOT: '5200000000000', // WhatsApp del bot, con 52 y sin +
}
