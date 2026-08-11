# =============================================================================
# logica/ejemplo_demo.R  --  EJEMPLO de logica (reemplazar por tu logica)
#
# Zona de pegado: este es el UNICO .R de r/logica/ al copiar el arquetipo.
# Para un ETL nuevo, borrar/reemplazar este archivo por <tu_logica>.R
# (recuerda: un solo .R en esta carpeta; ver LEEME.md y r/CONTRATO.md).
#
# Entrada: data.frames con los nombres de `lecturas` en r/io/leer_h2.R (aqui: DEMO).
# Salida : data.frame RESULTADO (SALIDA_DF en r/main.R).
# Aislamiento: sin conexiones, jars ni library() dentro de esta carpeta.
# =============================================================================

RESULTADO <- DEMO %>%
  mutate(FEALTA = as.Date(FEALTA)) %>%
  select(ID, TXNOMBRE, FEALTA)
