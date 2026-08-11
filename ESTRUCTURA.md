# Estructura del Arquetipo Apache Hop + H2

Estructura actual de `archetype/`. Es una plantilla estática: se copia a una carpeta nueva para crear un proyecto Apache Hop, renombrando el proyecto y completando variables.

```
archetype/
├── project-config.json                  # Fuente única de variables (H2 + Oracle + MySQL)
├── switch-env.ps1                       # Cambia entorno: .\switch-env.ps1 local|remote
├── .gitignore                           # client_secret.json, *.xlsx, .~*
├── README.md                            # Cómo usar el arquetipo
├── AGENTS.md                            # Guía para sesiones OpenCode en el proyecto generado
├── ESTRUCTURA.md                        # Este documento
│
├── environments/                        # Plantillas de variables por entorno
│   ├── local.json                       #   Entorno local/oficina (completar Oracle/MySQL)
│   └── remote.json                      #   Entorno remoto/casa (completar Oracle/MySQL)
│
├── h2/                                  # Infra H2 in-memory (reutilizada de etl_diego/h2)
│   ├── lib/
│   │   └── h2-2.4.240.jar               #   Driver/Server H2
│   ├── scripts/
│   │   ├── start_h2.bat                 #   Levanta H2 TCP+WEB en puerto 9092
│   │   ├── stop_h2.bat                  #   Mata procesos org.h2.tools.Server
│   │   └── reset_and_create.bat         #   stop + start + DDL (00_reset.sql + 01_schema.sql)
│   └── sql/
│       ├── 00_reset.sql                 #   DROP ALL OBJECTS (limpia mem:csep)
│       └── 01_schema.sql                #   DDL del proyecto (tabla demo + sección propia)
│
├── metadata/                            # Metadatos que lee Apache Hop
│   ├── rdbms/
│   │   ├── h2.json                      #   Conexión H2 (variables DB_H2_*)
│   │   ├── oracle_sisud.json            #   Oracle oefabd SISUD, fuente (variables DB_ORA_SISUD_*)
│   │   ├── oracle_repocsep.json         #   Oracle REPOCSEP, destino (variables DB_ORA_REPO_*)
│   │   └── mysql.json                   #   Conexión MySQL (variables DB_MYSQL_*)
│   ├── pipeline-run-configuration/
│   │   └── local.json                   #   Run config "local" para pipelines
│   └── workflow-run-configuration/
│       └── local.json                   #   Run config "local" para workflows
│
├── workflows/
│   └── wf_main.hwf                      # Entry point: Reset H2 clean → Pipeline demo → Run R → Success
│
├── pipelines/
│   └── pl_demo.hpl                      # Pipeline demo: H2 DEMO_TABLA_EJEMPLO → Dummy
│
├── r/                                  # Capa R (lógica de negocio aislada)
│   ├── main.R                          #   Orquestación: SETUP → leer_h2 → [único .R de logica/] → escribir_oracle
│   ├── CONTRATO.md                     #   Contrato entrada/salida de la capa R
│   ├── plantilla_logica.R              #   Plantilla de lógica (copiar a r/logica/)
│   ├── io/
│   │   ├── leer_h2.R                   #     ENTRADA genérica: H2 mem:csep → data.frames (lista `lecturas`)
│   │   └── escribir_oracle.R           #     SALIDA genérica: df → Oracle REPOCSEP (skip si placeholders)
│   └── logica/                         #     ZONA DE PEGADO: un solo .R auto-descubierto por main.R
│       └── LEEME.md                    #       Reglas del pegado (sin I/O dentro de la lógica)
│
├── lib/
│   └── ojdbc11.jar                     # Driver Oracle JDBC (requerido para write R → Oracle)
│
└── output/
    └── .gitkeep                         # Salidas generadas (xlsx, csv, logs)
```

## Flujo del entry point (`wf_main.hwf`)

```
Start → Reset H2 clean (SHELL: h2\scripts\reset_and_create.bat)
     → Pipeline demo (pl_demo.hpl) → Run R (Rscript r/main.R) → Success
```

- **Reset H2 clean**: detiene el server H2, lo levanta y aplica `h2/sql/00_reset.sql` + `h2/sql/01_schema.sql`. H2 es **in-memory** (`mem:csep`): se limpia sola al parar el server, por eso el DDL se aplica por TCP después del start.
- **Pipeline demo**: lee `PUBLIC.DEMO_TABLA_EJEMPLO` (creada en `01_schema.sql`) por la conexión `h2`. Es un smoke test: funciona sin BDs externas.
- **Run R**: ejecuta `r/main.R` → lee H2 (`r/io/leer_h2.R`), corre la lógica (el único `.R` en `r/logica/`, zona de pegado) y escribe a Oracle (`r/io/escribir_oracle.R`). Si las credenciales Oracle son placeholders, omite el write con warning → sigue siendo smoke test H2-only.

## Cómo se propaga a un proyecto nuevo

1. Copiar `archetype/` a `<workspace>/<nombre_proyecto>/`.
2. Registrar el proyecto en `D:\Eder\hop\config\hop-config.json` (fuera del repo) con el nombre nuevo.
3. Completar variables en `project-config.json` (o `environments/local.json` + `.\switch-env.ps1 local`).
4. Escribir el DDL propio en `h2/sql/01_schema.sql` y la lógica en `pipelines/` / `workflows/`.
