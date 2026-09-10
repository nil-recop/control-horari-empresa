-- Dades de prova (opcional). S'apliquen automàticament amb `supabase db
-- reset` en local, o es poden enganxar manualment al SQL Editor.
-- Esborra aquest fitxer (o el seu contingut) si no vols dades d'exemple.
-- Recorda canviar els PIN abans de fer servir l'aplicació amb personal real.

insert into obres (id, name, address, active, cost_centers) values
  ('11111111-1111-1111-1111-111111111111', 'Rehabilitació Casa Batlló', 'Barcelona', true,
   '[{"id":"cc1","name":"Façanes"},{"id":"cc2","name":"Coberta"},{"id":"cc3","name":"Interiors"}]'),
  ('22222222-2222-2222-2222-222222222222', 'Restauració Cartoixa d''Escala Dei', 'Priorat, Tarragona', true,
   '[{"id":"cc4","name":"Consolidació estructural"},{"id":"cc5","name":"Pedra vista"}]')
on conflict (id) do nothing;

insert into workers (id, name, pin, role, hourly_rate, dieta_rate, desplacament_rate, obra_ids) values
  ('33333333-3333-3333-3333-333333333331', 'Jordi Puig', '1234', 'cap_obra', 0, 0, 0, '{}'),
  ('33333333-3333-3333-3333-333333333332', 'Marc Solà', '1111', 'encarregat', 18, 12, 8, '{11111111-1111-1111-1111-111111111111}'),
  ('33333333-3333-3333-3333-333333333333', 'Anna Ferré', '2222', 'treballador', 15, 12, 8, '{11111111-1111-1111-1111-111111111111}'),
  ('33333333-3333-3333-3333-333333333334', 'David Roig', '3333', 'treballador', 15, 12, 8, '{11111111-1111-1111-1111-111111111111,22222222-2222-2222-2222-222222222222}'),
  ('33333333-3333-3333-3333-333333333335', 'Laia Camps', '4444', 'treballador', 16, 12, 8, '{22222222-2222-2222-2222-222222222222}')
on conflict (id) do nothing;
