// Aplica las plantillas a Supabase Auth con la Management API.
// Uso: SUPABASE_ACCESS_TOKEN=sbp_... node supabase/emails/aplicar.mjs   (token personal: supabase.com/dashboard/account/tokens)
import { PLANTILLAS } from './generar.mjs';

const REF = process.env.SUPABASE_PROJECT_REF ?? 'bjbfcxodapjaudawlsvg';
const token = process.env.SUPABASE_ACCESS_TOKEN;
if (!token) { console.error('Falta SUPABASE_ACCESS_TOKEN.'); process.exit(1); }
const c = PLANTILLAS.confirmacion, r = PLANTILLAS.recuperacion;
const res = await fetch(`https://api.supabase.com/v1/projects/${REF}/config/auth`, {
  method: 'PATCH', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({ mailer_subjects_confirmation: c.asunto, mailer_templates_confirmation_content: c.html,
    mailer_subjects_recovery: r.asunto, mailer_templates_recovery_content: r.html }),
});
console.log(res.status, res.ok ? 'plantillas aplicadas' : await res.text());
process.exitCode = res.ok ? 0 : 1;
