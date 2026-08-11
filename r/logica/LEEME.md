# Zona de pegado de logica R

- Copia aqui **un solo** archivo `.R` con tu logica de negocio.
- `r/main.R` auto-descubre el unico `.R` de esta carpeta y lo ejecuta.
  Error si hay 0 o mas de 1 archivo.
- Entrada: data.frames ya cargados (nombres = claves de `lecturas` en `r/io/leer_h2.R`).
- Salida: deja un data.frame con el nombre `RESULTADO` (configurable en `r/main.R`, `SALIDA_DF`).
- No abrir conexiones/jars aqui: el I/O vive en `r/io/`.

Viene con un ejemplo (`ejemplo_demo.R`) para el smoke test. Al pegar tu lógica,
borra/reemplaza ese archivo (mantén un solo `.R`). Plantilla: `../plantilla_logica.R`.
