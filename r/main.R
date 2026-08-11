# =============================================================================
# main.R  --  ENTRY POINT de la capa R del arquetipo (orquestacion delgada)
#
# Flujo:
#   1. SETUP   : heap JVM + librerias + root
#   2. ENTRADA : io/leer_h2.R              -> data.frames (nombres = claves de `lecturas`)
#   3. LOGICA  : el UNICO .R de r/logica/  -> deja un df (SALIDA_DF)
#   4. SALIDA  : io/escribir_oracle.R      -> df -> Oracle REPOCSEP (skip si placeholders)
#
# ZONA DE PEGADO: para un ETL nuevo solo se copia un .R a r/logica/ y se deja
# un df con el nombre SALIDA_DF. El I/O (r/io/) no se toca.
# Contrato detallado: r/CONTRATO.md
#
# Requisitos:
#   - H2 TCP up (h2\scripts\reset_and_create.bat + pipelines Hop)
#   - R 4.3.3 + paquetes: RJDBC, dplyr, stringr, tidyr, lubridate
#   - lib/ojdbc11.jar (solo si se escribe a Oracle)
# Uso: Rscript r/main.R
# =============================================================================

# ---------------------------------------------------------------------------
# 0. CONFIG (editar por proyecto)
# ---------------------------------------------------------------------------
# Nombre del data.frame de salida que debe dejar la logica de r/logica/.
SALIDA_DF <- "RESULTADO"

# ---------------------------------------------------------------------------
# 1. SETUP: heap JVM ANTES de cargar rJava/RJDBC (no mover esta linea)
# ---------------------------------------------------------------------------
options(java.parameters = c("-Xmx6g", "-Xms512m"))

suppressPackageStartupMessages({
  .libPaths(c(path.expand("~/R/library"), .libPaths()))
  library(RJDBC)
  library(dplyr)
  library(stringr)
  library(tidyr)
  library(lubridate)
})

args_cmd <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_cmd, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
} else {
  normalizePath("r/main.R")
}
root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

ojdbc_jar <- file.path(root, "lib", "ojdbc11.jar")

# ---------------------------------------------------------------------------
# 2. ENTRADA (H2 -> data.frames en el entorno)
# ---------------------------------------------------------------------------
source(file.path(root, "r", "io", "leer_h2.R"))
datos <- leer_h2(root)
if (length(datos) == 0) stop("leer_h2() no devolvio data.frames; revisa 'lecturas' en r/io/leer_h2.R")

# Desempaquetar: cada clave de 'lecturas' es un data.frame con ese mismo nombre
for (nm in names(datos)) assign(nm, datos[[nm]], envir = globalenv())

# ---------------------------------------------------------------------------
# 3. LOGICA: auto-descubrir el UNICO .R de r/logica/ (zona de pegado)
# ---------------------------------------------------------------------------
logica_dir <- file.path(root, "r", "logica")
archivos_r <- list.files(logica_dir, pattern = "\\.R$", ignore.case = TRUE, full.names = TRUE)
if (length(archivos_r) == 0) stop("No hay ningun .R en r/logica/. Pega ahi tu logica (ver r/plantilla_logica.R)")
if (length(archivos_r) > 1) stop("Hay mas de un .R en r/logica/: ", length(archivos_r),
                                 ". Deja un solo archivo de logica.")

# El archivo de logica usa los data.frames ya cargados y debe dejar SALIDA_DF.
message("Logica: ", basename(archivos_r))
source(archivos_r[1])

if (!exists(SALIDA_DF, envir = globalenv())) {
  stop("La logica no dejo el data.frame '", SALIDA_DF, "' (configurable en main.R). Ver r/CONTRATO.md")
}

df_salida <- get(SALIDA_DF, envir = globalenv())
message("Salida de logica: ", nrow(df_salida), " filas x ", ncol(df_salida), " columnas")

# ---------------------------------------------------------------------------
# 4. SALIDA (df -> Oracle REPOCSEP; skip si credenciales placeholder)
# ---------------------------------------------------------------------------
source(file.path(root, "r", "io", "escribir_oracle.R"))
escribir_oracle(
  df_salida,
  ojdbc_jar = ojdbc_jar,
  ddl_path = file.path(root, "sql", "create_ORACLE_RPT_MULTA_COERCITIVA.sql")
)

message("Listo (H2 -> logica -> REPOCSEP.RPT_MULTA_COERCITIVA).")
