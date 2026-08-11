# =============================================================================
# io/escribir_oracle.R
# SALIDA: data.frame -> Oracle REPOCSEP.RPT_MULTA_COERCITIVA
#   - CREATE TABLE si no existe (sql/create_ORACLE_RPT_MULTA_COERCITIVA.sql)
#   - TRUNCATE + INSERT
# Si url/user/password son placeholders "<...>", omite el write (smoke H2-only).
# =============================================================================

escribir_oracle <- function(df,
                            tabla = "RPT_MULTA_COERCITIVA",
                            esquema = "REPOCSEP",
                            url = "jdbc:oracle:thin:@//10.6.0.15:1532/dvoefacore",
                            user = "REPOCSEP",
                            password = "desarrollo24",
                            ojdbc_jar,
                            ddl_path = NULL) {
  if (missing(ojdbc_jar) || !file.exists(ojdbc_jar)) {
    stop("No se encuentra ojdbc_jar: ", ojdbc_jar)
  }

  if (grepl("^<", url) || grepl("^<", user) || grepl("^<", password)) {
    message("AVISO: credenciales Oracle placeholder -> se OMITE el write (tabla ",
            esquema, ".", tabla, ").")
    message("Resultado en memoria: ", nrow(df), " filas x ", ncol(df), " columnas")
    return(invisible(nrow(df)))
  }

  out <- df
  out[] <- lapply(out, function(x) if (is.factor(x)) as.character(x) else x)
  for (nm in names(out)) {
    if (inherits(out[[nm]], "POSIXct") || inherits(out[[nm]], "POSIXt")) {
      out[[nm]] <- format(out[[nm]], "%Y-%m-%d %H:%M:%S")
    } else if (inherits(out[[nm]], "Date")) {
      out[[nm]] <- format(out[[nm]], "%Y-%m-%d %H:%M:%S")
    }
  }
  out <- as.data.frame(out, stringsAsFactors = FALSE)

  drv_ora <- RJDBC::JDBC("oracle.jdbc.OracleDriver", ojdbc_jar)
  con <- DBI::dbConnect(drv_ora, url, user, password)
  on.exit(try(DBI::dbDisconnect(con), silent = TRUE), add = TRUE)

  RJDBC::dbSendUpdate(con, "ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS'")

  # CREATE si no existe (tabla en el esquema del usuario conectado = REPOCSEP)
  n_tbl <- DBI::dbGetQuery(
    con,
    paste0(
      "SELECT COUNT(*) AS N FROM user_tables WHERE table_name = '",
      toupper(tabla), "'"
    )
  )$N
  if (is.na(n_tbl) || as.integer(n_tbl) == 0L) {
    if (is.null(ddl_path)) {
      root_guess <- normalizePath(file.path(dirname(ojdbc_jar), ".."), mustWork = FALSE)
      ddl_path <- file.path(root_guess, "sql", "create_ORACLE_RPT_MULTA_COERCITIVA.sql")
    }
    if (!file.exists(ddl_path)) {
      stop("Tabla ", tabla, " no existe y no se encuentra DDL: ", ddl_path)
    }
    message("Creando tabla ", esquema, ".", tabla, " desde ", ddl_path)
    ddl <- paste(readLines(ddl_path, warn = FALSE), collapse = "\n")
    # quitar comentarios de linea y partir por ;
    ddl <- gsub("--[^\n]*", "\n", ddl)
    stmts <- trimws(unlist(strsplit(ddl, ";")))
    stmts <- stmts[nzchar(stmts)]
    for (st in stmts) {
      RJDBC::dbSendUpdate(con, st)
    }
  }

  fq <- paste0(esquema, ".", tabla)
  RJDBC::dbSendUpdate(con, paste0("TRUNCATE TABLE ", fq))
  DBI::dbWriteTable(con, tabla, out, overwrite = FALSE, append = TRUE, row.names = FALSE)

  n_out <- DBI::dbGetQuery(con, paste0("SELECT COUNT(*) AS N FROM ", fq))$N
  DBI::dbDisconnect(con)
  on.exit(NULL)

  message(tabla, ": ", nrow(out), " filas -> ", fq, " (", n_out, " en BD)")
  invisible(n_out)
}
