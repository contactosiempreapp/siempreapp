-- ============================================================
-- SIEMPRE — Schema inicial de base de datos (Supabase / Postgres)
-- Seguimiento de mujeres con riesgo de preeclampsia
-- Embarazo + Cuarto trimestre
-- ============================================================
-- Convenciones:
--   - PK: uuid, default gen_random_uuid()
--   - Nada se sobreescribe: los datos clínicos editables se guardan
--     como filas nuevas con fecha_carga y profesional_id (historial).
--   - Todas las tablas clínicas llevan institucion_id (vía paciente)
--     para que las políticas RLS aíslen datos por hospital.
-- ============================================================

create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
-- 1. INSTITUCIONES Y PROFESIONALES
-- ------------------------------------------------------------

create table instituciones (
  id            uuid primary key default gen_random_uuid(),
  nombre        text not null,
  codigo        text unique not null,        -- para el listado desplegable
  activa        boolean not null default true,
  created_at    timestamptz not null default now()
);

-- profesionales usa Supabase Auth (auth.users) para login individual.
-- Esta tabla extiende auth.users con datos propios de la app.
create table profesionales (
  id            uuid primary key references auth.users(id) on delete cascade,
  institucion_id uuid not null references instituciones(id),
  nombre        text not null,
  matricula     text,
  email         text not null,
  activo        boolean not null default true,
  created_at    timestamptz not null default now()
);

-- ------------------------------------------------------------
-- 2. PACIENTES
-- ------------------------------------------------------------
-- Login de paciente: DNI + contraseña compartida (NO usa Supabase
-- Auth). El "id" interno es la clave real para todas las relaciones,
-- así un DNI mal cargado se puede corregir sin romper referencias.

create table pacientes (
  id                    uuid primary key default gen_random_uuid(),
  institucion_id        uuid not null references instituciones(id),
  dni                   text not null,
  apellido              text not null,
  nombre                text not null,
  fecha_nacimiento       date,
  telefono              text,
  fecha_alta            timestamptz not null default now(),
  profesional_alta_id   uuid references profesionales(id),
  indicacion_aspirina   boolean not null default false,
  aspirina_dosis_mg     integer default 81,
  indicacion_calcio     boolean not null default false,
  rama_cuarto_trimestre text check (rama_cuarto_trimestre in ('A_con_THE','B_sin_THE')),
  activa                boolean not null default true,
  created_at            timestamptz not null default now()
);

-- Un DNI no se repite dentro de la misma institución
create unique index idx_pacientes_dni_institucion on pacientes (institucion_id, dni);
create index idx_pacientes_apellido on pacientes (apellido);
create index idx_pacientes_dni on pacientes (dni);

-- ------------------------------------------------------------
-- 3. GESTACIÓN ACTUAL (histórico — no se sobreescribe)
-- ------------------------------------------------------------

create table gestacion_actual (
  id                    uuid primary key default gen_random_uuid(),
  paciente_id           uuid not null references pacientes(id) on delete cascade,
  fum                   date,
  fecha_eco_datante     date,
  eco_semanas           integer,
  eco_dias              integer,
  fpp_obstetra          date,
  fuente_fpp_vigente    text check (fuente_fpp_vigente in ('FUM','ECO','OBSTETRA')),
  fecha_parto_real      date,               -- se completa al finalizar la gesta; dispara el motor de cuarto trimestre
  profesional_id        uuid references profesionales(id),
  fecha_carga           timestamptz not null default now()
);
create index idx_gestacion_paciente on gestacion_actual (paciente_id, fecha_carga desc);

-- ------------------------------------------------------------
-- 4. ANTECEDENTES (histórico — no se sobreescribe)
-- ------------------------------------------------------------

