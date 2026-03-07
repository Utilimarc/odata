-- Demo database setup: schema + seed data for PostgreSQL
-- This script is idempotent — safe to run multiple times.

-- Drop all tables (reverse dependency order)
DROP TABLE IF EXISTS data_type_showcase CASCADE;
DROP TABLE IF EXISTS role_permissions CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS note_tags CASCADE;
DROP TABLE IF EXISTS notes CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS permissions CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

-- Create tables
CREATE TABLE departments (
  id SERIAL PRIMARY KEY,
  department_name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  email VARCHAR(100) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  full_name VARCHAR(100),
  department_id INTEGER REFERENCES departments(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE categories (
  category_id SERIAL PRIMARY KEY,
  category_name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  created_by INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE notes (
  note_id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  category_id INTEGER REFERENCES categories(category_id) ON DELETE SET NULL,
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,
  is_pinned BOOLEAN DEFAULT false,
  is_archived BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE tags (
  tag_id SERIAL PRIMARY KEY,
  tag_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE roles (
  role_id SERIAL PRIMARY KEY,
  role_name VARCHAR(50) NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE permissions (
  permission_id SERIAL PRIMARY KEY,
  permission_name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE note_tags (
  note_id INTEGER NOT NULL REFERENCES notes(note_id) ON DELETE CASCADE,
  tag_id INTEGER NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE,
  PRIMARY KEY (note_id, tag_id)
);

CREATE TABLE user_roles (
  user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  role_id INTEGER NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, role_id)
);

CREATE TABLE role_permissions (
  role_id INTEGER NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
  permission_id INTEGER NOT NULL REFERENCES permissions(permission_id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

-- Indexes
CREATE INDEX idx_users_department_id ON users(department_id);
CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_category_id ON notes(category_id);
CREATE INDEX idx_note_tags_note_id ON note_tags(note_id);
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);

-- Seed data

INSERT INTO departments (id, department_name, description, created_at) VALUES
  (1, 'Engineering', 'Software Development and Engineering', NOW() - INTERVAL '6 months'),
  (2, 'Marketing', 'Marketing and Communications', NOW() - INTERVAL '5 months'),
  (3, 'Sales', 'Sales and Business Development', NOW() - INTERVAL '4 months'),
  (4, 'Human Resources', 'HR and People Operations', NOW() - INTERVAL '3 months'),
  (5, 'Finance', 'Finance and Accounting', NOW() - INTERVAL '2 months');
SELECT setval('departments_id_seq', (SELECT MAX(id) FROM departments));

INSERT INTO users (user_id, username, email, password_hash, full_name, department_id, is_active, created_at, updated_at) VALUES
  (1, 'john.doe', 'john.doe@company.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', 'John Doe', 1, true, NOW() - INTERVAL '180 days', NOW() - INTERVAL '1 day'),
  (2, 'jane.smith', 'jane.smith@company.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', 'Jane Smith', 1, true, NOW() - INTERVAL '150 days', NOW() - INTERVAL '2 days'),
  (3, 'bob.johnson', 'bob.johnson@company.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', 'Bob Johnson', 2, true, NOW() - INTERVAL '120 days', NOW() - INTERVAL '3 days'),
  (4, 'alice.williams', 'alice.williams@company.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', 'Alice Williams', 2, true, NOW() - INTERVAL '100 days', NOW() - INTERVAL '4 days'),
  (5, 'charlie.brown', 'charlie.brown@company.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', 'Charlie Brown', 3, true, NOW() - INTERVAL '90 days', NOW() - INTERVAL '5 days'),
  (6, 'diana.davis', 'diana.davis@company.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', 'Diana Davis', 3, true, NOW() - INTERVAL '80 days', NOW() - INTERVAL '6 days'),
  (7, 'eve.miller', 'eve.miller@company.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', 'Eve Miller', 4, true, NOW() - INTERVAL '70 days', NOW() - INTERVAL '7 days'),
  (8, 'frank.wilson', 'frank.wilson@company.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', 'Frank Wilson', 5, true, NOW() - INTERVAL '60 days', NOW() - INTERVAL '8 days'),
  (9, 'grace.moore', 'grace.moore@company.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', 'Grace Moore', 1, false, NOW() - INTERVAL '50 days', NOW() - INTERVAL '30 days'),
  (10, 'admin', 'admin@company.com', '$2a$10$abcdefghijklmnopqrstuvwxyz', 'System Administrator', 1, true, NOW() - INTERVAL '365 days', NOW());
SELECT setval('users_user_id_seq', (SELECT MAX(user_id) FROM users));

INSERT INTO categories (category_id, category_name, description, created_by, created_at) VALUES
  (1, 'Work', 'Work-related notes and tasks', 1, NOW() - INTERVAL '150 days'),
  (2, 'Personal', 'Personal notes and reminders', 1, NOW() - INTERVAL '140 days'),
  (3, 'Projects', 'Project documentation and planning', 2, NOW() - INTERVAL '130 days'),
  (4, 'Meetings', 'Meeting notes and action items', 2, NOW() - INTERVAL '120 days'),
  (5, 'Ideas', 'Ideas and brainstorming', 3, NOW() - INTERVAL '110 days'),
  (6, 'Research', 'Research notes and findings', 3, NOW() - INTERVAL '100 days'),
  (7, 'Documentation', 'Technical documentation', 1, NOW() - INTERVAL '90 days'),
  (8, 'Training', 'Training materials and notes', 4, NOW() - INTERVAL '80 days');
SELECT setval('categories_category_id_seq', (SELECT MAX(category_id) FROM categories));

INSERT INTO notes (note_id, user_id, category_id, title, content, is_pinned, is_archived, created_at, updated_at) VALUES
  (1, 1, 1, 'Sprint Planning Q4', 'Planning for Q4 sprint. Focus on new features and bug fixes. Team capacity: 5 developers.', true, false, NOW() - INTERVAL '30 days', NOW() - INTERVAL '1 day'),
  (2, 1, 4, 'Team Meeting Notes', 'Discussed project timeline and resource allocation. Action items: Review architecture, Update documentation.', true, false, NOW() - INTERVAL '25 days', NOW() - INTERVAL '2 days'),
  (3, 2, 3, 'API Design Document', 'RESTful API design for the new microservice. Endpoints, authentication, rate limiting considerations.', false, false, NOW() - INTERVAL '20 days', NOW() - INTERVAL '3 days'),
  (4, 2, 7, 'Database Schema Updates', 'Proposed changes to the user table. Add new fields for profile completion tracking.', true, false, NOW() - INTERVAL '15 days', NOW() - INTERVAL '4 days'),
  (5, 3, 5, 'Marketing Campaign Ideas', 'Brainstorming session results. Social media strategy, content calendar, influencer partnerships.', false, false, NOW() - INTERVAL '10 days', NOW() - INTERVAL '5 days'),
  (6, 3, 4, 'Client Meeting - Acme Corp', 'Requirements gathering session. Client needs custom reporting dashboard. Timeline: 6 weeks.', true, false, NOW() - INTERVAL '8 days', NOW() - INTERVAL '1 day'),
  (7, 4, 2, 'Personal Goals 2024', 'Career development goals. Learn new technologies, contribute to open source, attend conferences.', false, false, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
  (8, 4, 6, 'React Performance Research', 'Research on React performance optimization. Memoization, lazy loading, code splitting techniques.', false, false, NOW() - INTERVAL '6 days', NOW() - INTERVAL '2 days'),
  (9, 5, 1, 'Sales Pipeline Review', 'Q3 sales pipeline analysis. Top prospects, conversion rates, revenue projections.', true, false, NOW() - INTERVAL '5 days', NOW() - INTERVAL '1 day'),
  (10, 5, 4, 'Product Demo Preparation', 'Preparing demo for enterprise client. Key features to highlight, common objections, pricing discussion.', false, false, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
  (11, 6, 1, 'Territory Planning', 'Sales territory assignments for new quarter. Coverage analysis, account distribution.', false, false, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
  (12, 7, 8, 'Onboarding Process Updates', 'Improvements to employee onboarding. New hire checklist, mentor assignment, first week schedule.', true, false, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
  (13, 8, 1, 'Budget Review Q4', 'Quarterly budget review and forecast. Department spending, cost optimization opportunities.', true, false, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
  (14, 1, 3, 'Mobile App Roadmap', 'Feature roadmap for mobile application. User feedback integration, platform parity goals.', false, false, NOW() - INTERVAL '12 days', NOW() - INTERVAL '6 days'),
  (15, 2, 1, 'Code Review Guidelines', 'Updated code review process and best practices. Review checklist, response time expectations.', false, true, NOW() - INTERVAL '60 days', NOW() - INTERVAL '60 days');
SELECT setval('notes_note_id_seq', (SELECT MAX(note_id) FROM notes));

INSERT INTO tags (tag_id, tag_name) VALUES
  (1, 'important'), (2, 'urgent'), (3, 'follow-up'), (4, 'meeting'), (5, 'project'),
  (6, 'documentation'), (7, 'research'), (8, 'planning'), (9, 'review'), (10, 'action-required');
SELECT setval('tags_tag_id_seq', (SELECT MAX(tag_id) FROM tags));

INSERT INTO note_tags (note_id, tag_id) VALUES
  (1, 1), (1, 5), (1, 8), (2, 1), (2, 4), (2, 10), (3, 5), (3, 6), (4, 1), (4, 6),
  (5, 8), (5, 7), (6, 1), (6, 4), (6, 3), (7, 8), (8, 7), (8, 6), (9, 1), (9, 9),
  (10, 5), (10, 8), (11, 8), (12, 1), (12, 6), (13, 1), (13, 9), (14, 5), (14, 8), (15, 6);

INSERT INTO roles (role_id, role_name, description) VALUES
  (1, 'Admin', 'System administrator with full access'),
  (2, 'Manager', 'Department manager with team oversight'),
  (3, 'Developer', 'Software developer with code access'),
  (4, 'User', 'Standard user with basic access'),
  (5, 'Viewer', 'Read-only access to resources');
SELECT setval('roles_role_id_seq', (SELECT MAX(role_id) FROM roles));

INSERT INTO permissions (permission_id, permission_name, description) VALUES
  (1, 'users.read', 'Read user information'),
  (2, 'users.write', 'Create and update users'),
  (3, 'users.delete', 'Delete users'),
  (4, 'notes.read', 'Read notes'),
  (5, 'notes.write', 'Create and update notes'),
  (6, 'notes.delete', 'Delete notes'),
  (7, 'categories.read', 'Read categories'),
  (8, 'categories.write', 'Create and update categories'),
  (9, 'categories.delete', 'Delete categories'),
  (10, 'departments.read', 'Read departments'),
  (11, 'departments.write', 'Create and update departments'),
  (12, 'departments.delete', 'Delete departments'),
  (13, 'roles.read', 'Read roles'),
  (14, 'roles.write', 'Create and update roles'),
  (15, 'permissions.read', 'Read permissions');
SELECT setval('permissions_permission_id_seq', (SELECT MAX(permission_id) FROM permissions));

-- Admin has all permissions
INSERT INTO role_permissions (role_id, permission_id)
  SELECT 1, permission_id FROM permissions;

-- Manager: read/write, no delete
INSERT INTO role_permissions (role_id, permission_id) VALUES
  (2, 1), (2, 2), (2, 4), (2, 5), (2, 7), (2, 8), (2, 10), (2, 11), (2, 13), (2, 15);

-- Developer: read/write for notes and categories
INSERT INTO role_permissions (role_id, permission_id) VALUES
  (3, 1), (3, 4), (3, 5), (3, 7), (3, 8), (3, 10), (3, 13), (3, 15);

-- User: read/write for own notes
INSERT INTO role_permissions (role_id, permission_id) VALUES
  (4, 1), (4, 4), (4, 5), (4, 7), (4, 10), (4, 13), (4, 15);

-- Viewer: read-only
INSERT INTO role_permissions (role_id, permission_id) VALUES
  (5, 1), (5, 4), (5, 7), (5, 10), (5, 13), (5, 15);

-- User-Role assignments
INSERT INTO user_roles (user_id, role_id) VALUES
  (10, 1), (1, 2), (2, 3), (3, 2), (4, 3), (5, 4), (6, 4), (7, 4), (8, 4), (9, 5);

-- Data Type Showcase: one column per supported OData/Sequelize data type
-- JSON values are serialized to strings and BLOB values to base64 by the router.
CREATE TABLE data_type_showcase (
  id SERIAL PRIMARY KEY,
  label VARCHAR(100) NOT NULL,
  big_int_val BIGINT,
  small_int_val SMALLINT,
  decimal_val DECIMAL(10,2),
  float_val REAL,
  double_val DOUBLE PRECISION,
  bool_val BOOLEAN DEFAULT false,
  string_val VARCHAR(200),
  text_val TEXT,
  date_only_val DATE,
  datetime_val TIMESTAMP DEFAULT NOW(),
  uuid_val UUID,
  json_val JSONB,
  blob_val BYTEA,
  department_id INTEGER REFERENCES departments(id) ON DELETE SET NULL
);

CREATE INDEX idx_data_type_showcase_department_id ON data_type_showcase(department_id);

INSERT INTO data_type_showcase (id, label, big_int_val, small_int_val, decimal_val, float_val, double_val, bool_val, string_val, text_val, date_only_val, datetime_val, uuid_val, json_val, blob_val, department_id) VALUES
  (1, 'Max values',
    9223372036854775807, 32767, 99999999.99, 3.4028235e+38, 1.7976931348623157e+308,
    true, 'Hello, World!', 'A longer text field demonstrating TEXT storage in PostgreSQL.',
    '2025-06-15', NOW() - INTERVAL '10 days',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    '{"key": "value", "count": 42}',
    E'\\x48656c6c6f',
    1),
  (2, 'Min / negative values',
    -9223372036854775808, -32768, -99999999.99, -1.5e-45, -5e-324,
    false, 'Special chars: O''Brien & Co <>"', 'Edge cases with special characters and unicode.',
    '1970-01-01', NOW() - INTERVAL '365 days',
    'b1234567-89ab-cdef-0123-456789abcdef',
    '{"nested": {"a": 1}, "list": [1, 2, 3]}',
    E'\\xDEADBEEF',
    2),
  (3, 'Zero / empty values',
    0, 0, 0.00, 0.0, 0.0,
    false, '', '',
    '2000-01-01', NOW(),
    'c0000000-0000-0000-0000-000000000000',
    '{}',
    E'\\x',
    3),
  (4, 'Typical values',
    42, 100, 1234.56, 3.14159, 2.718281828459045,
    true, 'A typical string value', 'Typical text content for everyday use.',
    '2024-03-15', NOW() - INTERVAL '30 days',
    'd1111111-2222-3333-4444-555555666666',
    '{"name": "test", "active": true, "tags": ["demo", "showcase"]}',
    E'\\x010203',
    4),
  (5, 'All nulls',
    NULL, NULL, NULL, NULL, NULL,
    NULL, NULL, NULL,
    NULL, NULL,
    NULL,
    NULL,
    NULL,
    NULL);
SELECT setval('data_type_showcase_id_seq', (SELECT MAX(id) FROM data_type_showcase));
