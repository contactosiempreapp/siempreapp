-- ============================================================
-- SIEMPRE — Datos iniciales (seed)
-- ============================================================

-- ------------------------------------------------------------
-- Catálogo de fármacos con interacción/relevancia en la gesta
-- (lista de partida — se amplía según necesidad clínica)
-- ------------------------------------------------------------

insert into catalogo_farmacos (nombre, grupo) values
  -- Antihipertensivos
  ('Alfametildopa', 'antihipertensivos'),
  ('Labetalol', 'antihipertensivos'),
  ('Nifedipina', 'antihipertensivos'),
  ('Amlodipina', 'antihipertensivos'),
  ('Hidralazina', 'antihipertensivos'),
  -- Anticoagulantes / antiagregantes
  ('Aspirina (AAS)', 'anticoagulantes_antiagregantes'),
  ('Enoxaparina', 'anticoagulantes_antiagregantes'),
  ('Heparina no fraccionada', 'anticoagulantes_antiagregantes'),
  -- Hipoglucemiantes
  ('Metformina', 'hipoglucemiantes'),
  ('Insulina NPH', 'hipoglucemiantes'),
  ('Insulina corriente', 'hipoglucemiantes'),
  -- Tiroideos
  ('Levotiroxina', 'tiroideos'),
  ('Metimazol', 'tiroideos'),
  ('Propiltiouracilo', 'tiroideos'),
  -- Anticonvulsivantes
  ('Sulfato de magnesio', 'anticonvulsivantes'),
  ('Levetiracetam', 'anticonvulsivantes'),
  ('Ácido valproico', 'anticonvulsivantes'),
  -- Psicofármacos
  ('Sertralina', 'psicofarmacos'),
  ('Fluoxetina', 'psicofarmacos'),
  ('Alprazolam', 'psicofarmacos'),
  -- Antibióticos con restricción en embarazo
  ('Amoxicilina', 'antibioticos_restriccion'),
  ('Nitrofurantoína', 'antibioticos_restriccion'),
  ('Doxiciclina (contraindicado)', 'antibioticos_restriccion'),
  -- AINEs
  ('Ibuprofeno', 'aines'),
  ('Diclofenac', 'aines'),
  -- Inmunosupresores
  ('Hidroxicloroquina', 'inmunosupresores'),
  ('Azatioprina', 'inmunosupresores'),
  ('Prednisona', 'inmunosupresores'),
  -- Suplementos
  ('Calcio', 'suplementos'),
  ('Hierro', 'suplementos'),
  ('Ácido fólico', 'suplementos'),
  ('Vitamina D', 'suplementos');

-- ------------------------------------------------------------
-- Plan de cuarto trimestre — Rama A (con trastorno hipertensivo
-- del embarazo). Basado en npj Women's Health, "Manejo de la
-- hipertensión postparto" (ventanas desde fecha de parto).
-- ------------------------------------------------------------

insert into cuarto_trimestre_plan (rama, item, categoria, ventana_inicio_dias, ventana_fin_dias, orden) values
  ('A_con_THE', 'Controlar la presión arterial (si hay antecedentes de HGT o ECV)', 'temprano', 0, 84, 1),
  ('A_con_THE', 'Screening de diabetes (si hubo DBTG, realizar PTOG)', 'temprano', 0, 84, 2),
  ('A_con_THE', 'Brindar consejos de hábitos saludables (ej: nutricionales)', 'temprano', 0, 84, 3),
  ('A_con_THE', 'Evaluar los determinantes sociales de la salud', 'temprano', 0, 84, 4),
  ('A_con_THE', 'Explicar métodos anticonceptivos y planificación familiar', 'intermedio', 84, 365, 5),
  ('A_con_THE', 'Evaluar síntomas de depresión postparto', 'intermedio', 84, 365, 6),
  ('A_con_THE', 'Evaluar la calidad del sueño', 'intermedio', 84, 365, 7),
  ('A_con_THE', 'Evaluar aparición de diabetes (glucemia en ayunas o HbA1c)', 'continuo', 0, null, 8),
  ('A_con_THE', 'Evaluar trastornos del perfil lipídico', 'continuo', 0, null, 9),
  ('A_con_THE', 'Evaluar peso saludable', 'continuo', 0, null, 10),
  ('A_con_THE', 'Continuar indicando hábitos saludables', 'continuo', 0, null, 11),
  ('A_con_THE', 'Reforzar los 8 pasos esenciales (AHA Life''s Essential 8)', 'continuo', 0, null, 12);

-- ------------------------------------------------------------
-- Plan de cuarto trimestre — Rama B (sin trastorno hipertensivo).
-- Controles estándar de rutina posparto. AJUSTAR intervalos
-- exactos cuando Bárbara los defina — quedan como placeholder
-- editable, no como definición clínica cerrada.
-- ------------------------------------------------------------

insert into cuarto_trimestre_plan (rama, item, categoria, ventana_inicio_dias, ventana_fin_dias, orden) values
  ('B_sin_THE', 'Control posparto de rutina', 'rutina', 0, 42, 1),
  ('B_sin_THE', 'Evaluar hábitos saludables', 'rutina', 0, 42, 2),
  ('B_sin_THE', 'Control posparto alejado', 'rutina', 42, 180, 3),
  ('B_sin_THE', 'Control anual de salud cardiovascular', 'continuo', 0, null, 4);

-- ============================================================
-- NOTA: la Rama B queda a definir con precisión — placeholder
-- para no bloquear el desarrollo del motor de fechas.
-- ============================================================
