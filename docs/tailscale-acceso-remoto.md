# Acceso remoto vía Tailscale (H2)

Cómo conectarse al H2 de esta PC desde casa usando **Tailscale** (mesh VPN). Permite llegar a la BD staging (`mem:csep`) y a cualquier BD H2 que levante el server local.

## Estado configurado

- **Máquina**: `lim-w1986` (esta PC).
- **IP Tailscale**: `100.109.97.75` (fija mientras la PC esté en la tailnet y logueada).
- **Servicio**: `Tailscale` (Windows, Automatic).
- **H2**: puertos `9092` (TCP) y `8082` (web console), escuchando en todas las interfaces.

## Cómo se conecta desde casa

Requisito: Tailscale instalado y logueado con la **misma cuenta** en la PC de casa.

1. **JDBC** (Hop, R, DBeaver, etc.):
   ```
   jdbc:h2:tcp://100.109.97.75:9092/<nombre_db>
   ```
   user `sa` / pass `csep`. El server arranca con `-ifNotExists`, así que cualquier nombre de BD se crea al conectar.

2. **Web console H2**: `http://100.109.97.75:8082` → JDBC URL `jdbc:h2:tcp://100.109.97.75:9092/<nombre_db>`, user `sa`, pass `csep`.

3. **Verificación rápida** (desde casa): `Test-NetConnection 100.109.97.75 -Port 9092` (PowerShell) debe responder `TcpTestSucceeded : True`.

## Cambios aplicados en el repo

- `h2/scripts/start_h2.bat`: se agregaron los flags `-tcpAllowOthers -webAllowOthers` al arranque del server H2. **Sin esto, H2 rechaza conexiones que no vienen de localhost aunque escuche en `0.0.0.0`.**
- La conexión de Hop a H2 sigue usando `localhost` (`DB_H2_*` en `project-config.json`); el acceso remoto no afecta las corridas locales.

## Notas y limitaciones

- **`mem:csep` es in-memory**: el staging se borra al parar el server y se resetea en cada corrida del workflow. Para procesos propios usar otra BD (ej. `mem:minito`) o una BD en **archivo** para que persista.
- **Oracle/MySQL NO se alcanzan por Tailscale directamente**: son servidores internos de la red OEFA (`odaprod-scan:1534`, `10.1.1.217:3306`). Tailscale solo enruta hacia esta PC. Para accederlos desde casa se necesita esta PC como puente (subnet router o túnel SSH) — no implementado.
- **Reinicio**: si esta PC se apaga o el server H2 se detiene, la BD desaparece. Al volver, correr `h2\scripts\start_h2.bat` y, si aplica, `reset_and_create.bat` para el staging.
- **Seguridad**: el acceso queda restringido a tu tailnet (nadie más en internet). H2 no queda expuesto públicamente.

## Orden típico para conectarse

1. En esta PC: `h2\scripts\start_h2.bat` (levanta H2).
2. Verificar Tailscale activo (suele bastar con que el servicio esté corriendo).
3. Desde casa: conectar con el JDBC URL de arriba a `100.109.97.75`.
