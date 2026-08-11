# =============================================================================
# io/leer_h2.R
# ENTRADA: H2 mem:csep -> data.frames (claves = contrato de r/logica/)
# =============================================================================

leer_h2 <- function(root) {

  lecturas <- list(
    GS1    = "SELECT * FROM PUBLIC.STG_GS1_MULTAS_COERCITIVAS",
    GS2    = "SELECT * FROM PUBLIC.STG_GS2_MULTAS_COERCITIVAS",
    ETAPAS = "SELECT * FROM PUBLIC.STG_GS1_ETAPAS",
    ORA    = "SELECT * FROM PUBLIC.STG_ORA_VW_MULTA_COERCITIVA",
    MYSQL  = "SELECT * FROM PUBLIC.STG_MYSQL_T_MVC_MULTACOERCITIVA"
  )

  h2_jars <- list.files(file.path(root, "h2", "lib"), pattern = "^h2-[0-9].*\\.jar$", full.names = TRUE)
  h2_jar <- if (length(h2_jars) > 0) h2_jars[1] else file.path(root, "h2", "lib", "h2.jar")
  if (!file.exists(h2_jar)) stop("No se encuentra: ", h2_jar)

  if (!requireNamespace("RJDBC", quietly = TRUE)) stop("Paquete RJDBC no disponible")

  drv <- RJDBC::JDBC("org.h2.Driver", h2_jar)
  con <- DBI::dbConnect(
    drv,
    "jdbc:h2:tcp://localhost:9092/mem:csep;DB_CLOSE_DELAY=-1;MODE=Oracle;DATABASE_TO_UPPER=TRUE;DEFAULT_NULL_ORDERING=HIGH;AUTO_RECONNECT=TRUE",
    "sa",
    "csep"
  )
  on.exit(try(DBI::dbDisconnect(con), silent = TRUE), add = TRUE)

  datos <- lapply(lecturas, function(q) DBI::dbGetQuery(con, q))

  datos <- lapply(datos, function(df) {
    for (nm in names(df)) {
      if (inherits(df[[nm]], "POSIXct") || inherits(df[[nm]], "Date")) {
        df[[nm]] <- as.Date(df[[nm]])
      }
    }
    df
  })

  DBI::dbDisconnect(con)
  on.exit(NULL)

  for (nm in names(datos)) {
    message(nm, ": ", nrow(datos[[nm]]), " x ", ncol(datos[[nm]]))
  }

  datos
}
