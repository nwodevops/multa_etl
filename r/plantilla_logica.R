# =============================================================================
# plantilla_logica.R  --  PLANTILLA DE LOGICA (copia fuera de r/logica/)
#
# PARA UN ETL NUEVO:
#   1. Copiar este archivo a  r/logica/<tu_logica>.R  (un solo .R en r/logica/)
#   2. Escribir tu transformacion usando los data.frames de entrada
#      (nombres = claves de `lecturas` en r/io/leer_h2.R).
#   3. Dejar al final un data.frame con el nombre SALIDA_DF (default "RESULTADO").
#
# AISLAMIENTO (reglas):
#   - NO abrir conexiones ni cargar jars/librerias: el I/O lo hace main.R/io/.
#   - NO usar rutas de archivo: el data.frame ya viene en memoria.
#   - Solo dplyr/base sobre los data.frames del entorno.
# =============================================================================

# Ejemplo trivial sobre la lectura DEMO (DEMO_TABLA_EJEMPLO):
# DEMO -> RESULTADO
RESULTADO <- DEMO %>%
  mutate(FEALTA = as.Date(FEALTA)) %>%
  select(ID, TXNOMBRE, FEALTA)

# <--- AQUI VA TU LOGICA (deja el df con el nombre SALIDA_DF) --->
