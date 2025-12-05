# TrackCargo Pro — Análisis y Alcance Web

## 1. Resumen
- Plataforma 100% web, mobile-first y responsive. Los usuarios finales operarán desde su navegador móvil; el panel/admin también debe adaptarse a escritorio y móvil.
- Objetivo: rastreo en tiempo real de envíos, visibilidad de estado y tiempos estimados, y gestión administrativa de la operación logística.
- Tecnologías de referencia: frontend web (SPA) + API REST/GraphQL + canal tiempo real (WebSocket/SSE). Persistencia en Firestore/Realtime DB y archivos en Cloud Storage. Autenticación en Firebase Auth. Notificaciones push web (FCM) y SMS opcional.

## 2. Roles y casos de uso
- Cliente final (web móvil): buscar envíos por código, ver estado y ubicación en tiempo real, recibir notificaciones, ver historial.
- Administrador/operador (panel web responsive): crear/editar envíos, asignar conductores, monitorear rutas, generar reportes y gestionar incidencias.
- Conductor/usuario de ruta (web móvil, opcional): registrar hitos de ruta, actualizar estado, subir fotos de evidencia. Este rol depende de la decisión de conectividad/offline (ver sección 3).

## 3. Sobre el usuario de ruta y la conectividad
- Escenario A (sin offline): si la ruta tiene conectividad razonable, el conductor puede usar la misma web móvil (PWA) y no se requiere app nativa. Menor complejidad.
- Escenario B (offline-first): si habrá zonas sin señal, se necesita modo offline para el rol de ruta: caché local, cola de eventos (check-ins, entregas, fotos) y sincronización cuando vuelva la conexión. Esto sí justifica un cliente con capacidades offline robustas (PWA con background sync y control de colas).
- Definir pronto qué escenario aplica, porque impacta arquitectura del frontend (capa de sincronización), API y modelado de eventos de ruta.

## 4. Arquitectura de alto nivel (web)
- Capa de presentación: aplicaciones web responsive para cliente, operador y, si aplica, conductor (PWA para soporte móvil y push).
- Capa de servicios: API REST/GraphQL para CRUD y consultas; canal de tiempo real para tracking (WebSocket/SSE); servicios de autenticación y autorización por rol; notificaciones push web/SMS.
- Capa de datos: Firestore/Realtime DB para estados y tracking; Cloud Storage para evidencias (fotos); caché en cliente (IndexedDB) si se adopta modo offline.
- Integraciones externas: Firebase Auth, FCM (push web), Maps API para geocodificación/mapas, SMS gateway (Twilio/u otro) para OTP o alertas.

## 5. UX/UI y requisitos web
- Mobile-first, responsive; navegación simple en pantallas pequeñas.
- PWA recomendada para acceso desde pantalla de inicio y notificaciones push.
- Desempeño en redes móviles: optimizar payloads, uso de imágenes y frecuencias de actualización.
- Accesibilidad básica: contraste, tamaños táctiles mínimos, etiquetas claras.

## 6. Riesgos y pendientes
- Decidir necesidad de modo offline para el rol de ruta.
- Definir SLA de “tiempo real” (frecuencia de ubicación, costo de datos, batería).
- Política de notificaciones: qué eventos generan push/SMS y a quién.
- Seguridad y privacidad: protección de datos personales y geolocalización; control de acceso por rol.

## 7. Próximos pasos sugeridos
- Cerrar la decisión de conectividad para el rol de ruta (Escenario A vs B).
- Establecer el set mínimo de pantallas web para cliente y admin (MVP).
- Normalizar el modelo de eventos de tracking (estados, hitos, evidencias) y su impacto en el API.
