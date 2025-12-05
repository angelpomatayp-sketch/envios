-- TrackCargo Pro - Esquema base (Postgres + PostGIS)
-- Ejecutar con: psql -d <db> -f db/schema.sql

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- Usuarios
CREATE TABLE IF NOT EXISTS users (
    id              uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           text UNIQUE,
    phone           text,
    name            text,
    role            text NOT NULL CHECK (role IN ('cliente', 'admin', 'conductor')),
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

-- Envios
CREATE TABLE IF NOT EXISTS shipments (
    id              uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    tracking_code   text NOT NULL UNIQUE,
    sender_name     text,
    recipient_name  text,
    origin_text     text,
    origin_geom     geometry(Point, 4326),
    destination_text text,
    destination_geom geometry(Point, 4326),
    service_type    text,
    eta             timestamptz,
    status          text NOT NULL CHECK (status IN (
        'creado','asignado','recogido','en_ruta','en_reparto','entregado','intentado_fallido','devuelto','cancelado'
    )),
    conductor_id    uuid REFERENCES users(id) ON DELETE SET NULL,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

-- Ubicaciones (pings de ruta)
CREATE TABLE IF NOT EXISTS locations (
    id              uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    geom            geometry(Point, 4326) NOT NULL,
    accuracy        double precision,
    recorded_at     timestamptz NOT NULL DEFAULT now(),
    source          text NOT NULL CHECK (source IN ('gps','manual')),
    conductor_id    uuid REFERENCES users(id) ON DELETE SET NULL
);

-- Evidencias (fotos/documentos)
CREATE TABLE IF NOT EXISTS evidences (
    id              uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id     uuid NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    url             text NOT NULL,
    kind            text NOT NULL CHECK (kind IN ('foto','doc')),
    metadata        jsonb,
    created_at      timestamptz NOT NULL DEFAULT now()
);

-- Hitos de envío
CREATE TABLE IF NOT EXISTS shipment_events (
    id              uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    shipment_id     uuid NOT NULL REFERENCES shipments(id) ON DELETE CASCADE,
    event_type      text NOT NULL CHECK (event_type IN (
        'creado','asignado_conductor','recogido','en_ruta','en_reparto','entregado','intentado_fallido','devuelto','cancelado'
    )),
    message         text,
    location_id     uuid REFERENCES locations(id) ON DELETE SET NULL,
    evidence_id     uuid REFERENCES evidences(id) ON DELETE SET NULL,
    created_at      timestamptz NOT NULL DEFAULT now()
);

-- Notificaciones
CREATE TABLE IF NOT EXISTS notifications (
    id              bigserial PRIMARY KEY,
    shipment_id     uuid REFERENCES shipments(id) ON DELETE CASCADE,
    kind            text NOT NULL CHECK (kind IN ('push','sms','email')),
    recipient       text,
    payload         jsonb,
    status          text NOT NULL CHECK (status IN ('pendiente','enviado','error')),
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

-- Índices adicionales
CREATE INDEX IF NOT EXISTS idx_shipments_conductor ON shipments(conductor_id);
CREATE INDEX IF NOT EXISTS idx_events_shipment ON shipment_events(shipment_id);
CREATE INDEX IF NOT EXISTS idx_events_type ON shipment_events(event_type);
CREATE INDEX IF NOT EXISTS idx_locations_geom ON locations USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_locations_conductor ON locations(conductor_id);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(status);
