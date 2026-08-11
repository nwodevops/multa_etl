# Arquetipo Apache Hop + H2 in-memory

Plantilla base para crear proyectos **Apache Hop** en OEFA.

Reglas fijas del arquetipo:
- Siempre es un ETL **Apache Hop**.
- Siempre se usa **H2 in-memory** (`mem:csep`, puerto `9092`) como staging, con **reset clean en cada corrida** (stop + start + DDL). La infra de H2 se reutiliza de `etl_diego/h2`.

## Uso

1. **Copiar** la carpeta a un proyecto nuevo:
   `Copy-Item -Recurse archetype\ <workspace>\<nombre_proyecto>`
2. **Registrar el proyecto** en Hop:
   editar `D:\Eder\hop\config\hop-config.json` (fuera del repo) para que el proyecto activo apunte a la carpeta nueva con el nombre elegido.
3. **Completar variables** en `project-config.json`:
   - `DB_H2_*` ya vienen listas (in-memory `mem:csep`).
   - Oracle (2 conexiones) y MySQL tienen placeholders `<...>`: rellenar con las credenciales reales (usar `.\switch-env.ps1 local|remote` con `environments/*.json` si se manejan entornos).
   - `DB_ORA_SISUD_*` → **Oracle oefabd** (SISUD, fuente).
   - `DB_ORA_REPO_*` → **Oracle REPOCSEP** (destino).
   - `DB_MYSQL_*` → MySQL gapps.
4. **Escribir el DDL propio** en `h2/sql/01_schema.sql` (la tabla demo `DEMO_TABLA_EJEMPLO` es solo un smoke test).
5. **Poner la lógica**: en `pipelines/` y `workflows/` (partiendo de `wf_main.hwf` / `pl_demo.hpl`), o en R pegando un `.R` en `r/logica/` (zona de pegado aislada; ver `r/plantilla_logica.R` y `r/CONTRATO.md`).

## Capa R (lógica aislada)

- La lógica de negocio puede vivir en **R** en vez de transformaciones de Hop. El patrón es por capas: `r/main.R` orquesta, `r/io/` es I/O genérico y `r/logica/` es una **zona de pegado**.
- Para un ETL nuevo: copiar `r/plantilla_logica.R` → `r/logica/<tu_logica>.R` (**un solo `.R`**), escribir la transformación con los data.frames de entrada (nombres = claves de `lecturas` en `r/io/leer_h2.R`) y dejar el data.frame `RESULTADO`. `main.R` lo auto-descubre y lo ejecuta.
- **Prerequisitos**: R 4.3.3 (la ruta del workflow está hardcodeada: `C:\Program Files\R\R-4.3.3\bin\Rscript.exe`), paquetes `RJDBC, dplyr, stringr, tidyr, lubridate` (en `~/R/library`), y `lib/ojdbc11.jar` para el write a Oracle.
- **Smoke test sin Oracle**: si las credenciales de `r/io/escribir_oracle.R` quedan como `<...>`, `main.R` ejecuta entrada+lógica y omite el write con warning.

## Verificación

No hay build/test/lint: se ejecuta `workflows/wf_main.hwf` en el GUI de Apache Hop y se revisa el log. El workflow demo corre sin BDs externas: lee `DEMO_TABLA_EJEMPLO` desde H2 y la capa R omite el write a Oracle si las credenciales son placeholders.

## Staging Area (Step 1) — `workflows/wf_staging.hwf`

ETL de staging de `docs/notas.txt`: resetea H2 y carga 4 fuentes a tablas `STG_*`:

1. **Google Sheets** (`workflows/load_sheets.hwf` + `client_secret.json`) → `STG_GS1_MULTAS_COERCITIVAS`, `STG_GS1_ETAPAS`, `STG_GS2_MULTAS_COERCITIVAS` (`pl_gs1_multas.hpl`, `pl_gs1_etapas.hpl`, `pl_gs2_multas.hpl`).
2. **Oracle** `SISUD.VW_MULTA_COERCITIVA` → `STG_ORA_VW_MULTA_COERCITIVA` (`pl_stage_oracle.hpl`).
3. **MySQL** `gappsdb.T_MVC_MULTACOERCITIVA_MC` → `STG_MYSQL_T_MVC_MULTACOERCITIVA` (`pl_stage_mysql.hpl`).

Prerequisitos para correr en Windows (los archivos `.bat`/rutas son Windows):
- `client_secret.json` (service account) en la raíz del proyecto; las hojas deben estar compartidas con el email de la SA.
- Variables `SPREADSHEET_KEY_GS1` / `SPREADSHEET_KEY_GS2` en `project-config.json`.
- Credenciales Oracle SISUD (`CSEPDV`) y MySQL (`gapps`) ya completadas en `project-config.json` / `environments/local.json` (texto plano, no commitear ni propagar).
- **Driver MySQL para Hop**: `mysql-connector-j-*.jar` en el `lib/` de la instalación de Hop (Hop no lo trae por defecto; el driver H2 y el Oracle suelen venir incluidos — si no, copiar `lib/ojdbc11.jar` al lib de Hop).
- Correr el workflow **Play** sobre `workflows/wf_staging.hwf` y revisar el log (el H2 se resetea solo en cada corrida).
- `docs/input_examples/*.xlsx` son referencia de mapeo (gitignoreados); el staging ya no los lee.

## Notas

- La BD in-memory se llama `mem:csep` en el arquetipo (igual que `etl_diego`). Si se renombra, hay que cambiarla en 4 lugares: `h2/scripts/reset_and_create.bat`, `project-config.json`, `environments/*.json` y `metadata/rdbms/h2.json`.
- Los `.bat` usan rutas relativas, así que funcionan copiados tal cual. Requieren `java` en PATH.
- `h2-2.4.240.jar`, puerto `9092` (H2 TCP + WEB `8082`).
- Contraseñas de BDs van en texto plano en `project-config.json` / `environments/*.json` / `r/io/escribir_oracle.R`: no commitear ni propagar.
