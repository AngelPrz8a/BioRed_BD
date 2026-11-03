-- =====================================================
-- Script de creación de base de datos (MySQL 8.0.16+)
-- Versión 2: incorpora visibilidad de módulos, destino de
-- solicitudes, tabla de accesos, separación de roles,
-- unicidad usuario-grupo y contexto de grupo en auditoría.
-- =====================================================

DROP DATABASE IF EXISTS biored_db;
CREATE DATABASE biored_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE biored_db;

-- -----------------------------------------------------
-- usuarios
-- rol_global: alcance de TODA la plataforma.
-- "coordinador" NO es un rol global: se define por grupo
-- en grupo_usuarios.rol_grupo.
-- -----------------------------------------------------
CREATE TABLE usuarios (
  id_usuario       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre           VARCHAR(100) NOT NULL,
  correo           VARCHAR(150) NOT NULL,
  contrasena_hash  VARCHAR(255) NOT NULL,
  rol_global       ENUM('administrador','usuario') NOT NULL DEFAULT 'usuario',
  estado_cuenta    ENUM('activa','inactiva','suspendida','pendiente') NOT NULL DEFAULT 'pendiente',
  fecha_registro   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_usuario),
  UNIQUE KEY uk_usuarios_correo (correo)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- etiquetas
-- -----------------------------------------------------
CREATE TABLE etiquetas (
  id_etiqueta  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre       VARCHAR(100) NOT NULL,
  estado       ENUM('activa','inactiva') NOT NULL DEFAULT 'activa',
  PRIMARY KEY (id_etiqueta)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- usuario_etiquetas
-- -----------------------------------------------------
CREATE TABLE usuario_etiquetas (
  id_usuario        INT UNSIGNED NOT NULL,
  id_etiqueta       INT UNSIGNED NOT NULL,
  asignado_por      INT UNSIGNED NULL,
  fecha_asignacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_usuario, id_etiqueta),
  CONSTRAINT fk_ue_usuario   FOREIGN KEY (id_usuario)   REFERENCES usuarios (id_usuario)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ue_etiqueta  FOREIGN KEY (id_etiqueta)  REFERENCES etiquetas (id_etiqueta)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ue_asignador FOREIGN KEY (asignado_por) REFERENCES usuarios (id_usuario)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- grupos
-- -----------------------------------------------------
CREATE TABLE grupos (
  id_grupo        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre          VARCHAR(100) NOT NULL,
  descripcion     TEXT NULL,
  visibilidad     ENUM('publico','privado') NOT NULL DEFAULT 'privado',
  fecha_creacion  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_grupo),
  UNIQUE KEY uk_grupos_nombre (nombre)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- modulos
-- visibilidad: publico | identificados | grupo | privado
-- Si es 'grupo', id_grupo es obligatorio.
-- (FK de id_grupo con RESTRICT porque MySQL no permite
--  acciones referenciales en columnas usadas en un CHECK)
-- -----------------------------------------------------
CREATE TABLE modulos (
  id_modulo           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_propietario      INT UNSIGNED NOT NULL,
  id_grupo            INT UNSIGNED NULL,
  visibilidad         ENUM('publico','identificados','grupo','privado') NOT NULL DEFAULT 'privado',
  fecha_modificacion  DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  modificado_por      INT UNSIGNED NULL,
  PRIMARY KEY (id_modulo),
  CONSTRAINT fk_mod_propietario  FOREIGN KEY (id_propietario) REFERENCES usuarios (id_usuario)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_mod_grupo        FOREIGN KEY (id_grupo)       REFERENCES grupos (id_grupo),
  CONSTRAINT fk_mod_modificador  FOREIGN KEY (modificado_por) REFERENCES usuarios (id_usuario)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT ck_mod_visibilidad_grupo
    CHECK (visibilidad <> 'grupo' OR id_grupo IS NOT NULL)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- sensores
-- -----------------------------------------------------
CREATE TABLE sensores (
  id_sensor  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_modulo  INT UNSIGNED NOT NULL,
  tipo       VARCHAR(50) NOT NULL,
  PRIMARY KEY (id_sensor),
  CONSTRAINT fk_sen_modulo FOREIGN KEY (id_modulo) REFERENCES modulos (id_modulo)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- visualizacion
-- -----------------------------------------------------
CREATE TABLE visualizacion (
  id_visualizacion    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_sensor           INT UNSIGNED NOT NULL,
  id_usuario          INT UNSIGNED NOT NULL,
  tipo                VARCHAR(50) NOT NULL,
  configuracion       JSON NULL,
  fecha_creacion      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_modificacion  DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_visualizacion),
  CONSTRAINT fk_vis_sensor  FOREIGN KEY (id_sensor)  REFERENCES sensores (id_sensor)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_vis_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- solicitudes
-- Cada tipo exige un destino explícito:
--   acceso_modulo     -> id_modulo + nivel_acceso_solicitado
--   ingreso_grupo     -> id_grupo  + rol_solicitado
--   cambio_rol_grupo  -> id_grupo  + rol_solicitado
-- (FK de destino con RESTRICT por la restricción de MySQL
--  sobre CHECK + acciones referenciales)
-- -----------------------------------------------------
CREATE TABLE solicitudes (
  id_solicitud               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_solicitante             INT UNSIGNED NOT NULL,
  id_responsable             INT UNSIGNED NULL,
  tipo                       ENUM('acceso_modulo','ingreso_grupo','cambio_rol_grupo') NOT NULL,
  id_modulo                  INT UNSIGNED NULL,
  id_grupo                   INT UNSIGNED NULL,
  rol_solicitado             ENUM('miembro','coordinador') NULL,
  nivel_acceso_solicitado    ENUM('lectura','escritura') NULL,
  estado                     ENUM('pendiente','aprobada','rechazada','cancelada') NOT NULL DEFAULT 'pendiente',
  fecha_creacion             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_resolucion           DATETIME NULL,
  justificacion_solicitante  TEXT NULL,
  respuesta_resolucion       TEXT NULL,
  PRIMARY KEY (id_solicitud),
  CONSTRAINT fk_sol_solicitante FOREIGN KEY (id_solicitante) REFERENCES usuarios (id_usuario)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_sol_responsable FOREIGN KEY (id_responsable) REFERENCES usuarios (id_usuario)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_sol_modulo      FOREIGN KEY (id_modulo)      REFERENCES modulos (id_modulo),
  CONSTRAINT fk_sol_grupo       FOREIGN KEY (id_grupo)       REFERENCES grupos (id_grupo),
  CONSTRAINT ck_sol_destino CHECK (
    (tipo = 'acceso_modulo'
       AND id_modulo IS NOT NULL AND nivel_acceso_solicitado IS NOT NULL
       AND id_grupo IS NULL      AND rol_solicitado IS NULL)
    OR
    (tipo IN ('ingreso_grupo','cambio_rol_grupo')
       AND id_grupo IS NOT NULL  AND rol_solicitado IS NOT NULL
       AND id_modulo IS NULL     AND nivel_acceso_solicitado IS NULL)
  ),
  CONSTRAINT ck_sol_resolucion CHECK (
    estado = 'pendiente' OR fecha_resolucion IS NOT NULL
  )
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- grupo_usuarios
-- rol_grupo: alcance LIMITADO al grupo de la fila.
-- Un coordinador de un grupo no administra otros grupos.
-- UNIQUE (id_usuario, id_grupo): una única pertenencia por pareja
-- (para reingresos se reutiliza la fila cambiando estado/fechas).
-- -----------------------------------------------------
CREATE TABLE grupo_usuarios (
  id_grupo_usuarios    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_usuario           INT UNSIGNED NOT NULL,
  id_grupo             INT UNSIGNED NOT NULL,
  id_solicitud_origen  INT UNSIGNED NULL,
  estado               ENUM('activo','inactivo','pendiente') NOT NULL DEFAULT 'activo',
  rol_grupo            ENUM('miembro','coordinador') NOT NULL DEFAULT 'miembro',
  fecha_ingreso        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_modificacion   DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_grupo_usuarios),
  UNIQUE KEY uk_grupo_usuario (id_usuario, id_grupo),
  CONSTRAINT fk_gu_usuario   FOREIGN KEY (id_usuario)          REFERENCES usuarios (id_usuario)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_gu_grupo     FOREIGN KEY (id_grupo)            REFERENCES grupos (id_grupo)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_gu_solicitud FOREIGN KEY (id_solicitud_origen) REFERENCES solicitudes (id_solicitud)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- accesos: permisos vigentes sobre módulos, separados de la
-- solicitud que los originó. Permite consultar, revocar y caducar.
-- -----------------------------------------------------
CREATE TABLE accesos (
  id_acceso          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_modulo          INT UNSIGNED NOT NULL,
  id_usuario         INT UNSIGNED NOT NULL,
  id_solicitud       INT UNSIGNED NULL,
  nivel_acceso       ENUM('lectura','escritura') NOT NULL DEFAULT 'lectura',
  estado             ENUM('vigente','revocado','caducado') NOT NULL DEFAULT 'vigente',
  concedido_por      INT UNSIGNED NULL,
  fecha_concesion    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_expiracion   DATETIME NULL,
  revocado_por       INT UNSIGNED NULL,
  fecha_revocacion   DATETIME NULL,
  motivo_revocacion  TEXT NULL,
  -- Columna generada: vale 1 si el acceso está vigente, NULL si no.
  -- Con el UNIQUE evita dos accesos vigentes para el mismo usuario y módulo.
  vigente_flag       TINYINT GENERATED ALWAYS AS (IF(estado = 'vigente', 1, NULL)) STORED,
  PRIMARY KEY (id_acceso),
  UNIQUE KEY uk_acceso_solicitud (id_solicitud),
  UNIQUE KEY uk_acceso_vigente (id_modulo, id_usuario, vigente_flag),
  KEY idx_acc_usuario (id_usuario),
  KEY idx_acc_expiracion (estado, fecha_expiracion),
  CONSTRAINT fk_acc_modulo     FOREIGN KEY (id_modulo)     REFERENCES modulos (id_modulo)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_acc_usuario    FOREIGN KEY (id_usuario)    REFERENCES usuarios (id_usuario)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_acc_solicitud  FOREIGN KEY (id_solicitud)  REFERENCES solicitudes (id_solicitud)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_acc_concedido  FOREIGN KEY (concedido_por) REFERENCES usuarios (id_usuario)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_acc_revocado   FOREIGN KEY (revocado_por)  REFERENCES usuarios (id_usuario)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT ck_acc_revocacion CHECK (estado <> 'revocado' OR fecha_revocacion IS NOT NULL),
  CONSTRAINT ck_acc_expiracion CHECK (fecha_expiracion IS NULL OR fecha_expiracion > fecha_concesion)
) ENGINE=InnoDB;

-- Vista de accesos efectivamente vigentes (considera la caducidad por fecha)
CREATE VIEW v_accesos_vigentes AS
SELECT *
FROM accesos
WHERE estado = 'vigente'
  AND (fecha_expiracion IS NULL OR fecha_expiracion > NOW());

-- Marca como 'caducado' los accesos vencidos (requiere SET GLOBAL event_scheduler = ON;)
CREATE EVENT ev_caducar_accesos
  ON SCHEDULE EVERY 1 HOUR
  DO
    UPDATE accesos
       SET estado = 'caducado'
     WHERE estado = 'vigente'
       AND fecha_expiracion IS NOT NULL
       AND fecha_expiracion <= NOW();

-- -----------------------------------------------------
-- auditorias
-- Sin FK a propósito (el historial debe sobrevivir a los datos).
-- id_grupo_contexto: copia del grupo al que pertenecía el recurso
-- en el momento del cambio (NULL si el cambio es global).
-- Si un módulo cambia de grupo, registrar el cambio de id_grupo con
-- el grupo anterior como contexto, y opcionalmente otra fila con el nuevo.
-- -----------------------------------------------------
CREATE TABLE auditorias (
  id_auditoria       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  entidad            VARCHAR(100) NOT NULL,
  entidad_id         INT UNSIGNED NOT NULL,
  accion             ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  campo              VARCHAR(100) NULL,
  valor_anterior     TEXT NULL,
  valor_nuevo        TEXT NULL,
  usuario_id         INT UNSIGNED NULL,
  id_grupo_contexto  INT UNSIGNED NULL,
  fecha              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_auditoria),
  KEY idx_aud_entidad (entidad, entidad_id),
  KEY idx_aud_usuario (usuario_id),
  KEY idx_aud_grupo_fecha (id_grupo_contexto, fecha)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Índices adicionales
-- -----------------------------------------------------
CREATE INDEX idx_ue_etiqueta      ON usuario_etiquetas (id_etiqueta);
CREATE INDEX idx_gu_grupo         ON grupo_usuarios (id_grupo);
CREATE INDEX idx_mod_propietario  ON modulos (id_propietario);
CREATE INDEX idx_mod_grupo        ON modulos (id_grupo);
CREATE INDEX idx_sen_modulo       ON sensores (id_modulo);
CREATE INDEX idx_vis_sensor       ON visualizacion (id_sensor);
CREATE INDEX idx_vis_usuario      ON visualizacion (id_usuario);
CREATE INDEX idx_sol_solicitante  ON solicitudes (id_solicitante);
CREATE INDEX idx_sol_responsable  ON solicitudes (id_responsable);
CREATE INDEX idx_sol_modulo       ON solicitudes (id_modulo);
CREATE INDEX idx_sol_grupo        ON solicitudes (id_grupo);
