-- RèCOP · Control Horari d'Obra — ACTUALITZACIÓ COMPLETA de la base de dades
--
-- Executa aquest fitxer sencer, una sola vegada, al SQL Editor de Supabase
-- (New query -> enganxa -> Run). Es pot tornar a executar sense problema:
-- només aplica el que encara falti i no esborra cap dada.

-- 1) Columnes noves
alter table workers add column if not exists active boolean not null default true;
alter table workers add column if not exists external boolean not null default false;
alter table workers add column if not exists company text;
alter table workers add column if not exists position text;

alter table notificacions add column if not exists target text;

alter table solicituds add column if not exists obra_id uuid references obres(id) on delete set null;

alter table fitxatges add column if not exists hourly_rate numeric;
alter table fitxatges add column if not exists dieta_rate numeric;
alter table fitxatges add column if not exists desplacament_rate numeric;

-- 2) Fitxatges: una fila per treballador + data + obra (hores a diverses obres el mateix dia)
alter table fitxatges drop constraint if exists fitxatges_worker_id_date_key;
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'fitxatges_worker_id_date_obra_id_key') then
    alter table fitxatges add constraint fitxatges_worker_id_date_obra_id_key unique (worker_id, date, obra_id);
  end if;
end $$;

-- 3) Planificació (calendari del cap d'obra)
create table if not exists planificacio (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references workers(id) on delete cascade,
  date date not null,
  obra_id uuid references obres(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (worker_id, date)
);
alter table planificacio enable row level security;
drop policy if exists "anon full access" on planificacio;
create policy "anon full access" on planificacio for all using (true) with check (true);

-- 4) Assistència: eliminar un treballador no s'ha de bloquejar pel camp "marcat per"
alter table assistencia drop constraint if exists assistencia_marked_by_fkey;
alter table assistencia add constraint assistencia_marked_by_fkey
  foreign key (marked_by) references workers(id) on delete set null;

-- 5) Permisos per a la clau pública (també per a taules noves futures)
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;
alter default privileges in schema public grant select, insert, update, delete on tables to anon, authenticated;
alter default privileges in schema public grant usage, select on sequences to anon, authenticated;

-- 6) Congela el preu dels fitxatges antics (només els que encara no en tenen)
update fitxatges f
set hourly_rate = w.hourly_rate,
    dieta_rate = w.dieta_rate,
    desplacament_rate = w.desplacament_rate
from workers w
where f.worker_id = w.id and f.hourly_rate is null;

-- 7) Refresca la memòria cau de l'API
notify pgrst, 'reload schema';
