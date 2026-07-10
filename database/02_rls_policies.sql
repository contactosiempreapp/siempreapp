-- ============================================================
-- SIEMPRE — Políticas de Row Level Security (RLS)
-- ============================================================
-- Dos accesos muy distintos conviven en este sistema:
--
-- 1) PROFESIONAL: usa Supabase Auth (auth.uid()). Las políticas
--    de abajo lo limitan a ver/editar solo pacientes de SU
--    institución.
--
-- 2) PACIENTE: login por DNI + contraseña compartida, NO pasa
--    por Supabase Auth. El front nunca usa la API key "anon"
--    directo para leer/escribir datos de paciente — todo pasa
--    por una Edge Function que:
--      a) valida el token de paciente_sesiones
--      b) usa la service_role key (que ignora RLS) para hacer
--         la operación ya validada
--    Por eso NO hace falta (ni conviene) exponer políticas RLS
--    "para pacientes" en las tablas clínicas: la Edge Function
--    ya garantiza que una paciente solo pueda tocar sus propios
--    datos, porque arma el paciente_id desde el token, no desde
--    lo que mande el cliente.
--
-- Esto es lo mismo en espíritu a lo que ya usás en URCyM con la
-- vista SECURITY DEFINER, aplicado acá vía Edge Functions.
-- ============================================================

-- Función helper: institución del profesional autenticado
create or replace function institucion_del_profesional()
returns uuid
language sql
security definer
stable
as $$
  select institucion_id from profesionales where id = auth.uid();
$$;

-- ------------------------------------------------------------
-- Activar RLS en todas las tablas clínicas
-- ------------------------------------------------------------

alter table instituciones enable row level security;
alter table profesionales enable row level security;
alter table pacientes enable row level security;
alter table gestacion_actual enable row level security;
alter table antecedentes_clinicos enable row level security;
alter table antecedentes_obstetricos enable row level security;
alter table antecedentes_familiares enable row level security;
alter table antecedentes_paternos enable row level security;
alter table antecedentes_estilo_vida enable row level security;
alter table catalogo_farmacos enable row level security;
alter table paciente_medicamentos enable row level security;
alter table aspirina_log enable row level security;
alter table calcio_log enable row level security;
alter table mdpa_estudios enable row level security;
alter table mdpa_registros enable row level security;
alter table presion_arterial_suelta enable row level security;
alter table estudios_complementarios enable row level security;
alter table cuarto_trimestre_plan enable row level security;
alter table cuarto_trimestre_seguimiento enable row level security;
alter table seguimiento_citas enable row level security;
alter table paciente_sesiones enable row level security;

-- ------------------------------------------------------------
-- INSTITUCIONES: cualquier profesional autenticado puede leer
-- el listado (lo necesita, p.ej., el desplegable de alta).
-- Solo lectura — el alta de instituciones se hace manualmente.
-- ------------------------------------------------------------

create policy "instituciones_select_autenticados"
  on instituciones for select
  to authenticated
  using (true);

-- ------------------------------------------------------------
-- PROFESIONALES: cada profesional ve a sus colegas de la misma
-- institución (útil para saber quién cargó qué). Solo puede
-- editar su propia fila.
-- ------------------------------------------------------------

create policy "profesionales_select_misma_institucion"
  on profesionales for select
  to authenticated
  using (institucion_id = institucion_del_profesional());

create policy "profesionales_update_propio"
  on profesionales for update
  to authenticated
  using (id = auth.uid());

-- ------------------------------------------------------------
-- PACIENTES y tablas clínicas: el profesional solo ve/edita
-- pacientes de su propia institución.
-- ------------------------------------------------------------

create policy "pacientes_select_misma_institucion"
  on pacientes for select
  to authenticated
  using (institucion_id = institucion_del_profesional());

create policy "pacientes_insert_misma_institucion"
  on pacientes for insert
  to authenticated
  with check (institucion_id = institucion_del_profesional());

