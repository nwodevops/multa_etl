# =============================================================================
# io/leer_h2.R
# ENTRADA generica del arquetipo: H2 mem:csep -> data.frames (RJDBC)
#
# La lista `lecturas` define el contrato de entrada de la logica:
#   nombre -> query SQL sobre H2 (mem:csep, puerto 9092, sa/csep)
# Cada clave de la lista se convierte en un data.frame con ESE MISMO nombre
# en el entorno (lo desempaqueta main.R).
#
# PARA UN ETL NUEVO: agregar/editar entradas en `lecturas` (no tocar el resto).
#
# Requisito: options(java.parameters=...) ANTES de library(RJDBC)/rJava
# Uso:
#   source(file.path(root, "r", "io", "leer_h2.R"))
#   datos <- leer_h2(root)
#   datos$<nombre>   # por cada clave de `lecturas`
# =============================================================================

leer_h2 <- function(root) {

  # Queries del proyecto. Las claves son los nombres de los data.frames de entrada.
  lecturas <- list(
    DEMO = "SELECT ID, TXNOMBRE, FEALTA FROM PUBLIC.DEMO_TABLA_EJEMPLO"
    # , MI_TABLA = "SELECT * FROM PUBLIC.MI_TABLA"
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

  # Coerciones genericas: columnas Date/timestamp -> Date (si aplica)
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
