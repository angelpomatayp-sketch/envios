# TrackCargo Pro — Web, SSR y API

## 1. Resumen y alcance
- Plataforma 100% web, mobile-first y responsive para clientes finales (uso en móviles) y panel/admin. En el futuro, conductor web móvil (PWA) si se requiere.
- Objetivo: rastreo en tiempo real, visibilidad de estado y ETA, y gestión administrativa/logística.
- Stack elegido: Frontend `Next.js` (SSR/PWA) + Backend `NestJS` (REST + WebSockets). Cache/pub-sub con Redis (Render “Valor clave”) y base de datos recomendada: Postgres + PostGIS para geodatos.

## 2. Conectividad y rol de ruta
- Escenario A (sin offline): el conductor usa la misma web móvil (PWA), con conectividad razonable; menor complejidad.
- Escenario B (offline-first): si hay zonas sin señal, se añade caché local/cola de eventos y sync diferido. A decidir pronto porque impacta arquitectura cliente/API.

## 3. Arquitectura actual (repo)
- `web/`: Next.js 16 (app router, TypeScript, ESLint). Scripts: `npm run dev`, `npm run build`, `npm run start`.
- `api/`: NestJS 11 (TypeScript, ESLint). Scripts: `npm run start:dev`, `npm run build`, `npm run start:prod`.
- `.gitignore` en raíz cubre dependencias, builds y entornos.
- Aún no hay modelo de datos ni endpoints específicos; esto es el esqueleto inicial.

## 4. Requisitos web y UX
- Mobile-first, responsive; PWA para acceso desde pantalla de inicio y push web.
- Tiempo real: canal WebSocket para eventos de tracking; SSE como alternativa si solo hay flujo de bajada.
- Performance en redes móviles: payloads ligeros, control de frecuencia de actualización de ubicación.

## 5. Despliegue en Render (un solo proveedor)
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

## 6. Cómo correr en local
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

## 7. Pendientes próximos
- Definir Escenario A/B de conectividad para conductor.
- Modelar entidades (envío, hitos, ubicaciones, evidencias) y estados de tracking con sus eventos en tiempo real.
- Añadir configuración de Postgres/Redis y variables de entorno (no subir `.env`).
- Diseñar pantallas clave (cliente y admin) y rutas API iniciales. 
