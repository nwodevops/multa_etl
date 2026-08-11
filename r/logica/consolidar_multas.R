# =============================================================================
# logica/consolidar_multas.R
# Fase 1 Opción 3: UNION de STG_* con columna FUENTE -> RESULTADO
# Entrada: GS1, GS2, ETAPAS, ORA, MYSQL (r/io/leer_h2.R)
# Salida : RESULTADO (esquema RPT_MULTA_COERCITIVA)
# Sin library()/conexiones aquí (contrato r/CONTRATO.md).
# =============================================================================

.chr <- function(x) {
  if (is.null(x)) return(NA_character_)
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(as.character(x))
  as.character(x)
}

.num <- function(x) {
  if (is.null(x)) return(NA_real_)
  suppressWarnings(as.numeric(x))
}

.empty_rpt <- function(n = 0L) {
  data.frame(
    FUENTE = character(n),
    FECHA_CARGA = .POSIXct(rep(NA_real_, n), tz = "UTC"),
    COD_MA = character(n),
    COD_PROY_MC = character(n),
    CUM = character(n),
    CAM = character(n),
    EXPEDIENTE = character(n),
    ADMINISTRADO = character(n),
    UF = character(n),
    COORD = character(n),
    JEFE = character(n),
    MONTO_UIT = as.numeric(rep(NA_real_, n)),
    MONTO_S = as.numeric(rep(NA_real_, n)),
    ESTADO = character(n),
    N_CARTA_DCG = character(n),
    FN_MC = character(n),
    F_VENC_DCG = character(n),
    PRESENT_DCG_ADM = character(n),
    AMERIT_MC = character(n),
    N_RES_MC = character(n),
    F_VENC_MC = character(n),
    ESTADO_MC = character(n),
    F_PAGO = character(n),
    RECORD_SEG = character(n),
    DOC_VERIF_MC = character(n),
    EXP_SIGED_DOC = character(n),
    ETA_REG_PROY_MC = character(n),
    ETA_REG_MC = character(n),
    N_PROY_MC = as.numeric(rep(NA_real_, n)),
    RESULT_PROY_MC = character(n),
    NRO_ETAPA_MC = as.numeric(rep(NA_real_, n)),
    PERF_ENCARG_MC = character(n),
    ACCION_MC = character(n),
    ENCARGADO_MC = character(n),
    F_ASIG_MC = character(n),
    EST_ETAPA_MC = character(n),
    CONFORMIDAD_MC = character(n),
    COD_ETAPA_MC = character(n),
    RESOLUCION = character(n),
    FECHA_EMISION = character(n),
    NUMERO_REGISTRO = character(n),
    ESTADO_RESOLUCION = character(n),
    MEDIDA_ADMINISTRATIVA = character(n),
    MONTO_MULTA_REC = as.numeric(rep(NA_real_, n)),
    MONTO_MULTA_TFA = as.numeric(rep(NA_real_, n)),
    NU_IDMC = as.numeric(rep(NA_real_, n)),
    TX_RECORD_SEG = character(n),
    FE_F_VERIF_POST_MC = character(n),
    FG_ESTADOMULTA = character(n),
    NU_IDVERIFICACIONMA = as.numeric(rep(NA_real_, n)),
    TX_PASOACTUAL = character(n),
    TX_ESTADOREGISTRO = character(n),
    stringsAsFactors = FALSE
  )
}

.map_gs <- function(df, fuente) {
  if (is.null(df) || nrow(df) == 0) return(.empty_rpt(0L))
  n <- nrow(df)
  out <- .empty_rpt(n)
  out$FUENTE <- fuente
  out$FECHA_CARGA <- Sys.time()
  out$COD_MA <- .chr(df$COD_MA)
  if ("COD_PROY_MC" %in% names(df)) out$COD_PROY_MC <- .chr(df$COD_PROY_MC)
  out$EXPEDIENTE <- .chr(df$EXP_INF_INCUMP)
  if ("ADM" %in% names(df)) out$ADMINISTRADO <- .chr(df$ADM)
  if ("UF" %in% names(df)) out$UF <- .chr(df$UF)
  if ("COORD" %in% names(df)) out$COORD <- .chr(df$COORD)
  if ("JEFE" %in% names(df)) out$JEFE <- .chr(df$JEFE)
  out$MONTO_UIT <- .num(df$MULTA_UIT)
  out$MONTO_S <- .num(df$MULTA_S)
  out$ESTADO <- .chr(df$ESTADO_MC)
  out$N_CARTA_DCG <- .chr(df$N_CARTA_DCG)
  out$FN_MC <- .chr(df$FN_MC)
  out$F_VENC_DCG <- .chr(df$F_VENC_DCG)
  out$PRESENT_DCG_ADM <- .chr(df$PRESENT_DCG_ADM)
  out$AMERIT_MC <- .chr(df$AMERIT_MC)
  out$N_RES_MC <- .chr(df$N_RES_MC)
  out$F_VENC_MC <- .chr(df$F_VENC_MC)
  out$ESTADO_MC <- .chr(df$ESTADO_MC)
  out$F_PAGO <- .chr(df$F_PAGO)
  out$RECORD_SEG <- .chr(df$RECORD_SEG)
  out$DOC_VERIF_MC <- .chr(df$DOC_VERIF_MC)
  out$EXP_SIGED_DOC <- .chr(df$EXP_SIGED_DOC)
  if ("ETA_REG_PROY_MC" %in% names(df)) out$ETA_REG_PROY_MC <- .chr(df$ETA_REG_PROY_MC)
  if ("ETA_REG_MC" %in% names(df)) out$ETA_REG_MC <- .chr(df$ETA_REG_MC)
  if ("N_PROY_MC" %in% names(df)) out$N_PROY_MC <- .num(df$N_PROY_MC)
  if ("RESULT_PROY_MC" %in% names(df)) out$RESULT_PROY_MC <- .chr(df$RESULT_PROY_MC)
  out
}

