# AGENTS.md

Proyecto ETL en **Apache Hop** (OEFA). No hay build/test/lint: la verificación es ejecutar el workflow en el GUI de Hop y revisar el log. Este proyecto se creó a partir del arquetipo en `D:\Eder\workspace_etl_apache_hop_oefa\archetype`.

## Ejecución y flujo

- Entrada: `workflows/wf_main.hwf`. Cadena: `Reset H2 clean` (SHELL) → `Pipeline demo` → `Run R` → `Success`.
- Cada corrida **resetea la BD H2** (stop + start + DDL) vía `h2/scripts/reset_and_create.bat`.
- Archivos `.hpl`/`.hwf` son XML con variables `${PROJECT_HOME}`.

## Capa R (lógica aislada)

- La lógica de negocio vive en `r/logica/`: **zona de pegado** con un solo `.R` (auto-descubierto por `r/main.R`; error si hay 0 o más de 1). Copy-paste ahí y corre.
- Entrada: data.frames ya cargados con los nombres de la lista `lecturas` en `r/io/leer_h2.R`. Salida: data.frame `RESULTADO` (`SALIDA_DF` configurable en `main.R`). Ver `r/CONTRATO.md`.
- Aislamiento: en `r/logica/` no hay conexiones ni jars ni `library()`; el I/O vive en `r/io/`.
- **No mover** la línea `options(java.parameters=...)` en `r/main.R`: va **antes** de `library(RJDBC)`/`rJava`.
- Prerequisitos: R 4.3.3 (ruta Rscript hardcodeada en el workflow), paquetes `RJDBC, dplyr, stringr, tidyr, lubridate` en `~/R/library`, `lib/ojdbc11.jar` para write a Oracle.
- Si las credenciales Oracle en `r/io/escribir_oracle.R` quedan como `<...>`, el write se omite con warning → smoke test H2-only.

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
