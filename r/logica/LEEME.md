# r/logica — zona de pegado

Un solo archivo `.R` (hoy: `consolidar_multas.R`).

- Entrada: data.frames `GS1`, `GS2`, `ETAPAS`, `ORA`, `MYSQL` (ver `r/io/leer_h2.R`).
- Salida: data.frame `RESULTADO` con `FUENTE` (UNION fase 1).
- Sin `library()`, conexiones ni jars aquí.