.map_etapas <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(.empty_rpt(0L))
  n <- nrow(df)
  out <- .empty_rpt(n)
  out$FUENTE <- "GS_ETAPA"
  out$FECHA_CARGA <- Sys.time()
  out$COD_PROY_MC <- .chr(df$COD_PROY_MC)
  out$NRO_ETAPA_MC <- .num(df$NRO_ETAPA_MC)
  out$PERF_ENCARG_MC <- .chr(df$PERF_ENCARG_MC)
  out$ACCION_MC <- .chr(df$ACCION_MC)
  out$ENCARGADO_MC <- .chr(df$ENCARGADO_MC)
  out$F_ASIG_MC <- .chr(df$F_ASIG_MC)
  out$EST_ETAPA_MC <- .chr(df$EST_ETAPA_MC)
  out$CONFORMIDAD_MC <- .chr(df$CONFORMIDAD_MC)
  out$COD_ETAPA_MC <- .chr(df$COD_ETAPA_MC)
  out$ESTADO <- .chr(df$EST_ETAPA_MC)
  out
}

.map_ora <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(.empty_rpt(0L))
  n <- nrow(df)
  out <- .empty_rpt(n)
  out$FUENTE <- "ORA"
  out$FECHA_CARGA <- Sys.time()
  out$CUM <- .chr(df$CUM)
  out$CAM <- .chr(df$CAM)
  out$EXPEDIENTE <- .chr(df$NUMERO_EXPEDIENTE)
  out$ADMINISTRADO <- .chr(df$ADMINISTRADO)
  out$MONTO_S <- .num(df$MONTO_MULTA)
  out$ESTADO <- .chr(df$ESTADO_MULTA)
  out$RESOLUCION <- .chr(df$RESOLUCION)
  out$FECHA_EMISION <- .chr(df$FECHA_EMISION)
  out$NUMERO_REGISTRO <- .chr(df$NUMERO_REGISTRO)
  out$ESTADO_RESOLUCION <- .chr(df$ESTADO_RESOLUCION)
  out$MEDIDA_ADMINISTRATIVA <- .chr(df$MEDIDA_ADMINISTRATIVA)
  out$MONTO_MULTA_REC <- .num(df$MONTO_MULTA_REC)
  out$MONTO_MULTA_TFA <- .num(df$MONTO_MULTA_TFA)
  out
}

.map_mysql <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(.empty_rpt(0L))
  n <- nrow(df)
  out <- .empty_rpt(n)
  out$FUENTE <- "MYSQL"
  out$FECHA_CARGA <- Sys.time()
  out$CUM <- .chr(df$TX_IDCUM)
  out$CAM <- .chr(df$TX_IDCAM)
  out$MONTO_UIT <- .num(df$NU_MONTOMCUIT)
  out$MONTO_S <- .num(df$NU_MONTOMCS)
  out$ESTADO <- .chr(df$FG_ESTADOMULTA)
  out$RECORD_SEG <- .chr(df$TX_RECORD_SEG)
  out$DOC_VERIF_MC <- .chr(df$TX_DOC_VERIF_MC)
  out$EXP_SIGED_DOC <- .chr(df$TX_EXP_SIGED_DOC)
  out$NU_IDMC <- .num(df$NU_IDMC)
  out$TX_RECORD_SEG <- .chr(df$TX_RECORD_SEG)
  out$FE_F_VERIF_POST_MC <- .chr(df$FE_F_VERIF_POST_MC)
  out$FG_ESTADOMULTA <- .chr(df$FG_ESTADOMULTA)
  out$NU_IDVERIFICACIONMA <- .num(df$NU_IDVERIFICACIONMA)
  out$TX_PASOACTUAL <- .chr(df$TX_PASOACTUAL)
  out$TX_ESTADOREGISTRO <- .chr(df$TX_ESTADOREGISTRO)
  out
}

# --- apilar ---
parts <- list(
  .map_gs(GS1, "GS1"),
  .map_gs(GS2, "GS2"),
  .map_etapas(ETAPAS),
  .map_ora(ORA),
  .map_mysql(MYSQL)
)

RESULTADO <- do.call(rbind, parts)
rownames(RESULTADO) <- NULL

message(
  "consolidar_multas: ", nrow(RESULTADO), " filas | ",
  paste(names(table(RESULTADO$FUENTE)), as.integer(table(RESULTADO$FUENTE)), sep = "=", collapse = ", ")
)