create policy "pacientes_update_misma_institucion"
  on pacientes for update
  to authenticated
  using (institucion_id = institucion_del_profesional());

-- Patrón repetido para cada tabla hija: el profesional accede
-- si la paciente referenciada pertenece a su institución.

create policy "gestacion_select" on gestacion_actual for select to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));
create policy "gestacion_insert" on gestacion_actual for insert to authenticated
  with check (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));

create policy "antclinicos_select" on antecedentes_clinicos for select to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));
create policy "antclinicos_insert" on antecedentes_clinicos for insert to authenticated
  with check (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));

create policy "antobst_select" on antecedentes_obstetricos for select to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));
create policy "antobst_insert" on antecedentes_obstetricos for insert to authenticated
  with check (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));

create policy "antfam_select" on antecedentes_familiares for select to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));
create policy "antfam_insert" on antecedentes_familiares for insert to authenticated
  with check (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));

create policy "antpat_select" on antecedentes_paternos for select to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));
create policy "antpat_insert" on antecedentes_paternos for insert to authenticated
  with check (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));

create policy "antestilo_select" on antecedentes_estilo_vida for select to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));
create policy "antestilo_insert" on antecedentes_estilo_vida for insert to authenticated
  with check (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));

create policy "catalogo_farmacos_select" on catalogo_farmacos for select to authenticated using (true);

create policy "pacmed_select" on paciente_medicamentos for select to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));
create policy "pacmed_insert" on paciente_medicamentos for insert to authenticated
  with check (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));
create policy "pacmed_update" on paciente_medicamentos for update to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));

create policy "aspirina_select" on aspirina_log for select to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));

create policy "calcio_select" on calcio_log for select to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));

create policy "mdpa_estudios_select" on mdpa_estudios for select to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));
create policy "mdpa_estudios_insert" on mdpa_estudios for insert to authenticated
  with check (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));

create policy "mdpa_registros_select" on mdpa_registros for select to authenticated
  using (estudio_id in (
    select e.id from mdpa_estudios e
    join pacientes p on p.id = e.paciente_id
    where p.institucion_id = institucion_del_profesional()
  ));

create policy "pa_suelta_select" on presion_arterial_suelta for select to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));

create policy "estudios_select" on estudios_complementarios for select to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));
create policy "estudios_insert" on estudios_complementarios for insert to authenticated
  with check (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));

create policy "ctplan_select" on cuarto_trimestre_plan for select to authenticated using (true);

create policy "ctseguimiento_select" on cuarto_trimestre_seguimiento for select to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));
create policy "ctseguimiento_insert" on cuarto_trimestre_seguimiento for insert to authenticated
  with check (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));

create policy "citas_select" on seguimiento_citas for select to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));
create policy "citas_insert" on seguimiento_citas for insert to authenticated
  with check (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));
create policy "citas_update" on seguimiento_citas for update to authenticated
  using (paciente_id in (select id from pacientes where institucion_id = institucion_del_profesional()));

-- paciente_sesiones: nadie accede vía API key normal, solo la
-- Edge Function con service_role (que ignora RLS). No se agregan
-- políticas a propósito → bloqueado por defecto para authenticated/anon.

-- ============================================================
-- IMPORTANTE — checklist antes de ir a producción:
--   [ ] Confirmar que la API key "anon" pública NUNCA se usa
--       para insertar/leer datos de paciente directamente.
--       Todo acceso de paciente pasa por la Edge Function.
--   [ ] Revisar que cada Edge Function de paciente arme el
--       paciente_id desde el token validado, no desde el body
--       que manda el cliente (para que una paciente no pueda
--       pedir datos de otra cambiando un id en la request).
--   [ ] Storage: crear políticas equivalentes para los buckets
--       de fotos MDPA / adjuntos de estudios (mismo criterio
--       de institución).
-- ============================================================
