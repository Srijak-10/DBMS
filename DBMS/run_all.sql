-- =============================================================================
-- VEHICLE SPARE PARTS AND INVENTORY MANAGEMENT SYSTEM (VSP-IMS)
-- Master Runner Script: Executes all components in dependency order
-- Usage in MySQL CLI: source run_all.sql;
-- =============================================================================

SELECT 'Starting Vehicle Inventory DBMS setup...' AS status;

-- 1. Create Tables, Constraints, and Indexes
SOURCE schema/01_database_and_tables.sql;

-- 2. Create Reporting & Catalog Views
SOURCE schema/02_views.sql;

-- 3. Create Automated Triggers
SOURCE schema/03_triggers.sql;

-- 4. Create Business Stored Procedures & Functions
SOURCE schema/04_stored_procedures.sql;

-- 5. Seed Realistic Automotive Data
SOURCE data/05_sample_data.sql;

SELECT 'Database setup completed successfully! Ready for queries.' AS status;
