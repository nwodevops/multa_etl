# Diagrama general — ETL + Data Warehouse (visión futura)

Vista a grandes rasgos. No detalla columnas, puentes ni literales del TDR.

```mermaid
flowchart TB
  subgraph fuentes [Fuentes_operativas]
    Sheets[Google_Sheets_multas]
    SISUD_M[Oracle_SISUD_multas]
    SISUD_I[Oracle_SISUD_informes]
    MySQL[MySQL_gapps]
  end

  subgraph etl [ETL_multa_etl]
    Hop[Apache_Hop]
    H2[(H2_STG_landing)]
    R[R_reglas_negocio]
  end

  subgraph silver [REPOCSEP_silver]
    RPT_M[(RPT_MULTA_COERCITIVA)]
    RPT_I[(RPT_INFORME_SUPERVISION)]
    FACT_M[(FACT_MULTA_limpia)]
    FACT_I[(FACT_INFORME_limpia)]
  end

  subgraph dims [Dimensiones_compartidas]
    DIM_A[DIM_ADMINISTRADO]
    DIM_E[DIM_EXPEDIENTE]
    DIM_P[DIM_PERIODO]
    DIM_S[DIM_SECTOR]
    DIM_X[DIM_ESTRATEGIA]
  end

  subgraph gold [Capa_analitica]
    FACT_EF[(FACT_EFECTIVIDAD)]
    BI[Power_BI_tableros]
  end

  Sheets --> Hop
  SISUD_M --> Hop
  SISUD_I --> Hop
  MySQL --> Hop
  Hop --> H2
  H2 --> R
  H2 --> RPT_I
  R --> RPT_M
  RPT_M --> FACT_M
  RPT_I --> FACT_I
  FACT_M --> FACT_EF
  FACT_I --> FACT_EF
  DIM_A --> FACT_EF
  DIM_E --> FACT_EF
  DIM_P --> FACT_EF
  DIM_S --> FACT_EF
  DIM_X --> FACT_EF
  FACT_EF --> BI
  FACT_M --> BI
  FACT_I --> BI
```

**Lectura rápida**

1. **Fuentes** → Hop las baja a **H2 STG** (landing).
2. **Silver landing:** dos hechos (`RPT` multas / informes); multas pasan por R (UNION); informes van Hop-only.
3. **Silver depurado:** `FACT_*` limpios + **dimensiones** compartidas.
4. **Gold:** cruce de efectividad y consumo en BI — **sin mezclar granos** en una sola tabla cruda.
