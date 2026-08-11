# CONTRATO — capa R del arquetipo Apache Hop + H2

El proyecto es un **arquetipo**: el I/O es genérico y reutilizable; solo se cambia la
**lógica de negocio** pegando un `.R` en `r/logica/`. Cualquier lógica nueva (R o Python
en el futuro) debe respetar este contrato de entrada y salida.

```
r/main.R            orquesta: SETUP → io/leer_h2.R → [único .R de logica/] → io/escribir_oracle.R
r/io/leer_h2.R      ENTRADA genérica : H2 mem:csep → data.frames (nombres = claves de `lecturas`)
r/logica/           LOGICA de negocio : zona de pegado (un solo .R), entrada/salida en entorno
r/io/escribir_oracle.R  SALIDA genérica: data.frame → tabla Oracle (TRUNCATE+INSERT; skip si placeholders)
```

## Entrada (la deja `r/io/leer_h2.R`)

Cada clave de la lista `lecturas` (en `leer_h2.R`) se convierte en un data.frame con
**ese mismo nombre** en el entorno. La lógica recibe esos data.frames ya cargados.

| Nombre | Fuente (query en `leer_h2.R`) |
|---|---|
| `DEMO` | `SELECT ID, TXNOMBRE, FEALTA FROM PUBLIC.DEMO_TABLA_EJEMPLO` |

Para un ETL nuevo, agregar/editar entradas en `lecturas`; los nombres pasan a ser el
contrato de entrada de tu lógica.

## Salida (la consume `r/io/escribir_oracle.R`)

La lógica debe dejar en el entorno un data.frame con el nombre de `SALIDA_DF`
(default **`RESULTADO`**, configurable en `r/main.R`). Columnas/tipos deben mapear a la
tabla destino.

El escritor normaliza antes de insertar (factores→character, Date→ISO string) y hace
`ALTER SESSION NLS_DATE_FORMAT` + `TRUNCATE` + `INSERT` + `COUNT`. Si las credenciales
Oracle son placeholders, omite el write con warning (smoke test H2-only).

## Cómo crear otro ETL en este arquetipo

1. Copiar `r/plantilla_logica.R` → `r/logica/<tu_logica>.R` (**un solo .R** en esa carpeta).
2. Escribir tu transformación usando los data.frames de entrada (nombres de `lecturas`)
   y dejar el data.frame `RESULTADO`.
3. Completar tabla/esquema/credenciales en la llamada a `escribir_oracle()` (o sus defaults
   en `r/io/escribir_oracle.R`).
4. Reutilizar `r/io/` y `r/main.R` sin tocarlos. Para portar a Python, replicar este
   contrato con el mismo nombre de data.frames/columnas.

## Reglas

- **Aislamiento de la lógica**: en `r/logica/` no se abren conexiones, no se cargan jars
  ni `library()`, no se usan rutas de archivo. Solo dplyr/base sobre los data.frames del
  entorno.
- **No mover** la línea `options(java.parameters=...)` en `r/main.R`: debe ejecutarse
  **antes** de `library(RJDBC)`/`rJava`.
- **No dejar** credenciales reales como defaults del arquetipo: completar los `<...>` por
  proyecto. Los passwords quedan en texto plano en el repo (igual que `project-config.json`).
