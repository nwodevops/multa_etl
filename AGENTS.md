# AGENTS.md

Proyecto ETL en **Apache Hop** (OEFA). No hay build/test/lint: la verificación es ejecutar el workflow en el GUI de Hop y revisar el log. Este proyecto se creó a partir del arquetipo en `D:\Eder\workspace_etl_apache_hop_oefa\archetype`.

## Ejecución y flujo

- **Smoke test del arquetipo**: `workflows/wf_main.hwf`. Cadena: `Reset H2 clean` (SHELL) → `Pipeline demo` → `Run R` → `Success`.
- **ETL real (Step 1+2)**: `workflows/wf_staging.hwf`. Cadena: `Reset H2 clean` → `load_sheets.hwf` → `Pipeline Oracle` → `Pipeline MySQL` → `Run R` (`consolidar_multas.R` UNION `FUENTE` → `REPOCSEP.RPT_MULTA_COERCITIVA`) → `Success`.
- Cada corrida **resetea la BD H2** (stop + start + DDL) vía `h2/scripts/reset_and_create.bat`; el DDL de staging vive en `h2/sql/01_schema.sql`.
- Archivos `.hpl`/`.hwf` son XML con variables `${PROJECT_HOME}`.

## Staging (Step 1 de `docs/notas.txt`)

- **5 tablas** `STG_*` en H2 (landing nullable, sin PK, en `01_schema.sql`): `STG_GS1_MULTAS_COERCITIVAS` (48 cols), `STG_GS1_ETAPAS` (12), `STG_GS2_MULTAS_COERCITIVAS` (32), `STG_ORA_VW_MULTA_COERCITIVA` (13), `STG_MYSQL_T_MVC_MULTACOERCITIVA` (18).
- **Fuentes**:
  - Google Sheets vía `workflows/load_sheets.hwf` (patrón `nefa_hop`): `pl_gs1_multas.hpl`, `pl_gs1_etapas.hpl`, `pl_gs2_multas.hpl` con `GoogleSheetsInput` → H2. Credencial: `${PROJECT_HOME}/client_secret.json`. Keys: `SPREADSHEET_KEY_GS1`, `SPREADSHEET_KEY_GS2`.
  - Oracle `SISUD.VW_MULTA_COERCITIVA` → `pl_stage_oracle.hpl`.
  - MySQL `gappsdb.T_MVC_MULTACOERCITIVA_MC` → `pl_stage_mysql.hpl`.

## Consolidación R (Step 2, fase 1 — UNION FUENTE)

- Lógica: `r/logica/consolidar_multas.R` (único `.R` en `r/logica/`).
- Entrada: `GS1`, `GS2`, `ETAPAS`, `ORA`, `MYSQL` desde `r/io/leer_h2.R`.
- Salida: `REPOCSEP.RPT_MULTA_COERCITIVA` (`sql/create_ORACLE_RPT_MULTA_COERCITIVA.sql`). CREATE si falta; luego TRUNCATE+INSERT.
- **No hay JOIN matched** Sheets↔Oracle/MySQL en esta fase (`COD_MA` ≠ `CUM`). Filtrar por `FUENTE` en consumo.
- **Fase 2 (pendiente)**: limpieza R, normalizar `COD_PROY_MC`, agregar etapas, puente `COD_MA`↔`CUM` si negocio lo define.

## Capa R (lógica aislada)

- Zona de pegado `r/logica/` con un solo `.R` (auto-descubierto por `r/main.R`).
- Ver `r/CONTRATO.md`.
- Prerequisitos: R en PATH o en `%ProgramFiles%\R\R-*` (el workflow busca `Rscript` solo; no hardcodea 4.3.3), paquetes `RJDBC, dplyr, stringr, tidyr, lubridate`, `lib/ojdbc11.jar`.
- Google Sheets: campos numéricos van como **String** en Hop (evita crash por `#N/A`); H2 STG_* también VARCHAR en montos. R convierte con `as.numeric`.
- Destino REPOCSEP ya configurado en `r/io/escribir_oracle.R` / `project-config.json` (`DB_ORA_REPO_*`).

## H2 (server local, in-memory)

- BD **in-memory** `mem:csep` (`jdbc:h2:tcp://localhost:9092/mem:csep;...MODE=Oracle...`). Se limpia sola al parar el server.
- El DDL se aplica por TCP **después** del start: `h2/scripts/reset_and_create.bat` → `h2/sql/00_reset.sql` (DROP ALL) + `h2/sql/01_schema.sql` (DDL del proyecto).
- Requiere `java` en PATH; jar `h2/lib/h2-2.4.240.jar`.
- Si el workflow se queda pegado en `Reset H2 clean`, revisar procesos java/H2 huérfanos (`h2/scripts/stop_h2.bat`).
- **Gotcha**: la línea `start "H2-Server" /MIN java ...` en `h2/scripts/start_h2.bat` debe terminar en `>nul 2>&1`; sin eso la acción SHELL de Hop se cuelga para siempre.

## Variables (crítico)

- **Fuente única**: `project-config.json` → `config.variables`. Un `${VAR}` literal en el log = variable no definida o proyecto activo equivocado.
- Cambio de entorno: `.\switch-env.ps1 local|remote` copia `environments/<env>.json` → `project-config.json`.
- El proyecto activo se elige en `D:\Eder\hop\config\hop-config.json` (fuera del repo): debe ser el nombre de este proyecto. No editar ese config salvo que el usuario lo pida.

## Conexiones

- `metadata/rdbms/*.json` referencian variables:
  - `h2` (`DB_H2_*`), lista por defecto.
  - `oracle_sisud` (`DB_ORA_SISUD_*`): Oracle **oefabd** (SISUD, fuente).
  - `oracle_repocsep` (`DB_ORA_REPO_*`): Oracle **REPOCSEP** (destino).
  - `mysql` (`DB_MYSQL_*`).
  - Completar los placeholders `<...>` en `project-config.json` o `environments/`.

## Credenciales y secretos

- Passwords en texto plano dentro del repo (`project-config.json`, `environments/*.json`, `r/io/escribir_oracle.R`): no commitear ni propagar.
- Si se usa Google Sheets, `client_secret.json` (service account) va en la raíz y está en `.gitignore`.
