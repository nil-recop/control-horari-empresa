# RèCOP · Control Horari d'Obra

Aplicació web mòbil de control horari per a personal d'obra, encarregats i
cap d'obra de RèCOP.

**Aquest paquet ja està llest per publicar tal qual.** El fitxer
`index.html` ja porta configurada la connexió al vostre projecte real de
Supabase, i ja m'has confirmat que has executat `supabase/schema.sql`. No
cal editar cap fitxer.

## Publicar-ho a GitHub Pages (3 passos, sense Node ni build)

1. **Crea un repositori nou a GitHub** (per exemple, `recop-control-horari`)
   i puja-hi tot el contingut d'aquesta carpeta tal com està:
   - `index.html`
   - `.nojekyll`
   - `supabase/schema.sql`
   - `README.md`

2. Dins el repositori, vés a **Settings → Pages**.
   - A "Build and deployment → Source", tria **Deploy from a branch**.
   - A "Branch", tria `main` (o la que facis servir) i la carpeta
     **`/ (root)`**.
   - Prem **Save**.

3. Espera un o dos minuts. GitHub mostrarà l'adreça pública a la mateixa
   pàgina de **Settings → Pages**, amb aquest format:

   ```
   https://EL-TEU-USUARI.github.io/NOM-DEL-REPOSITORI/
   ```

   Obre aquesta adreça: l'aplicació ja hauria de carregar-se i connectar
   directament amb la vostra base de dades de Supabase.

Cada vegada que vulgueu actualitzar l'aplicació, només cal pujar els
canvis al repositori (`git push`) — GitHub Pages el torna a publicar
automàticament en un parell de minuts.

> Nota: amb un compte gratuït de GitHub, per fer servir Pages el
> repositori ha de ser **públic**. Si necessiteu que sigui privat, caldria
> un compte de pagament (GitHub Pro/Team) o publicar-ho amb Netlify en el
> seu lloc — te'n dono els passos més avall.

## Provar-ho abans de publicar (opcional)

Si vols comprovar-ho al teu ordinador abans de pujar-ho:

```bash
npx serve .
```

o, amb Python instal·lat:

```bash
python3 -m http.server 8080
```

I després obre `http://localhost:8080`. (Obrir `index.html` fent doble
clic directament no funciona bé; el navegador necessita servir-lo per
HTTP.)

## Alternativa: Netlify

Si en algun moment preferiu Netlify en lloc de GitHub Pages (per exemple,
per tenir un repositori privat sense pagar GitHub Pro): **Add new site →
Import an existing project** → tries el repositori → deixa el "Build
command" buit i el "Publish directory" com `.` (l'arrel) → Deploy. No cal
cap altre canvi.

## Si mai necessites canviar la connexió a Supabase

Només caldria en cas de canviar de projecte de Supabase. Les dues línies
són a l'inici del `<script>` dins `index.html`:

```js
const SUPABASE_URL = 'https://rtpsjbtvvnjigpuygrek.supabase.co';
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_1VoCxRb15wE5fLnQS_tQBQ_kx1cGgKZ';
```

## Carpeta `supabase/`

```
supabase/
├── schema.sql               Tot en un sol fitxer: la manera ràpida que ja
│                             heu fet servir (copiar i enganxar al SQL
│                             Editor del Dashboard). No cal tornar-lo a
│                             executar si ja teniu les taules creades.
├── config.toml               Configuració per si en algun moment voleu
│                             gestionar el projecte amb la CLI de Supabase.
├── migrations/
│   └── 20260101000000_initial_schema.sql
│                             El mateix esquema (taules, seguretat RLS i
│                             el bucket de justificants), però separat en
│                             el format de "migració" que espera la CLI.
├── seed.sql                  Només les dades de prova (obres i
│                             treballadors d'exemple), per separat de
│                             l'esquema.
└── .gitignore                Perquè Git ignori fitxers temporals que crea
                              la CLI en local.
```

**No cal que facis res més amb aquesta carpeta ara mateix** — el vostre
projecte ja funciona amb el que vau executar amb `schema.sql`. Aquesta
estructura (`config.toml` + `migrations/` + `seed.sql`) només es fa servir
si en el futur voleu instal·lar la [CLI de
Supabase](https://supabase.com/docs/guides/cli) (per exemple, per
desenvolupar en local amb Docker, o per connectar el repositori de GitHub
perquè apliqui els canvis de base de dades automàticament). En aquest cas:

```bash
supabase link --project-ref rtpsjbtvvnjigpuygrek
supabase db push
```

## Seguretat i xifratge de les dades

- **Xifratge per defecte de Supabase**: tant la base de dades com
  l'emmagatzematge de fitxers estan xifrats en repòs (AES-256) i en
  trànsit (HTTPS/TLS) de manera automàtica — no cal configurar res
  addicional.
- **Justificants (documents adjunts)**: es guarden en un magatzem
  (*bucket*) **privat**, mai amb accés públic directe. L'aplicació només
  genera enllaços temporals signats (vàlids 10 minuts) quan algú necessita
  veure o descarregar un document — inclosos els justificants mèdics.
- **Clau "publishable" al codi**: és la clau pública de Supabase
  (equivalent a l'antiga "anon key"), pensada expressament per anar dins
  codi client/públic. La protecció real de qui pot llegir o escriure cada
  dada la donen les polítiques RLS del fitxer `supabase/schema.sql`, no el
  fet d'amagar aquesta clau.
- **Xifratge addicional a nivell d'aplicació**: de moment no s'ha
  implementat perquè, sense un sistema d'autenticació real (cada usuari
  amb la seva pròpia clau), la clau de xifratge hauria d'anar incrustada
  al mateix codi públic, cosa que no aporta protecció real. Té sentit
  revisar-ho quan hi hagi autenticació d'usuaris.
- **Properes millores de seguretat recomanades, per ordre de prioritat**:
  1. Sistema d'autenticació real (substituir el PIN intern).
  2. Un cop hi hagi autenticació, restringir les polítiques RLS perquè
     cada persona només pugui veure/editar el que li correspon.
  3. Revisar llavors si cal xifratge addicional per usuari als documents.

## Nota tècnica: sense pas de compilació

`index.html` carrega React i Supabase des d'un CDN i transforma el codi
directament al navegador (amb Babel), en lloc de compilar-lo abans amb
Node/npm. Això fa que publicar-lo sigui tan senzill com pujar un sol
fitxer, a canvi d'un petit cost de rendiment en la primera càrrega de la
pàgina — assumible per a una eina interna de l'empresa.