create table antecedentes_clinicos (
  id                          uuid primary key default gen_random_uuid(),
  paciente_id                 uuid not null references pacientes(id) on delete cascade,
  preeclampsia_previa         boolean default false,
  hta_cronica                 boolean default false,
  diabetes_pregestacional     boolean default false,
  diabetes_tipo                text check (diabetes_tipo in ('tipo1','tipo2', null)),
  enfermedad_renal_cronica    boolean default false,
  enfermedad_autoinmune       boolean default false,
  enfermedad_autoinmune_cual  text,
  sindrome_ovario_poliquistico boolean default false,
  embarazo_multiple           boolean default false,
  nuliparidad                 boolean default false,
  intervalo_embarazos_mayor_10 boolean default false,
  edad_materna                integer,
  imc_pregestacional          numeric(4,1),
  reproduccion_asistida       boolean default false,
  otros_antecedentes          text,
  profesional_id              uuid references profesionales(id),
  fecha_carga                 timestamptz not null default now()
);
create index idx_antclinicos_paciente on antecedentes_clinicos (paciente_id, fecha_carga desc);

-- Una fila por embarazo previo
create table antecedentes_obstetricos (
  id                    uuid primary key default gen_random_uuid(),
  paciente_id           uuid not null references pacientes(id) on delete cascade,
  numero_gesta          integer,
  anio                  integer,
  hta_gestacional       boolean default false,
  preeclampsia          boolean default false,
  diabetes_gestacional  boolean default false,
  rciu                  boolean default false,
  parto_prematuro       boolean default false,
  semana_finalizacion   integer,
  via_finalizacion      text check (via_finalizacion in ('vaginal','cesarea', null)),
  peso_nacimiento_g     integer,
  otras_complicaciones  text,
  profesional_id        uuid references profesionales(id),
  fecha_carga           timestamptz not null default now()
);
create index idx_antobst_paciente on antecedentes_obstetricos (paciente_id);

create table antecedentes_familiares (
  id                    uuid primary key default gen_random_uuid(),
  paciente_id           uuid not null references pacientes(id) on delete cascade,
  madre_the             boolean default false,
  madre_pe              boolean default false,
  hermana_the           boolean default false,
  hermana_pe            boolean default false,
  profesional_id        uuid references profesionales(id),
  fecha_carga           timestamptz not null default now()
);
create index idx_antfam_paciente on antecedentes_familiares (paciente_id, fecha_carga desc);

-- Una fila por embarazo previo del padre (puede haber sido con otra pareja)
create table antecedentes_paternos (
  id                    uuid primary key default gen_random_uuid(),
  paciente_id           uuid not null references pacientes(id) on delete cascade,
  fue_con_pareja_actual boolean not null,
  the                   boolean default false,
  preeclampsia          boolean default false,
  anio                  integer,
  profesional_id        uuid references profesionales(id),
  fecha_carga           timestamptz not null default now()
);
create index idx_antpat_paciente on antecedentes_paternos (paciente_id);

create table antecedentes_estilo_vida (
  id                     uuid primary key default gen_random_uuid(),
  paciente_id            uuid not null references pacientes(id) on delete cascade,
  ocupacion              text,
  tipo_alimentacion      text check (tipo_alimentacion in ('omnivora','vegetariana','vegana','otra')),
  tipo_alimentacion_otra text,
  tabaquismo             text check (tabaquismo in ('nunca','actual','exfumadora')),
  actividad_fisica_previa boolean,
  consumo_alcohol        boolean default false,
  otras_sustancias       text,
  profesional_id         uuid references profesionales(id),
  fecha_carga            timestamptz not null default now()
);
create index idx_antestilo_paciente on antecedentes_estilo_vida (paciente_id, fecha_carga desc);

-- ------------------------------------------------------------
-- 5. MEDICAMENTOS
-- ------------------------------------------------------------

