-- SafePath sample data. Run AFTER schema.sql.
USE safepath;

-- Passwords are SHA-256 hex: admin123 / test123
INSERT INTO users (name, email, password_hash, role, phone_no) VALUES
('Admin',      'admin@safepath.com', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'ADMIN',      NULL),
('Test User',  'test@safepath.com',  'ecd71870d1963316a97e3ac3408c9835ad8cf0f3c1bc703527c30265534f75ae', 'PEDESTRIAN', '9876543210');

-- ids will be 1..6 in this order
INSERT INTO locations (name, latitude, longitude) VALUES
('College Gate',     10.0261, 76.3297),
('Bus Stand',        10.0189, 76.3410),
('Library',          10.0275, 76.3310),
('Market',           10.0150, 76.3350),
('Hostel',           10.0300, 76.3270),
('Railway Station',  10.0080, 76.3500);

-- columns: source, destination, name, distance_km, time_min, lighting(1-5), crowd(1-5), dog_risk(1-5)
INSERT INTO routes (source_id, destination_id, name, distance_km, estimated_time_min, lighting_level, crowd_density, dog_risk) VALUES
-- College Gate -> Bus Stand (ids 1-3)
(1, 2, 'Main Road',          1.8, 22, 5, 5, 1),
(1, 2, 'Canal Shortcut',     1.2, 14, 1, 1, 4),
(1, 2, 'Temple Street',      1.5, 18, 3, 3, 2),
-- College Gate -> Library (ids 4-5)
(1, 3, 'Campus Path',        0.4,  5, 4, 3, 1),
(1, 3, 'Back Lane',          0.3,  4, 2, 1, 3),
-- Bus Stand -> Market (ids 6-8)
(2, 4, 'Bazaar Road',        1.1, 14, 4, 5, 2),
(2, 4, 'Old Bridge Route',   0.8, 10, 2, 2, 5),
(2, 4, 'School Lane',        1.0, 12, 3, 3, 3),
-- Hostel -> College Gate (ids 9-10)
(5, 1, 'Hostel Main Path',   0.6,  8, 4, 4, 1),
(5, 1, 'Field Shortcut',     0.4,  5, 1, 1, 4),
-- Railway Station -> Market (ids 11-12)
(6, 4, 'Station Road',       1.6, 20, 5, 4, 2),
(6, 4, 'Railway Underpass',  1.0, 12, 1, 2, 3);

-- Incidents (user 2 = Test User). Dates are relative so they stay "recent".
INSERT INTO incidents (route_id, reporter_id, type, severity, description, reported_at) VALUES
(2,  2, 'POOR_LIGHTING', 'MEDIUM', 'Street lights not working near canal',      DATE_SUB(NOW(), INTERVAL 3 DAY)),
(2,  2, 'THEFT',         'HIGH',   'Phone snatching reported after dark',        DATE_SUB(NOW(), INTERVAL 7 DAY)),
(7,  2, 'DOG_THREAT',    'MEDIUM', 'Stray dogs near the old bridge',             DATE_SUB(NOW(), INTERVAL 2 DAY)),
(10, 2, 'HARASSMENT',    'HIGH',   'Group harassing students in the field',      DATE_SUB(NOW(), INTERVAL 10 DAY)),
(12, 2, 'POOR_LIGHTING', 'LOW',    'Underpass dim in the evening',               DATE_SUB(NOW(), INTERVAL 45 DAY)),
(1,  2, 'ACCIDENT',      'LOW',    'Minor scooter accident near the junction',   DATE_SUB(NOW(), INTERVAL 20 DAY));

INSERT INTO feedback (route_id, user_id, rating, comments) VALUES
(1, 2, 5, 'Busy and well lit, felt safe'),
(2, 2, 2, 'Fast but very dark'),
(3, 2, 4, 'Quiet but fine'),
(6, 2, 5, 'Lots of shops open, good'),
(7, 2, 2, 'Dogs and no lights'),
(9, 2, 4, 'Good for daily use'),
(11,2, 5, 'Safest way from the station');
