-- RAG exacto. El índice ivfflat (lists = 10) es aproximado y revisa solo la lista más cercana: con pocos negocios devolvía
-- apenas una parte del catálogo (a "copias" le faltaba la papelería). A esta escala la búsqueda exacta es instantánea.
-- Cuando el catálogo pase de unos 5 mil negocios, crear un índice HNSW (create index ... using hnsw (embedding vector_cosine_ops)).
drop index if exists catalogo_documentos_embedding_idx;
