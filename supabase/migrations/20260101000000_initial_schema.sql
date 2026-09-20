-- RèCOP · Control Horari d'Obra — esquema inicial
-- Generat a partir de supabase/schema.sql, sense les dades de prova
-- (aquestes viuen a supabase/seed.sql, per separat).

create extension if not exists "pgcrypto";

-- ============================= Taules =============================

create table if not exists workers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  pin text not null,
  role text not null check (role in ('treballador','encarregat','cap_obra')),
  active boolean not null default true,
  hourly_rate numeric not null default 0,
  dieta_rate numeric not null default 0,
  desplacament_rate numeric not null default 0,
  obra_ids uuid[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists obres (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  active boolean not null default true,
  cost_centers jsonb not null default '[]',
  created_at timestamptz not null default now()
);

create table if not exists fitxatges (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references workers(id) on delete cascade,
  date date not null,
  baixa boolean not null default false,
  obra_id uuid references obres(id) on delete set null,
  hours numeric not null default 0,
  dieta boolean not null default false,
  desplacament boolean not null default false,
  comment text default '',
  -- Preus "congelats" en el moment de crear el fitxatge, perquè un canvi
  -- de preu del treballador més endavant no alteri el cost d'hores ja
  -- registrades. Poden quedar a null en registres molt antics (anteriors
  -- a aquesta columna); en aquest cas l'aplicació fa servir el preu actual
  -- del treballador com a reserva.
  hourly_rate numeric,
  dieta_rate numeric,
  desplacament_rate numeric,
  file_name text,
  file_path text,
  created_at timestamptz not null default now(),
  -- Una fila per treballador+data+obra: permet marcar hores a diverses
  -- obres el mateix dia (una fila per obra).
  unique (worker_id, date, obra_id)
);

create table if not exists solicituds (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references workers(id) on delete cascade,
  type text not null check (type in ('vacances','permis')),
  date_from date not null,
  date_to date not null,
  comment text default '',
  obra_id uuid references obres(id) on delete set null,
  file_name text,
  file_path text,
  status text not null default 'pendent' check (status in ('pendent','aprovada','rebutjada')),
  created_at timestamptz not null default now()
);

create table if not exists notificacions (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references workers(id) on delete cascade,
  message text not null,
  read boolean not null default false,
  target text,
  created_at timestamptz not null default now()
);

create table if not exists assignacions_cc (
  id uuid primary key default gen_random_uuid(),
  date date not null,
  obra_id uuid not null references obres(id) on delete cascade,
  cost_center_id text not null,
  worker_ids uuid[] not null default '{}',
  created_at timestamptz not null default now(),
  unique (date, obra_id, cost_center_id)
);

create table if not exists assistencia (
  id uuid primary key default gen_random_uuid(),
  date date not null,
  obra_id uuid not null references obres(id) on delete cascade,
  worker_id uuid not null references workers(id) on delete cascade,
  present boolean not null,
  marked_by uuid references workers(id),
  created_at timestamptz not null default now(),
  unique (date, obra_id, worker_id)
);

-- Planificació: destinació prevista (obra) d'un treballador en un dia,
-- feta servir pel calendari del cap d'obra (consulta de dies passats i
-- assignació de dies futurs).
create table if not exists planificacio (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references workers(id) on delete cascade,
  date date not null,
  obra_id uuid references obres(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (worker_id, date)
);

-- ============================= Row Level Security =============================
-- IMPORTANT: Aquestes polítiques són OBERTES (qualsevol amb la clau "anon"/
-- "publishable" pot llegir/escriure) perquè, de moment, l'aplicació encara
-- no té un sistema d'autenticació real (només PIN intern). És un pas
-- provisional del prototip. Quan implementeu l'autenticació definitiva,
-- s'han de restringir aquestes polítiques perquè cada usuari només pugui
-- veure/editar el que li correspon.

alter table workers enable row level security;
alter table obres enable row level security;
alter table fitxatges enable row level security;
alter table solicituds enable row level security;
alter table notificacions enable row level security;
alter table assignacions_cc enable row level security;
alter table assistencia enable row level security;
alter table planificacio enable row level security;

create policy "anon full access" on workers for all using (true) with check (true);
create policy "anon full access" on obres for all using (true) with check (true);
create policy "anon full access" on fitxatges for all using (true) with check (true);
create policy "anon full access" on solicituds for all using (true) with check (true);
create policy "anon full access" on notificacions for all using (true) with check (true);
create policy "anon full access" on assignacions_cc for all using (true) with check (true);
create policy "anon full access" on assistencia for all using (true) with check (true);
create policy "anon full access" on planificacio for all using (true) with check (true);

-- Crear les taules per SQL directe (en lloc del Table Editor) no atorga
-- permisos a "anon"/"authenticated" automàticament: cal fer-ho explícit,
-- o encara que les polítiques RLS siguin obertes, Postgres denegarà
-- l'accés abans d'arribar-hi ("permission denied for table ...").
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;
-- Perquè les taules que es creïn MÉS ENDAVANT també tinguin permisos sense
-- haver de tornar a fer aquest GRANT a mà cada vegada.
alter default privileges in schema public grant select, insert, update, delete on tables to anon, authenticated;
alter default privileges in schema public grant usage, select on sequences to anon, authenticated;

-- ============================= Emmagatzematge de justificants =============================
-- Bucket PRIVAT (public = false): els justificants (inclosos els mèdics) no
-- s'han de poder veure amb un enllaç directe sense signar, per protegir dades
-- sensibles. L'aplicació genera URLs signades temporals per veure'ls/descarregar-los.

insert into storage.buckets (id, name, public)
values ('justificants', 'justificants', false)
on conflict (id) do nothing;

create policy "anon upload justificants" on storage.objects
  for insert to anon with check (bucket_id = 'justificants');
create policy "anon read justificants" on storage.objects
  for select to anon using (bucket_id = 'justificants');
create policy "anon update justificants" on storage.objects
  for update to anon using (bucket_id = 'justificants');
create policy "anon delete justificants" on storage.objects
  for delete to anon using (bucket_id = 'justificants');
