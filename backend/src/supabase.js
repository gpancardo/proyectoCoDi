export class Supabase {
  constructor({ url, serviceKey, anonKey }) { this.url = url.replace(/\/$/, ''); this.serviceKey = serviceKey; this.anonKey = anonKey; }
  async request(path, options = {}) {
    const respuesta = await fetch(`${this.url}${path}`, { ...options, headers: { apikey: this.serviceKey, Authorization: `Bearer ${this.serviceKey}`, ...(options.headers ?? {}) }, signal: AbortSignal.timeout(8000) });
    if (!respuesta.ok) throw Object.assign(new Error(`Supabase respondió ${respuesta.status}`), { status: respuesta.status });
    return respuesta.status === 204 ? null : respuesta.json();
  }
  negocios() { return this.request('/rest/v1/negocios?select=id,nombre,zona,direccion,categoria,productos,verificado,abierto&verificado=eq.true&order=id.asc'); }
  perfil(compradorId) { return this.request(`/rest/v1/perfiles_descubrimiento?comprador_id=eq.${encodeURIComponent(compradorId)}&select=categorias&limit=1`).then((r) => r[0] ?? null); }
  documentos(embedding) { return this.request('/rest/v1/rpc/match_catalogo_documentos', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ p_embedding: `[${embedding.join(',')}]`, p_limite: 40 }) }); }
  documentosPendientes() { return this.request('/rest/v1/catalogo_documentos?embedding=is.null&select=negocio_id,contenido&order=actualizado.asc&limit=100'); }
  actualizarEmbedding(negocioId, embedding) { return this.request(`/rest/v1/catalogo_documentos?negocio_id=eq.${encodeURIComponent(negocioId)}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json', Prefer: 'return=minimal' }, body: JSON.stringify({ embedding: `[${embedding.join(',')}]` }) }); }
  async sesion(token) {
    const r = await fetch(`${this.url}/auth/v1/user`, { headers: { apikey: this.anonKey, Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(8000) });
    if (!r.ok) return null;
    return r.json();
  }
  comprador(subject) { return this.request(`/rest/v1/compradores?sujeto_auth=eq.${encodeURIComponent(subject)}&select=id&limit=1`).then((r) => r[0] ?? null); }
  evento(body) { return this.request('/rest/v1/rpc/registrar_evento_descubrimiento', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }); }
  // Genéricos para pedidos/cobros. `filtro` es una query PostgREST construida por el backend, nunca por el cliente.
  get(tabla, filtro) { return this.request(`/rest/v1/${tabla}?${filtro}`); }
  insertar(tabla, filas) { return this.request(`/rest/v1/${tabla}`, { method: 'POST', headers: { 'Content-Type': 'application/json', Prefer: 'return=representation' }, body: JSON.stringify(filas) }); }
  // PATCH condicionado: devuelve las filas cambiadas; [] significa que el estado previo ya no coincidía.
  actualizar(tabla, filtro, cambios) { return this.request(`/rest/v1/${tabla}?${filtro}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json', Prefer: 'return=representation' }, body: JSON.stringify(cambios) }); }
  crearComprador(fila) { return this.request('/rest/v1/compradores?on_conflict=sujeto_auth', { method: 'POST', headers: { 'Content-Type': 'application/json', Prefer: 'return=representation,resolution=merge-duplicates' }, body: JSON.stringify(fila) }); }
}
