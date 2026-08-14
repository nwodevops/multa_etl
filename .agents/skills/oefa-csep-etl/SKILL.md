---
name: oefa-csep-etl
description: >-
  Apache Hop + H2 STG_* + R + Oracle REPOCSEP RPT_* ETL for OEFA CSEP (multas
  coercitivas e informes de supervisión). Use when extending multa_etl, adding
  STG/RPT sources, wiring wf_staging, debugging Hop logs, or planning TDR
  deliverables. Portable for Cursor, OpenCode, and other agents reading AGENTS.md.
---

# OEFA CSEP ETL (multa_etl)

## When to use

Working in `multa_etl` (or a clone of the CSEP Hop archetype): staging sources, writing `RPT_*` to REPOCSEP, reviewing TDR deliverables, or debugging a Hop Play log.

## Architecture (do not mix grains)

```
Sources (Sheets / Oracle SISUD / MySQL)
    -> Apache Hop
    -> H2 in-memory STG_* (landing, reset each run)
    -> either Hop TableOutput OR R consolidacion
    -> Oracle REPOCSEP.RPT_*
```

| Fact table | Grain | How it is loaded |
|---|---|---|
| `RPT_MULTA_COERCITIVA` | Union of multa sources (`FUENTE`) | Hop STG + **R** (`consolidar_multas.R`) |
| `RPT_INFORME_SUPERVISION` | One supervision activity/informe | **Hop only** (`pl_stage_informes` + `pl_rpt_informes`) |

Never `rbind` informes into the multa RPT. Informe ≠ multa.

## When Hop alone vs when R

- **Hop alone**: single source, 1:1 mapping to one RPT (example: `CSEP_INFORMES_VIEW`).
- **R**: multi-source UNION, wide schema mapping, business rules (`FUENTE`, `#N/A` → NA, future COD_MA↔CUM bridge).

## Workflow to run

Primary: `workflows/wf_staging.hwf`

1. Reset H2 clean (`h2/sql/00_reset.sql` + `01_schema.sql`)
2. `load_sheets.hwf` (GS1 multas, GS1 etapas, GS2 multas)
3. `pl_stage_oracle.hpl` → `STG_ORA_VW_MULTA_COERCITIVA`
4. `pl_stage_informes.hpl` → `STG_ORA_CSEP_INFORMES`
5. `pl_stage_mysql.hpl` → `STG_MYSQL_T_MVC_MULTACOERCITIVA`
6. Ensure DDL `sql/create_ORACLE_RPT_INFORME_SUPERVISION.sql`
7. `pl_rpt_informes.hpl` → `RPT_INFORME_SUPERVISION`
8. Run R → `RPT_MULTA_COERCITIVA`
9. Success

Verification = Hop GUI Play + log. No unit test suite.

## Extending a new source (checklist)

1. Map columns from live object (view/table/sheet). Files under `docs/input_examples/` are **mapping only**, not production extracts.
2. Add `STG_*` DDL to `h2/sql/01_schema.sql`.
3. Add Hop pipeline `pipelines/pl_stage_*.hpl` (TableInput → H2 TableOutput truncate).
4. Wire action + hops in `wf_staging.hwf`.
5. If single-source RPT: Hop pipeline to `oracle_repocsep` + DDL under `sql/create_ORACLE_RPT_*.sql` (idempotent).
6. If multi-source fact: extend `r/io/leer_h2.R` + the single file in `r/logica/` + `escribir_oracle.R` / `main.R`.
7. Update `AGENTS.md`.

## TDR REQ 3629-2026 (scope)

| Deliverable | Literals | Focus |
|---|---|---|
| 1 | a, b, c | Consolidate sources, structure review, quality diagnosis (both RPTs) |
| 2 | d, e, f | Depuration, traceability, **effectiveness analysis informes + multas** |
| 3 | g, h | Charts/indicators and management findings |

Do not implement literal f joins or DIM_* tables inside deliverable 1. See `docs/dwh_informes_multas_literal_f.md`.

## Connections (variables only)

- `h2` → `DB_H2_*` (`jdbc:h2:tcp://localhost:9092/mem:csep;...MODE=Oracle...`, user `sa` / password `csep`)
- `oracle_sisud` → `DB_ORA_SISUD_*` (oefabd / SISUD sources)
- `oracle_repocsep` → `DB_ORA_REPO_*` (REPOCSEP destination)
- `mysql` → `DB_MYSQL_*`

Never commit secrets. Do not paste passwords from `docs/notas.txt` into skills, PRs, or chat logs. `client_secret.json` is gitignored.

## Remote H2 (Tailscale)

If H2 runs on the Windows work PC and Tailscale is up:

`jdbc:h2:tcp://100.109.97.75:9092/mem:csep;DB_CLOSE_DELAY=-1;MODE=Oracle;DATABASE_TO_UPPER=TRUE;DEFAULT_NULL_ORDERING=HIGH;AUTO_RECONNECT=TRUE`

User `sa` / password `csep`. DB is **in-memory**: empty if the H2 server was restarted without a staging run.

## Hop gotchas already learned

- Sheets `#N/A` → use String fields in Hop; VARCHAR amounts in H2.
- Workflow XML: escape `&` as `&amp;` (e.g. `2>&amp;1`).
- Run R on Windows: delayed expansion + `call Rscript` so `%ERRORLEVEL%` is correct.
- Reset H2 SHELL must background the H2 server (`>nul 2>&1`) or Hop hangs.

## Quality rules (deliverable 1)

- Count STG rows vs source; `RPT` multa sum of `FUENTE` equals sum of multa STGs.
- Do not INNER JOIN `COD_MA` to `CUM` (different identifiers).
- Informes: key `IDACTIVIDAD`; watch null `TXNUMEXP` before any future bridge to multas.
