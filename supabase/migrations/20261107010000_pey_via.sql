-- Cómo se cobró cada orden: define por dónde preguntarle a pey si ya se pagó (push, link de pago o QR).
alter table ordenes add column pey_via text check (pey_via in ('push', 'link', 'qr'));
