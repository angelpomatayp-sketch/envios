# TrackCargo Pro — Web, SSR y API

## 1. Resumen y alcance
- Plataforma 100% web, mobile-first y responsive para clientes finales (uso en móviles) y panel/admin. Conectividad online (no se implementará modo offline/cola de eventos).
- Objetivo: rastreo en tiempo real, visibilidad de estado y ETA, y gestión administrativa/logística.
- Stack elegido: Frontend `Next.js` (SSR/PWA) + Backend `NestJS` (REST + WebSockets). Cache/pub-sub con Redis (Render “Valor clave”) y base de datos recomendada: Postgres + PostGIS para geodatos.

## 2. Conectividad y rol de ruta
- Escenario definido: solo online. El conductor (si se usa) opera con web móvil/PWA y requiere conectividad para registrar hitos y ubicaciones. No habrá caché offline ni sincronización diferida.

## 3. Arquitectura actual (repo)
- `web/`: Next.js 16 (app router, TypeScript, ESLint). Scripts: `npm run dev`, `npm run build`, `npm run start`.
- `api/`: NestJS 11 (TypeScript, ESLint). Scripts: `npm run start:dev`, `npm run build`, `npm run start:prod`.
- `.gitignore` en raíz cubre dependencias, builds y entornos.
- Aún no hay modelo de datos ni endpoints específicos; esto es el esqueleto inicial.

## 4. Modelo de dominio (borrador)
- Usuario: roles `cliente`, `admin`, `conductor`. Autenticación (p.ej. Firebase Auth o JWT propio).
- Envío: id de tracking, remitente/destinatario, origen/destino, servicio, fechas (creación, ETA), estado actual, ruta asignada, conductor opcional.
- Hito de envío: evento con timestamp y estado; opcional ubicación y notas (ej. “Recogido”, “En tránsito”, “Intento fallido”).
- Ubicación de ruta: ping GPS con lat/long/accuracy/timestamp, asociado a envío y/o conductor.
- Evidencia: fotos/archivos de entrega o incidencia, enlazadas a un hito.
- Notificación: push/SMS/email configurada por evento (creación, cambio de estado, intento fallido, entrega).

## 5. Estados y eventos de tracking (online)
- Estados sugeridos: `creado`, `asignado`, `recogido`, `en_ruta`, `en_reparto` (última milla), `entregado`, `intentado_fallido` (con motivo), `devuelto`, `cancelado`.
- Eventos (hitos) mínimos:
  - `creado`: alta del envío.
  - `asignado_conductor`: asignación o cambio de ruta.
  - `recogido`: paquete recibido por conductor.
  - `en_ruta`: traslado intermedio (puede incluir pings de ubicación).
  - `en_reparto`: salida a entrega.
  - `entregado`: confirmación con evidencia opcional.
  - `intentado_fallido`: intento de entrega fallido (motivo + opcional evidencia).
  - `devuelto` / `cancelado`: cierre no exitoso.
- Tiempo real: publicar por WebSocket cada cambio de estado/hito y, opcionalmente, pings de ubicación (con rate limit).

## 6. Requisitos web y UX
- Mobile-first, responsive; PWA para acceso desde pantalla de inicio y push web.
- Tiempo real: canal WebSocket para eventos de tracking; SSE como alternativa si solo hay flujo de bajada.
- Performance en redes móviles: payloads ligeros, control de frecuencia de actualización de ubicación.

## 7. Despliegue en Render (un solo proveedor)
Crear dos servicios web (o uno si fusionas API+SSR):
- Frontend (`web/`):
  - Tipo: Servicio web. Directorio raíz: `web`.
  - Build: `npm install && npm run build`
  - Start: `npm run start`
  - Variables clave: `PORT` lo define Render; Next las respeta con `next start`.
- Backend (`api/`):
  - Tipo: Servicio web. Directorio raíz: `api`.
  - Build: `npm install && npm run build`
  - Start: `npm run start:prod`
  - Variables clave: `PORT` de Render; Nest lee `process.env.PORT`.
- Añadir servicios gestionados: `Postgres` y `Valor clave` (Redis) desde Render. Configurar las credenciales en env vars de `api` (y `web` si necesita).

## 8. Cómo correr en local
- Frontend:
  - `cd web`
  - `npm install`
  - Dev: `npm run dev`
  - Prod: `npm run build && npm run start`
- Backend:
  - `cd api`
  - `npm install`
  - Dev: `npm run start:dev`
  - Prod: `npm run build && npm run start:prod`

## 9. Pendientes próximos
- Añadir esquema de base de datos (Postgres/PostGIS) y env vars para `api`.
- Definir payloads de eventos WebSocket y endpoints REST/GraphQL iniciales.
- Diseñar pantallas clave (cliente y admin) y flujos de notificación push/SMS.
