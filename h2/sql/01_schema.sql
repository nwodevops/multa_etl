-- ============================================================
-- Schema H2 in-memory (mem:csep) para el proyecto.
-- Se ejecuta SIEMPRE despues del start del server H2
-- (h2/scripts/reset_and_create.bat → sql/00_reset.sql → sql/01_schema.sql).
--
-- REGLAS DEL ARQUETIPO:
--  * H2 es in-memory: cada corrida del workflow empieza con
--    stop + start + DROP ALL + este DDL. Todo se regenera.
--  * VARCHAR sin longitud = maximo en H2 (evita Value too long).
--  * Agrega aqui las tablas/vistas/indices propios del proyecto.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS PUBLIC;

-- Tabla de ejemplo usada por workflows/wf_main.hwf + pipelines/pl_demo.hpl
CREATE TABLE IF NOT EXISTS DEMO_TABLA_EJEMPLO (
    ID       INT PRIMARY KEY,
    TXNOMBRE VARCHAR,
    FEALTA   TIMESTAMP
);

INSERT INTO DEMO_TABLA_EJEMPLO (ID, TXNOMBRE, FEALTA) VALUES
    (1, 'fila demo 1', CURRENT_TIMESTAMP),
    (2, 'fila demo 2', CURRENT_TIMESTAMP);

-- ============================================================
-- STAGING STEP 1 (docs/notas.txt) - tablas stage del ETL
-- Fuentes: Google Sheets (load_sheets.hwf + client_secret.json),
--          vista Oracle SISUD.VW_MULTA_COERCITIVA,
--          tabla MySQL gappsdb.T_MVC_MULTACOERCITIVA_MC.
-- Convencion: STG_<origen>_<entidad>; todas nullable (landing tolerante).
-- ============================================================

-- GS #1 'CAGR: MA OEFA - 3) MULTAS COERCITIVAS' -> hoja '1) Multas coercitivas'
CREATE TABLE IF NOT EXISTS STG_GS1_MULTAS_COERCITIVAS (
    COD_MA            VARCHAR,
    COD_PROY_MC       VARCHAR,
    JEFE              VARCHAR,
    ETA_REG_PROY_MC   VARCHAR,
    N_PROY_MC         VARCHAR,
    COORD             VARCHAR,
    ADM               VARCHAR,
    UF                VARCHAR,
    EXP_INF_INCUMP    VARCHAR,
    N_CARTA_DCG       VARCHAR,
    FN_MC             TIMESTAMP,
    F_VENC_DCG        TIMESTAMP,
    PRESENT_DCG_ADM   VARCHAR,
    F_RPTA_ADM        TIMESTAMP,
    DOC_SIGED         VARCHAR,
    EST_DCG           VARCHAR,
    F_INIC_ANALISIS   TIMESTAMP,
    REQ_VERIF_CAMPO   VARCHAR,
    F_VERIF_CAMPO     TIMESTAMP,
    F_FIN_ANALISIS    TIMESTAMP,
    AMERIT_MC         VARCHAR,
    N_DOC_NO_AMERIT   VARCHAR,
    F_DOC_NO_AMERIT   TIMESTAMP,
    MOTIVO_NO_AMERIT  VARCHAR,
    RESULT_PROY_MC    VARCHAR,
    ETA_REG_MC        VARCHAR,
    EXP_RES_MC        VARCHAR,
    N_RES_MC          VARCHAR,
    F_FIRMA_RES_MC    TIMESTAMP,
    FN_RES_MC         TIMESTAMP,
    F_VENC_MC         TIMESTAMP,
    MULTA_UIT         VARCHAR,
    MULTA_S           VARCHAR,
    RECORD_SEG        VARCHAR,
    F_VERIF_POST_MC   TIMESTAMP,
    DOC_VERIF_MC      VARCHAR,
    EXP_SIGED_DOC     VARCHAR,
    ESTADO_MC         VARCHAR,
    F_PAGO            TIMESTAMP,
    MEMO_EF           VARCHAR,
    F_REMIS           TIMESTAMP,
    SIGED             VARCHAR,
    ESTADO_PAGO_MC    VARCHAR,
    AUX_FIN_MC        VARCHAR,
    AUX_COD_MA        VARCHAR,
    AUX_EST_MC        VARCHAR,
    URESOL_MC         VARCHAR,
    FN_URESOL_MC      TIMESTAMP
);