create table catalogo_farmacos (
  id      uuid primary key default gen_random_uuid(),
  nombre  text not null,
  grupo   text not null check (grupo in (
            'antihipertensivos','anticoagulantes_antiagregantes',
            'hipoglucemiantes','tiroideos','anticonvulsivantes',
            'psicofarmacos','antibioticos_restriccion','aines',
            'inmunosupresores','suplementos','otros'
          ))
);

create table paciente_medicamentos (
  id                 uuid primary key default gen_random_uuid(),
  paciente_id        uuid not null references pacientes(id) on delete cascade,
  farmaco_id         uuid not null references catalogo_farmacos(id),
  dosis              text,
  fecha_inicio       date not null default current_date,
  fecha_fin          date,                 -- null = vigente
  motivo_suspension  text,
  profesional_id     uuid references profesionales(id),
  fecha_carga        timestamptz not null default now()
);
create index idx_pacmed_paciente on paciente_medicamentos (paciente_id, fecha_fin);

-- ------------------------------------------------------------
-- 6. ASPIRINA — calendario diario
-- ------------------------------------------------------------

create table aspirina_log (
  id            uuid primary key default gen_random_uuid(),
  paciente_id   uuid not null references pacientes(id) on delete cascade,
  dia           date not null,
  tomada        boolean not null,
  hora_registro timestamptz not null default now(),
  unique (paciente_id, dia)
);
create index idx_aspirina_paciente_dia on aspirina_log (paciente_id, dia desc);

-- ------------------------------------------------------------
-- 7. CALCIO — calendario diario + alimentos + suplemento + efectos adversos
-- ------------------------------------------------------------

create table calcio_log (
  id                uuid primary key default gen_random_uuid(),
  paciente_id       uuid not null references pacientes(id) on delete cascade,
  dia               date not null,
  alimentos         jsonb,            -- [{alimento, porcion, mg_calcio}, ...]
  aporte_calculado_mg integer,
  uso_suplemento    boolean default false,
  efecto_adverso    text,             -- null = sin efectos adversos ese día
  hora_registro     timestamptz not null default now(),
  unique (paciente_id, dia)
);
create index idx_calcio_paciente_dia on calcio_log (paciente_id, dia desc);

-- ------------------------------------------------------------
-- 8. PRESIÓN ARTERIAL — MDPA
-- ------------------------------------------------------------

create table mdpa_estudios (
  id                     uuid primary key default gen_random_uuid(),
  paciente_id            uuid not null references pacientes(id) on delete cascade,
  fecha_inicio           date not null,
  duracion_dias          integer not null default 4,
  motivo                 text,                -- diagnóstico / control / etc.
  farmacos_utilizados    text,
  incluye_postprandial   boolean not null default true,
  umbral_alarma_sis      integer not null default 135,
  umbral_alarma_dia      integer not null default 85,
  umbral_severo_sis      integer not null default 160,
  umbral_severo_dia      integer not null default 110,
  origen_carga           text check (origen_carga in ('manual','foto','pdf')) default 'manual',
  archivo_adjunto_url    text,
  profesional_id         uuid references profesionales(id),
  fecha_carga            timestamptz not null default now()
);
create index idx_mdpa_paciente on mdpa_estudios (paciente_id, fecha_inicio desc);

create table mdpa_registros (
  id            uuid primary key default gen_random_uuid(),
  estudio_id    uuid not null references mdpa_estudios(id) on delete cascade,
  dia           integer not null,             -- día 1, 2, 3...
  momento       text not null check (momento in ('matutina','postprandial','vespertina')),
  toma          integer not null check (toma in (1,2)),
  sistolica     integer,
  diastolica    integer,
  fecha_hora    timestamptz not null default now(),
  unique (estudio_id, dia, momento, toma)
);
create index idx_mdparegistros_estudio on mdpa_registros (estudio_id);

