# =============================================================================
# io/escribir_oracle.R
# SALIDA generica del arquetipo: data.frame -> tabla Oracle (TRUNCATE + INSERT)
#
# Normaliza generosamente antes de escribir:
#   - factores -> character
#   - columnas Date -> string ISO "%Y-%m-%d %H:%M:%S" (combina con ALTER SESSION
#     NLS_DATE_FORMAT para evitar ORA-01861)
#   - ALTER SESSION NLS_DATE_FORMAT + TRUNCATE + dbWriteTable(append) + COUNT
#
# CREDENCIALES: completar aqui los defaults del proyecto (texto plano, igual que
# project-config.json). Si url/user/password quedan como "<...>" (placeholders),
# el write se OMITE con un warning -> permite smoke test H2-only sin Oracle.
#
# Uso:
#   source(file.path(root, "r", "io", "escribir_oracle.R"))
#   escribir_oracle(df, ojdbc_jar = ojdbc_jar)
# =============================================================================

escribir_oracle <- function(df,
                            tabla = "MI_TABLA",
                            esquema = "MI_ESQUEMA",
                            url = "<DB_ORA_REPO_URL>",
                            user = "<USUARIO>",
                            password = "<PASSWORD>",
                            ojdbc_jar) {
  if (missing(ojdbc_jar) || !file.exists(ojdbc_jar)) {
    stop("No se encuentra ojdbc_jar: ", ojdbc_jar)
  }

  # Skip si las credenciales siguen siendo placeholders (sin Oracle configurado)
  if (grepl("^<", url) || grepl("^<", user) || grepl("^<", password)) {
    message("AVISO: credenciales Oracle placeholder -> se OMITE el write (tabla ",
            esquema, ".", tabla, ").")
    message("Resultado en memoria: ", nrow(df), " filas x ", ncol(df), " columnas")
    return(invisible(nrow(df)))
  }

  out <- df
  out[] <- lapply(out, function(x) if (is.factor(x)) as.character(x) else x)
  for (nm in names(out)) {
    if (inherits(out[[nm]], "Date")) {
      out[[nm]] <- format(out[[nm]], "%Y-%m-%d %H:%M:%S")
    }
  }
  out <- as.data.frame(out, stringsAsFactors = FALSE)

  drv_ora <- RJDBC::JDBC("oracle.jdbc.OracleDriver", ojdbc_jar)
  con <- DBI::dbConnect(drv_ora, url, user, password)
  on.exit(try(DBI::dbDisconnect(con), silent = TRUE), add = TRUE)

  RJDBC::dbSendUpdate(con, "ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS'")
  RJDBC::dbSendUpdate(con, paste("TRUNCATE TABLE ", esquema, ".", tabla, sep = ""))
  DBI::dbWriteTable(con, tabla, out, overwrite = FALSE, append = TRUE, row.names = FALSE)

  n_out <- DBI::dbGetQuery(con, paste("SELECT COUNT(*) AS N FROM ", esquema, ".", tabla, sep = ""))$N
  DBI::dbDisconnect(con)
  on.exit(NULL)

  message(tabla, ": ", nrow(out), " filas -> ", esquema, ".", tabla, " (", n_out, " en BD)")
  invisible(n_out)
}
