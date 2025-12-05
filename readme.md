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

## 10. Esquema de base de datos (Postgres/PostGIS, borrador)
- users: id (uuid), email, phone, nombre, rol (`cliente|admin|conductor`), hash de auth externo (si aplica), timestamps.
- shipments: id (uuid), tracking_code (unique), remitente/destinatario (strings), origen/destino (texto + coords Point), servicio, eta, estado_actual, conductor_id (fk users), created_at/updated_at.
- shipment_events (hitos): id (uuid), shipment_id (fk), tipo (`creado|asignado|recogido|en_ruta|en_reparto|entregado|intentado_fallido|devuelto|cancelado`), message/motivo, evidencia_id (fk), location_id (fk opcional), created_at.
- locations: id (uuid), geom Point (PostGIS), accuracy, recorded_at, source (`gps|manual`), conductor_id opcional.
- evidences: id (uuid), shipment_id (fk), url, tipo (`foto|doc`), metadata json, created_at.
- notifications: id, shipment_id, tipo (`push|sms|email`), destinatario, payload json, status (`pendiente|enviado|error`), timestamps.
- Índices claves: `shipments.tracking_code`, GIST en `locations.geom`, `shipment_events.shipment_id`, `notifications.status`.

## 11. API y WebSockets (mínimo viable)
- REST (api):
  - `POST /auth/login` (si no se usa Firebase Auth).
  - `GET /shipments/:tracking_code` → detalle + últimos hitos.
  - `GET /shipments/:tracking_code/events` → historial.
  - `POST /shipments` (admin) → crear envío.
  - `PATCH /shipments/:id/assign` (admin) → asignar conductor.
  - `POST /shipments/:id/events` (conductor/admin) → registrar hito con estado y evidencia opcional.
  - `POST /shipments/:id/locations` (conductor) → pings de ubicación (rate-limit server-side).
- WebSocket:
  - Canal `shipments.{tracking_code}`: eventos `hito_actualizado`, `ubicacion_actualizada`.
  - Mensajes ejemplo:
    - Hito: `{ type: "hito_actualizado", data: { trackingCode, estado, eventoId, timestamp, motivo?, evidenciaUrl?, location? } }`
    - Ubicación: `{ type: "ubicacion_actualizada", data: { trackingCode, lat, lng, accuracy, timestamp } }`
- Seguridad:
  - Roles: `cliente` puede leer su envío por tracking y recibir WS; `conductor` puede publicar eventos/ubicaciones de envíos asignados; `admin` CRUD completo.
  - Autenticación: JWT propio o Firebase; proteger WS con token.

## 12. Variables de entorno sugeridas
- Backend (`api`): `DATABASE_URL` (Postgres), `REDIS_URL`, `PORT`, `JWT_SECRET` o credenciales Firebase, `STORAGE_BASE_URL` para evidencias.
- Frontend (`web`): `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_WS_URL`, claves públicas para mapas (si aplica).
