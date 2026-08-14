# AGENTS.md

Proyecto ETL en **Apache Hop** (OEFA / CSEP). No hay build/test/lint: la verificación es ejecutar el workflow en el GUI de Hop y revisar el log. Este proyecto se creó a partir del arquetipo en `D:\Eder\workspace_etl_apache_hop_oefa\archetype`.

**Skill portable (Cursor, OpenCode, otros):** [`.agents/skills/oefa-csep-etl/SKILL.md`](.agents/skills/oefa-csep-etl/SKILL.md)  
**DWH / literal f (futuro):** [`docs/dwh_informes_multas_literal_f.md`](docs/dwh_informes_multas_literal_f.md)

## Ejecución y flujo

- **Smoke test del arquetipo**: `workflows/wf_main.hwf`. Cadena: `Reset H2 clean` (SHELL) → `Pipeline demo` → `Run R` → `Success`.
- **ETL real**: `workflows/wf_staging.hwf`. Cadena:
  1. `Reset H2 clean`
  2. `load_sheets.hwf`
  3. `Pipeline Oracle` (multas SISUD → STG)
  4. `Pipeline Informes` (`CSEP_INFORMES_VIEW` → STG)
  5. `Pipeline MySQL`
  6. `Ensure RPT Informes DDL` + `Pipeline RPT Informes` → `REPOCSEP.RPT_INFORME_SUPERVISION` (**Hop-only**, sin R)
  7. `Run R` → `REPOCSEP.RPT_MULTA_COERCITIVA` (UNION `FUENTE`)
  8. `Success`
- Cada corrida **resetea la BD H2** (stop + start + DDL) vía `h2/scripts/reset_and_create.bat`; el DDL de staging vive en `h2/sql/01_schema.sql`.
- Archivos `.hpl`/`.hwf` son XML con variables `${PROJECT_HOME}`.

## Staging (Step 1)

- **6 tablas** `STG_*` en H2 (landing nullable, sin PK, en `01_schema.sql`):
  - Multas: `STG_GS1_MULTAS_COERCITIVAS`, `STG_GS1_ETAPAS`, `STG_GS2_MULTAS_COERCITIVAS`, `STG_ORA_VW_MULTA_COERCITIVA`, `STG_MYSQL_T_MVC_MULTACOERCITIVA`
  - Informes: `STG_ORA_CSEP_INFORMES` (`SISUD.CSEP_INFORMES_VIEW`)
- **Fuentes**:
  - Google Sheets vía `workflows/load_sheets.hwf`: `pl_gs1_multas.hpl`, `pl_gs1_etapas.hpl`, `pl_gs2_multas.hpl`. Credencial: `${PROJECT_HOME}/client_secret.json`. Keys: `SPREADSHEET_KEY_GS1`, `SPREADSHEET_KEY_GS2`.
  - Oracle `SISUD.VW_MULTA_COERCITIVA` → `pl_stage_oracle.hpl`.
  - Oracle `SISUD.CSEP_INFORMES_VIEW` → `pl_stage_informes.hpl` (dump en `docs/input_examples/` solo mapeo).
  - MySQL `gappsdb.T_MVC_MULTACOERCITIVA_MC` → `pl_stage_mysql.hpl`.

## Dos hechos en REPOCSEP (no mezclar granos)

| RPT | Grano | Carga |
|-----|-------|-------|
| `RPT_MULTA_COERCITIVA` | UNION multi-fuente (`FUENTE`) | Hop STG + **R** |
| `RPT_INFORME_SUPERVISION` | 1 actividad/informe (`IDACTIVIDAD`) | **Hop only** (`pl_rpt_informes.hpl`) |

## Consolidación R (solo multas)

- Lógica: `r/logica/consolidar_multas.R` (único `.R` en `r/logica/`).
- Entrada: `GS1`, `GS2`, `ETAPAS`, `ORA`, `MYSQL` desde `r/io/leer_h2.R` (no lee informes).
- Salida: `REPOCSEP.RPT_MULTA_COERCITIVA`. CREATE si falta; luego TRUNCATE+INSERT.
- **No hay JOIN matched** Sheets↔Oracle/MySQL (`COD_MA` ≠ `CUM`). Filtrar por `FUENTE` en consumo.
- Cruce informes↔multas = entregable 2 (ver `docs/dwh_informes_multas_literal_f.md`).

## Capa R (lógica aislada)

- Zona de pegado `r/logica/` con un solo `.R` (auto-descubierto por `r/main.R`).
- Prerequisitos: R en PATH o `%ProgramFiles%\R\R-*`, paquetes `RJDBC, dplyr, stringr, tidyr, lubridate`, `lib/ojdbc11.jar`.
- Google Sheets: campos numéricos como **String** en Hop (evita crash por `#N/A`); H2 montos VARCHAR.
- Destino REPOCSEP: `r/io/escribir_oracle.R` / `DB_ORA_REPO_*`.

## H2 (server local, in-memory)

- BD **in-memory** `mem:csep` (`jdbc:h2:tcp://localhost:9092/mem:csep;...MODE=Oracle...`). Se limpia al parar el server.
- DDL por TCP después del start: `h2/scripts/reset_and_create.bat` → `00_reset.sql` + `01_schema.sql`.
- Requiere `java` en PATH; jar `h2/lib/h2-2.4.240.jar`.
- Tailscale (PC trabajo): `jdbc:h2:tcp://100.109.97.75:9092/mem:csep;...` user `sa` / `csep`.
- **Gotcha**: `start "H2-Server" /MIN java ... >nul 2>&1` o la acción SHELL de Hop se cuelga.

## Variables (crítico)

- **Fuente única**: `project-config.json` → `config.variables`. Un `${VAR}` literal en el log = variable no definida o proyecto activo equivocado.
- Cambio de entorno: `.\switch-env.ps1 local|remote` copia `environments/<env>.json` → `project-config.json`.
- El proyecto activo se elige en `D:\Eder\hop\config\hop-config.json` (fuera del repo).

## Conexiones

- `h2` (`DB_H2_*`)
- `oracle_sisud` (`DB_ORA_SISUD_*`): oefabd / SISUD (multas + informes)
- `oracle_repocsep` (`DB_ORA_REPO_*`): destino RPT
- `mysql` (`DB_MYSQL_*`)

## Credenciales y secretos

- Passwords en texto plano en repo: no propagar. `client_secret.json` en raíz y `.gitignore`.