-- Mediciones sueltas (fuera de un estudio MDPA formal)
create table presion_arterial_suelta (
  id            uuid primary key default gen_random_uuid(),
  paciente_id   uuid not null references pacientes(id) on delete cascade,
  fecha_hora    timestamptz not null default now(),
  sistolica     integer not null,
  diastolica    integer not null,
  origen_carga  text check (origen_carga in ('manual','foto','pdf')) default 'manual',
  es_alarma     boolean default false,
  es_severa     boolean default false
);
create index idx_pasuelta_paciente on presion_arterial_suelta (paciente_id, fecha_hora desc);

-- ------------------------------------------------------------
-- 9. ESTUDIOS COMPLEMENTARIOS (carga profesional)
-- ------------------------------------------------------------

create table estudios_complementarios (
  id              uuid primary key default gen_random_uuid(),
  paciente_id     uuid not null references pacientes(id) on delete cascade,
  tipo            text not null check (tipo in (
                    'presurometria','vop','cardiografia','ecografia',
                    'curva_ponderal','screening_serico_sflt_plgf','otro'
                  )),
  fecha           date not null,
  datos           jsonb,             -- estructura libre por tipo (se tipa más adelante si hace falta)
  archivo_adjunto_url text,
  profesional_id  uuid references profesionales(id),
  fecha_carga     timestamptz not null default now()
);
create index idx_estudios_paciente on estudios_complementarios (paciente_id, tipo, fecha desc);

-- ------------------------------------------------------------
-- 10. CUARTO TRIMESTRE — plan de controles por rama
-- ------------------------------------------------------------

create table cuarto_trimestre_plan (
  id                   uuid primary key default gen_random_uuid(),
  rama                 text not null check (rama in ('A_con_THE','B_sin_THE')),
  item                 text not null,
  categoria            text not null,        -- temprano / intermedio / continuo (Rama A) — libre para Rama B
  ventana_inicio_dias  integer not null,      -- offset desde fecha_parto_real
  ventana_fin_dias     integer,               -- null = continuo, sin fin
  orden                integer default 0
);

-- Estado de cada paciente respecto a cada ítem del plan (se marca cumplido/pendiente)
create table cuarto_trimestre_seguimiento (
  id              uuid primary key default gen_random_uuid(),
  paciente_id     uuid not null references pacientes(id) on delete cascade,
  plan_item_id    uuid not null references cuarto_trimestre_plan(id),
  cumplido        boolean not null default false,
  fecha_cumplido  date,
  profesional_id  uuid references profesionales(id),
  fecha_carga     timestamptz not null default now()
);
create index idx_ctseguimiento_paciente on cuarto_trimestre_seguimiento (paciente_id);

-- ------------------------------------------------------------
-- 11. SEGUIMIENTO / CITAS (para panel de cohorte del profesional)
-- ------------------------------------------------------------

create table seguimiento_citas (
  id                     uuid primary key default gen_random_uuid(),
  paciente_id            uuid not null references pacientes(id) on delete cascade,
  fecha_esperada         date not null,
  tipo_control           text,
  asistio                boolean,
  motivo_inasistencia    text,
  profesional_id         uuid references profesionales(id),
  fecha_carga            timestamptz not null default now()
);
create index idx_seguimiento_paciente on seguimiento_citas (paciente_id, fecha_esperada desc);

-- ------------------------------------------------------------
-- 12. SESIÓN DE PACIENTE (login DNI + contraseña compartida)
-- ------------------------------------------------------------
-- No usa Supabase Auth. Se valida en una función y se emite un
-- token propio (guardado en esta tabla) que el front usa para
-- las siguientes requests, vía una Edge Function.

create table paciente_sesiones (
  id            uuid primary key default gen_random_uuid(),
  paciente_id   uuid not null references pacientes(id) on delete cascade,
  token         text not null unique,
  creado_en     timestamptz not null default now(),
  expira_en     timestamptz not null
);
create index idx_sesiones_token on paciente_sesiones (token);

-- ============================================================
-- Fin del schema base.
-- Siguiente archivo: 02_rls_policies.sql
-- ============================================================