-- GS #1 'CAGR: MA OEFA - 3) MULTAS COERCITIVAS' -> hoja '2) Etapas'
CREATE TABLE IF NOT EXISTS STG_GS1_ETAPAS (
    COD_PROY_MC      VARCHAR,
    NRO_ETAPA_MC     VARCHAR,
    PERF_ENCARG_MC   VARCHAR,
    ACCION_MC        VARCHAR,
    ENCARGADO_MC     VARCHAR,
    F_ASIG_MC        TIMESTAMP,
    EST_ETAPA_MC     VARCHAR,
    CONFORMIDAD_MC   VARCHAR,
    F_ENT_DEV_MC     TIMESTAMP,
    T_ELAB_MC        VARCHAR,
    COD_ETAPA_MC     VARCHAR,
    AUX_FIN_MC       VARCHAR
);

-- GS #2 'MEDIDAS ADMINISTRATIVAS OD LAMBAYEQUE.xlsx' -> hoja '5) Multas Coercitivas'
CREATE TABLE IF NOT EXISTS STG_GS2_MULTAS_COERCITIVAS (
    COD_MA            VARCHAR,
    EXP_INF_INCUMP    VARCHAR,
    N_CARTA_DCG       VARCHAR,
    FN_MC             TIMESTAMP,
    F_VENC_DCG        TIMESTAMP,
    PRESENT_DCG_ADM   VARCHAR,
    F_RPTA_ADM        TIMESTAMP,
    DOC_SIGED         VARCHAR,
    F_INIC_ANALISIS   TIMESTAMP,
    REQ_VERIF_CAMPO   VARCHAR,
    F_VERIF_CAMPO     TIMESTAMP,
    F_FIN_ANALISIS    TIMESTAMP,
    AMERIT_MC         VARCHAR,
    N_DOC_NO_AMERIT   VARCHAR,
    F_DOC_NO_AMERIT   TIMESTAMP,
    MOTIVO_NO_AMERIT  VARCHAR,
    EXP_RES_MC        VARCHAR,
    N_RES_MC          VARCHAR,
    F_FIRMA_RES_MC    TIMESTAMP,
    FN_RES_MC         TIMESTAMP,
    F_VENC_MC         TIMESTAMP,
    MULTA_UIT         VARCHAR,
    MULTA_S           VARCHAR,
    RECORD_SEG        VARCHAR,
    F_VERIF_POST_MC   TIMESTAMP,
    DOC_VERIF_MC      VARCHAR,
    EXP_SIGED_DOC     VARCHAR,
    ESTADO_MC         VARCHAR,
    F_PAGO            TIMESTAMP,
    MEMO_EF           VARCHAR,
    F_REMIS           TIMESTAMP,
    SIGED             VARCHAR
);

-- Oracle SISUD.VW_MULTA_COERCITIVA (13 columnas del view de notas.txt)
CREATE TABLE IF NOT EXISTS STG_ORA_VW_MULTA_COERCITIVA (
    NUMERO_EXPEDIENTE     VARCHAR,
    ADMINISTRADO          VARCHAR,
    RESOLUCION            VARCHAR,
    FECHA_EMISION         TIMESTAMP,
    NUMERO_REGISTRO       VARCHAR,
    ESTADO_RESOLUCION     VARCHAR,
    MEDIDA_ADMINISTRATIVA VARCHAR,
    CUM                   VARCHAR,
    CAM                   VARCHAR,
    MONTO_MULTA           DECIMAL(38,6),
    MONTO_MULTA_REC       DECIMAL(38,6),
    MONTO_MULTA_TFA       DECIMAL(38,6),
    ESTADO_MULTA          VARCHAR
);

-- MySQL gappsdb.T_MVC_MULTACOERCITIVA_MC (18 columnas del DDL de notas.txt)
CREATE TABLE IF NOT EXISTS STG_MYSQL_T_MVC_MULTACOERCITIVA (
    NU_IDMC                 BIGINT,
    NU_MONTOMCUIT           BIGINT,
    NU_MONTOMCS             BIGINT,
    TX_IDCUM                VARCHAR,
    TX_IDCAM                VARCHAR,
    TX_RECORD_SEG           VARCHAR,
    FE_F_VERIF_POST_MC      TIMESTAMP,
    TX_DOC_VERIF_MC         VARCHAR,
    TX_EXP_SIGED_DOC        VARCHAR,
    FG_ESTADOMULTA          VARCHAR,
    NU_IDVERIFICACIONMA     BIGINT,
    NU_IDINFORMACIONMC      BIGINT,
    FE_FECHA_CREACION       TIMESTAMP,
    TX_USUARIO_CREACION     VARCHAR,
    FE_FECHA_MODIFICACION   TIMESTAMP,
    TX_USUARIO_MODIFICACION VARCHAR,
    TX_ESTADOREGISTRO       VARCHAR(1),
    TX_PASOACTUAL           VARCHAR(1)
);

-- ============================================================
-- >>> DDL PROPIO DEL PROYECTO (reemplazar/ampliar lo de arriba) <<<
-- Ejemplo:
--   CREATE TABLE PUBLIC.MI_TABLA (...);
--   CREATE INDEX ... ;
-- ============================================================
