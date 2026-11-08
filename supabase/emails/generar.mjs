// Plantillas de correo de Barrio para Supabase Auth: HTML con estilos en línea (los correos no cargan CSS ni fuentes externas),
// la paleta y la voz de docs/DESIGN.md y docs/VOZ-DE-MARCA.md. `node supabase/emails/generar.mjs` escribe los .html y una vista previa.
import { writeFileSync } from 'node:fs';

const C = { marino: '#0B2545', mango: '#F5A524', crema: '#FFF8EC', blanco: '#FFFFFF', tinta: '#1A1F2B', gris: '#5B6472', borde: '#E8DFCF', teal: '#0F7C75' };
const TITULO = "'Archivo','Arial Black','Helvetica Neue',Arial,sans-serif";
const TEXTO = "'Archivo','Helvetica Neue',Helvetica,Arial,sans-serif";

// Toldo: franjas mango y blancas, como en la landing
const toldo = Array.from({ length: 16 }, (_, i) => `<td width="6.25%" height="16" bgcolor="${i % 2 ? C.blanco : C.mango}" style="font-size:0;line-height:0;">&nbsp;</td>`).join('');
// Marca marimba: letras en teclas mango y blancas de alturas distintas
const alturas = [46, 36, 42, 34, 40, 36];
const marimba = [...'barrio'].map((l, i) =>
  `<td valign="bottom" style="padding:0 2px 0 0;"><table role="presentation" cellpadding="0" cellspacing="0"><tr><td align="center" valign="bottom" width="30" height="${alturas[i]}" bgcolor="${i % 2 ? C.blanco : C.mango}" style="font:800 24px/1 ${TITULO};color:${C.marino};padding-bottom:4px;">${l}</td></tr></table></td>`).join('');

function correo({ previa, titulo, parrafos, boton, nota }) {
  return `<!doctype html>
<html lang="es-MX"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="color-scheme" content="light"><meta name="supported-color-schemes" content="light"><title>${titulo}</title></head>
<body style="margin:0;padding:0;background:${C.crema};">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;color:${C.crema};">${previa}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" bgcolor="${C.crema}"><tr><td align="center" style="padding:24px 12px;">
  <table role="presentation" width="560" cellpadding="0" cellspacing="0" style="width:100%;max-width:560px;border:2px solid ${C.marino};border-radius:8px;overflow:hidden;" bgcolor="${C.blanco}">
    <tr><td><table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>${toldo}</tr></table></td></tr>
    <tr><td bgcolor="${C.marino}" style="padding:28px 32px 0 32px;border-top:2px solid ${C.marino};"><table role="presentation" cellpadding="0" cellspacing="0"><tr>${marimba}</tr></table></td></tr>
    <tr><td style="padding:28px 32px 0 32px;font:800 34px/1.05 ${TITULO};color:${C.marino};letter-spacing:-0.02em;">${titulo}</td></tr>
    ${parrafos.map((p) => `<tr><td style="padding:16px 32px 0 32px;font:400 17px/1.55 ${TEXTO};color:${C.tinta};">${p}</td></tr>`).join('\n    ')}
    <tr><td style="padding:28px 32px 0 32px;">
      <table role="presentation" cellpadding="0" cellspacing="0"><tr><td align="center" bgcolor="${C.mango}" style="border:2px solid ${C.marino};border-radius:8px;">
        <a href="{{ .ConfirmationURL }}" target="_blank" style="display:inline-block;padding:18px 32px;font:700 19px/1 ${TEXTO};color:${C.marino};text-decoration:none;">${boton}</a>
      </td></tr></table>
    </td></tr>
    <tr><td style="padding:20px 32px 0 32px;font:400 14px/1.5 ${TEXTO};color:${C.gris};">${nota}</td></tr>
    <tr><td style="padding:16px 32px 28px 32px;font:400 13px/1.5 ${TEXTO};color:${C.gris};">Si el botón no abre, copia este enlace en tu navegador:<br><a href="{{ .ConfirmationURL }}" style="color:${C.marino};word-break:break-all;">{{ .ConfirmationURL }}</a></td></tr>
    <tr><td bgcolor="${C.marino}" style="padding:20px 32px;font:400 13px/1.5 ${TEXTO};color:${C.crema};">
      <strong style="color:${C.mango};">Barrio</strong> · Pide en tu barrio. Paga con un toque.<br>Cobros con CoDi, a través de <a href="https://pey.mx" style="color:${C.crema};">pey</a>. Hecho en CDMX.
    </td></tr>
  </table>
</td></tr></table>
</body></html>
`;
}

export const PLANTILLAS = {
  confirmacion: {
    asunto: 'Confirma tu correo en Barrio',
    html: correo({
      previa: 'Un toque y tu cuenta queda lista.',
      titulo: 'confirma tu correo',
      parrafos: ['Creaste una cuenta en Barrio con este correo.', 'Confírmala para pedir en tu barrio, con el total a la vista y pago con CoDi, o para recibir pedidos en tu negocio.'],
      boton: 'Confirmar mi correo',
      nota: 'Si no fuiste tú, ignora este mensaje: sin confirmar, la cuenta no se activa.',
    }),
  },
  recuperacion: {
    asunto: 'Cambia tu contraseña de Barrio',
    html: correo({
      previa: 'Elige una contraseña nueva en un minuto.',
      titulo: 'cambia tu contraseña',
      parrafos: ['Pediste cambiar la contraseña de tu cuenta en Barrio.', 'Toca el botón y elige una nueva. El enlace funciona una sola vez.'],
      boton: 'Elegir contraseña nueva',
      nota: 'Si no lo pediste, ignora este mensaje: tu contraseña actual sigue igual.',
    }),
  },
};

if (import.meta.url === `file://${process.argv[1]}`) {
  for (const [k, v] of Object.entries(PLANTILLAS)) writeFileSync(new URL(`${k}.html`, import.meta.url), v.html);
  console.log('plantillas escritas:', Object.keys(PLANTILLAS).join(', '));
}
