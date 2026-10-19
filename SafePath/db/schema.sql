-- SafePath schema (contract v1.0). Safe to re-run: it rebuilds everything.
CREATE DATABASE IF NOT EXISTS safepath;
USE safepath;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS feedback;
DROP TABLE IF EXISTS incidents;
DROP TABLE IF EXISTS routes;
DROP TABLE IF EXISTS locations;
DROP TABLE IF EXISTS users;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE users (
  user_id       INT PRIMARY KEY AUTO_INCREMENT,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(120) NOT NULL UNIQUE,
  password_hash VARCHAR(128) NOT NULL,
  role          VARCHAR(15)  NOT NULL,
  phone_no      VARCHAR(20)
);

CREATE TABLE locations (
  location_id INT PRIMARY KEY AUTO_INCREMENT,
  name        VARCHAR(100) NOT NULL UNIQUE,
  latitude    DOUBLE NOT NULL,
  longitude   DOUBLE NOT NULL
);

CREATE TABLE routes (
  route_id           INT PRIMARY KEY AUTO_INCREMENT,
  source_id          INT NOT NULL,
  destination_id     INT NOT NULL,
  name               VARCHAR(120) NOT NULL,
  distance_km        DOUBLE NOT NULL,
  estimated_time_min INT NOT NULL,
  lighting_level     INT NOT NULL,
  crowd_density      INT NOT NULL,
  dog_risk           INT NOT NULL,
  FOREIGN KEY (source_id)      REFERENCES locations(location_id),
  FOREIGN KEY (destination_id) REFERENCES locations(location_id)
);

CREATE TABLE incidents (
  incident_id INT PRIMARY KEY AUTO_INCREMENT,
  route_id    INT NOT NULL,
  reporter_id INT NOT NULL,
  type        VARCHAR(20) NOT NULL,
  severity    VARCHAR(10) NOT NULL,
  description VARCHAR(500),
  reported_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (route_id)    REFERENCES routes(route_id),
  FOREIGN KEY (reporter_id) REFERENCES users(user_id)
);

CREATE TABLE feedback (
  feedback_id INT PRIMARY KEY AUTO_INCREMENT,
  route_id    INT NOT NULL,
  user_id     INT NOT NULL,
  rating      INT NOT NULL,
  comments    VARCHAR(500),
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (route_id) REFERENCES routes(route_id),
  FOREIGN KEY (user_id)  REFERENCES users(user_id)
);
