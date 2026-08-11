# CONTRATO — capa R del arquetipo Apache Hop + H2

```
r/main.R            orquesta: SETUP → io/leer_h2.R → [único .R de logica/] → io/escribir_oracle.R
r/io/leer_h2.R      ENTRADA: H2 STG_* → data.frames GS1, GS2, ETAPAS, ORA, MYSQL
r/logica/           LOGICA: consolidar_multas.R (UNION FUENTE → RESULTADO)
r/io/escribir_oracle.R  SALIDA: RESULTADO → REPOCSEP.RPT_MULTA_COERCITIVA (CREATE si falta + TRUNCATE+INSERT)
```

## Entrada (`r/io/leer_h2.R`)

| Nombre | Fuente H2 |
|---|---|
| `GS1` | `STG_GS1_MULTAS_COERCITIVAS` |
| `GS2` | `STG_GS2_MULTAS_COERCITIVAS` |
| `ETAPAS` | `STG_GS1_ETAPAS` |
| `ORA` | `STG_ORA_VW_MULTA_COERCITIVA` |
| `MYSQL` | `STG_MYSQL_T_MVC_MULTACOERCITIVA` |

## Salida

Data.frame **`RESULTADO`** con columna `FUENTE` (`GS1`|`GS2`|`GS_ETAPA`|`ORA`|`MYSQL`) y esquema alineado a `sql/create_ORACLE_RPT_MULTA_COERCITIVA.sql`.

Escritor: CREATE si no existe → TRUNCATE → INSERT en `REPOCSEP.RPT_MULTA_COERCITIVA`.

## Reglas

- En `r/logica/` no hay conexiones ni `library()`; solo dplyr/base sobre data.frames.
- No mover `options(java.parameters=...)` en `r/main.R` (antes de RJDBC).
- Fase 1 = apilado sin JOIN matched Sheets↔SISUD. Limpieza/puente `COD_MA`↔`CUM` = fase 2.
