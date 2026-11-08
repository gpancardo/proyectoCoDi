export const normalizar = (valor = '') => String(valor)
  .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
  .toLowerCase().replace(/[^a-z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();

export const palabras = (valor) => normalizar(valor).split(' ').filter((p) => p.length > 1);

export const ZONAS = ['Álvaro Obregón', 'Azcapotzalco', 'Benito Juárez', 'Coyoacán', 'Cuajimalpa', 'Cuauhtémoc', 'Gustavo A. Madero', 'Iztacalco', 'Iztapalapa', 'Magdalena Contreras', 'Miguel Hidalgo', 'Milpa Alta', 'Tláhuac', 'Tlalpan', 'Venustiano Carranza', 'Xochimilco'];

export const categorias = ['abarrotes', 'antojitos', 'belleza', 'cafe', 'comida', 'farmacia', 'ferreteria', 'floreria', 'fruteria', 'lavanderia', 'panaderia', 'papeleria', 'taller'];
