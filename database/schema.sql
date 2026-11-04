CREATE DATABASE IF NOT EXISTS fleetdb
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE fleetdb;

CREATE TABLE organizations (
  id         CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  name       VARCHAR(150) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE users (
  id            CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  org_id        CHAR(36) NOT NULL,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role          ENUM('FLEET_MANAGER','MECHANIC','DRIVER') NOT NULL,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (org_id) REFERENCES organizations(id),
  INDEX idx_users_org (org_id)
) ENGINE=InnoDB;


CREATE TABLE vehicles (
  id                 CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  org_id             CHAR(36) NOT NULL,
  plate_number       VARCHAR(20) NOT NULL,
  model              VARCHAR(50) NOT NULL,
  year               SMALLINT NOT NULL,
  fuel_type          VARCHAR(20) NOT NULL,
  status             ENUM('ACTIVE','DUE_FOR_SERVICE','IN_MAINTENANCE','RETIRED') DEFAULT 'ACTIVE',
  current_odometer   INT NOT NULL DEFAULT 0,
  insurance_expiry   DATE NULL,
  revenue_lic_expiry DATE NULL,
  deleted_at         TIMESTAMP NULL,
  created_at         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (org_id) REFERENCES organizations(id),
  UNIQUE KEY uq_org_plate (org_id, plate_number),
  INDEX idx_vehicle_org_status (org_id, status)
) ENGINE=InnoDB;

CREATE TABLE service_rules (
  id                    CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  vehicle_id            CHAR(36) NOT NULL,
  name                  VARCHAR(100) NOT NULL,
  interval_km           INT NOT NULL,
  last_service_odometer INT NOT NULL DEFAULT 0,
  FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
  INDEX idx_rules_vehicle (vehicle_id)
) ENGINE=InnoDB;

CREATE TABLE job_cards (
  id                  CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  vehicle_id          CHAR(36) NOT NULL,
  mechanic_id         CHAR(36) NULL,
  service_rule_id     CHAR(36) NULL,
  title               VARCHAR(150) NOT NULL,
  description         TEXT NULL,
  status              ENUM('OPEN','IN_PROGRESS','COMPLETED','CANCELLED') DEFAULT 'OPEN',
  labor_cost          DECIMAL(10,2) NOT NULL DEFAULT 0,
  odometer_at_service INT NULL,
  opened_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at        TIMESTAMP NULL,
  FOREIGN KEY (vehicle_id)      REFERENCES vehicles(id),
  FOREIGN KEY (mechanic_id)     REFERENCES users(id),
  FOREIGN KEY (service_rule_id) REFERENCES service_rules(id) ON DELETE SET NULL,
  INDEX idx_job_vehicle (vehicle_id),
  INDEX idx_job_mechanic (mechanic_id)
) ENGINE=InnoDB;

CREATE TABLE job_parts (
  id          CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  job_card_id CHAR(36) NOT NULL,
  name        VARCHAR(100) NOT NULL,
  quantity    INT NOT NULL,
  unit_cost   DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (job_card_id) REFERENCES job_cards(id) ON DELETE CASCADE,
  INDEX idx_parts_job (job_card_id)
) ENGINE=InnoDB;

CREATE TABLE assignments (
  id          CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  vehicle_id  CHAR(36) NOT NULL,
  driver_id   CHAR(36) NOT NULL,
  shift_start DATETIME NOT NULL,
  shift_end   DATETIME NOT NULL,
  FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
  FOREIGN KEY (driver_id)  REFERENCES users(id),
  INDEX idx_asg_vehicle (vehicle_id, shift_start, shift_end),
  INDEX idx_asg_driver  (driver_id, shift_start, shift_end),
  CHECK (shift_end > shift_start)
) ENGINE=InnoDB;

CREATE TABLE fuel_logs (
  id          CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  vehicle_id  CHAR(36) NOT NULL,
  driver_id   CHAR(36) NOT NULL,
  odometer    INT NOT NULL,
  liters      DECIMAL(8,2) NOT NULL,
  total_cost  DECIMAL(10,2) NOT NULL,
  full_tank   BOOLEAN NOT NULL DEFAULT TRUE,
  receipt_url VARCHAR(255) NULL,
  logged_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
  FOREIGN KEY (driver_id)  REFERENCES users(id),
  INDEX idx_fuel_vehicle_time (vehicle_id, logged_at)
) ENGINE=InnoDB;

CREATE TABLE alerts (
  id              CHAR(36) PRIMARY KEY DEFAULT (UUID()),
  org_id          CHAR(36) NOT NULL,
  vehicle_id      CHAR(36) NOT NULL,
  service_rule_id CHAR(36) NULL,
  type            ENUM('SERVICE_DUE','INSURANCE_EXPIRY','LICENSE_EXPIRY') NOT NULL,
  message         VARCHAR(255) NOT NULL,
  resolved        BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
  INDEX idx_alert_org (org_id, resolved)
) ENGINE=InnoDB;
