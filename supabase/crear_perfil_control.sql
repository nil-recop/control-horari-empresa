-- RèCOP · Rol "Control": arreglar la restricció de rols i crear un perfil Control
-- Executa-ho tot de dalt a baix al SQL Editor de Supabase.

-- 1) Permet el rol "control" (sense això, qualsevol canvi a "control" dona error)
alter table workers drop constraint if exists workers_role_check;
alter table workers add constraint workers_role_check
  check (role in ('treballador','encarregat','cap_obra','control'));

-- 2) Crea un perfil nou amb rol Control (si encara no existeix)
--    Entrada a l'app: tria "Control" a la llista i posa el PIN. CANVIA EL PIN
--    després des de Personal.
insert into workers (name, pin, role, active, external, position, hourly_rate, dieta_rate, desplacament_rate, obra_ids)
select 'Control', '4827', 'control', true, false, 'Administració', 0, 0, 0, '{}'
where not exists (select 1 from workers where name = 'Control');

-- 3) Comprovació: ha de sortir el perfil Control i la restricció amb 'control'
select name, role, active from workers where role = 'control';
select conname, pg_get_constraintdef(oid) from pg_constraint
where conrelid = 'workers'::regclass and contype = 'c';
