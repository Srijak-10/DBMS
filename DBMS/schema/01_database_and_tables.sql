-- =============================================================================
-- VEHICLE SPARE PARTS AND INVENTORY MANAGEMENT SYSTEM (VSP-IMS)
-- Script 01: Database Creation, Tables, Keys, Constraints & Indexes
-- Target RDBMS: MySQL 8.0+ / MariaDB 10.5+
-- Engine: InnoDB | Character Set: utf8mb4 | Collation: utf8mb4_unicode_ci
-- =============================================================================

DROP DATABASE IF EXISTS vehicle_inventory_db;
CREATE DATABASE vehicle_inventory_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE vehicle_inventory_db;

-- -----------------------------------------------------------------------------
-- 1. TABLE: categories
-- Organizes parts into functional vehicle systems (e.g., Braking, Engine, Electrical)
-- Supports hierarchical categories via parent_category_id (Self-referencing FK)
-- -----------------------------------------------------------------------------
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    parent_category_id INT NULL,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_category_parent 
        FOREIGN KEY (parent_category_id) REFERENCES categories(category_id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 2. TABLE: brands (Manufacturers / OEM / Aftermarket brands)
-- -----------------------------------------------------------------------------
CREATE TABLE brands (
    brand_id INT AUTO_INCREMENT PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL UNIQUE,
    country_of_origin VARCHAR(60),
    website VARCHAR(255),
    is_oem BOOLEAN DEFAULT FALSE COMMENT 'True if Original Equipment Manufacturer',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 3. TABLE: parts
-- Master catalog of vehicle spare parts with pricing, specs, and stock limits
-- -----------------------------------------------------------------------------
CREATE TABLE parts (
    part_id INT AUTO_INCREMENT PRIMARY KEY,
    part_number VARCHAR(50) NOT NULL UNIQUE COMMENT 'OEM or manufacturer SKU/Part number',
    part_name VARCHAR(150) NOT NULL,
    category_id INT NOT NULL,
    brand_id INT NOT NULL,
    description TEXT,
    unit_of_measure VARCHAR(20) DEFAULT 'PIECE' COMMENT 'PIECE, SET, PAIR, LITER, KG',
    cost_price DECIMAL(10, 2) NOT NULL CHECK (cost_price >= 0.00),
    selling_price DECIMAL(10, 2) NOT NULL CHECK (selling_price >= cost_price),
    min_stock_level INT NOT NULL DEFAULT 5 CHECK (min_stock_level >= 0),
    max_stock_level INT NOT NULL DEFAULT 100 CHECK (max_stock_level >= min_stock_level),
    warranty_months INT DEFAULT 12 CHECK (warranty_months >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_parts_category 
        FOREIGN KEY (category_id) REFERENCES categories(category_id)
        ON UPDATE CASCADE,
    CONSTRAINT fk_parts_brand 
        FOREIGN KEY (brand_id) REFERENCES brands(brand_id)
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 4. TABLE: vehicles
-- Vehicle reference table (Make, Model, Year Range, Engine type, Fuel)
-- -----------------------------------------------------------------------------
CREATE TABLE vehicles (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    make VARCHAR(50) NOT NULL COMMENT 'Toyota, Honda, Ford, etc.',
    model VARCHAR(70) NOT NULL COMMENT 'Corolla, Civic, Mustang, etc.',
    year_start INT NOT NULL CHECK (year_start >= 1950 AND year_start <= 2100),
    year_end INT NOT NULL CHECK (year_end >= year_start),
    engine_displacement VARCHAR(30) COMMENT 'e.g. 1.8L, 2.0L Turbo, 3.5L V6',
    fuel_type ENUM('PETROL', 'DIESEL', 'HYBRID', 'ELECTRIC', 'CNG') DEFAULT 'PETROL',
    transmission ENUM('MANUAL', 'AUTOMATIC', 'CVT', 'DUAL_CLUTCH') DEFAULT 'AUTOMATIC',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_vehicle_spec UNIQUE (make, model, year_start, year_end, engine_displacement, fuel_type)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 5. TABLE: part_compatibility
-- Many-to-Many junction mapping parts to vehicles they fit
-- -----------------------------------------------------------------------------
CREATE TABLE part_compatibility (
    compatibility_id INT AUTO_INCREMENT PRIMARY KEY,
    part_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    position_notes VARCHAR(100) COMMENT 'e.g. Front Axle, Rear Left, All Trims',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_part_vehicle UNIQUE (part_id, vehicle_id),
    CONSTRAINT fk_compat_part 
        FOREIGN KEY (part_id) REFERENCES parts(part_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_compat_vehicle 
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) 
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 6. TABLE: warehouses
-- Physical warehouse / branch / shop storage facilities
-- -----------------------------------------------------------------------------
CREATE TABLE warehouses (
    warehouse_id INT AUTO_INCREMENT PRIMARY KEY,
    warehouse_code VARCHAR(20) NOT NULL UNIQUE,
    warehouse_name VARCHAR(100) NOT NULL,
    contact_phone VARCHAR(25),
    contact_email VARCHAR(100),
    city VARCHAR(60) NOT NULL,
    state VARCHAR(60),
    country VARCHAR(60) DEFAULT 'India',
    address_line TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 7. TABLE: inventory
-- Real-time stock levels of parts across multiple warehouses with bin tracking
-- -----------------------------------------------------------------------------
CREATE TABLE inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    part_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    aisle VARCHAR(15) DEFAULT 'A1',
    shelf VARCHAR(15) DEFAULT 'S1',
    bin VARCHAR(15) DEFAULT 'B1',
    quantity_on_hand INT NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    quantity_reserved INT NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
    last_restocked_at TIMESTAMP NULL DEFAULT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_part_warehouse UNIQUE (part_id, warehouse_id),
    CONSTRAINT fk_inv_part 
        FOREIGN KEY (part_id) REFERENCES parts(part_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_inv_warehouse 
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 8. TABLE: suppliers
-- Suppliers and auto-part distributors
-- -----------------------------------------------------------------------------
CREATE TABLE suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(120) NOT NULL UNIQUE,
    contact_name VARCHAR(80),
    phone VARCHAR(25) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    tax_registration_no VARCHAR(50) COMMENT 'GSTIN / VAT / EIN',
    address TEXT,
    city VARCHAR(60),
    country VARCHAR(60) DEFAULT 'India',
    payment_terms VARCHAR(50) DEFAULT 'Net 30',
    rating DECIMAL(2, 1) DEFAULT 4.0 CHECK (rating BETWEEN 1.0 AND 5.0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 9. TABLE: purchase_orders
-- Procurement orders placed with suppliers
-- -----------------------------------------------------------------------------
CREATE TABLE purchase_orders (
    po_id INT AUTO_INCREMENT PRIMARY KEY,
    po_number VARCHAR(30) NOT NULL UNIQUE,
    supplier_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    order_date DATE NOT NULL,
    expected_delivery_date DATE,
    received_date DATE NULL,
    total_amount DECIMAL(12, 2) DEFAULT 0.00 CHECK (total_amount >= 0.00),
    status ENUM('PENDING', 'ORDERED', 'PARTIALLY_RECEIVED', 'COMPLETED', 'CANCELLED') DEFAULT 'PENDING',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_po_supplier 
        FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) 
        ON UPDATE CASCADE,
    CONSTRAINT fk_po_warehouse 
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) 
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 10. TABLE: purchase_order_items
-- Line items for each purchase order
-- -----------------------------------------------------------------------------
CREATE TABLE purchase_order_items (
    po_item_id INT AUTO_INCREMENT PRIMARY KEY,
    po_id INT NOT NULL,
    part_id INT NOT NULL,
    quantity_ordered INT NOT NULL CHECK (quantity_ordered > 0),
    quantity_received INT NOT NULL DEFAULT 0 CHECK (quantity_received >= 0),
    unit_cost DECIMAL(10, 2) NOT NULL CHECK (unit_cost >= 0.00),
    total_line_cost DECIMAL(12, 2) GENERATED ALWAYS AS (quantity_ordered * unit_cost) STORED,
    CONSTRAINT uq_po_part UNIQUE (po_id, part_id),
    CONSTRAINT fk_poi_po 
        FOREIGN KEY (po_id) REFERENCES purchase_orders(po_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_poi_part 
        FOREIGN KEY (part_id) REFERENCES parts(part_id) 
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 11. TABLE: customers
-- Retail car owners, mechanics, garages, and corporate fleets
-- -----------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_type ENUM('RETAIL', 'WORKSHOP', 'FLEET', 'WHOLESALE') DEFAULT 'RETAIL',
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(25) NOT NULL UNIQUE,
    email VARCHAR(100) NULL,
    tax_id VARCHAR(50) NULL,
    address TEXT,
    city VARCHAR(60),
    discount_percentage DECIMAL(4, 2) DEFAULT 0.00 CHECK (discount_percentage BETWEEN 0.00 AND 50.00),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 12. TABLE: sales_orders (Invoices / Customer Orders)
-- -----------------------------------------------------------------------------
CREATE TABLE sales_orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_number VARCHAR(30) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(12, 2) DEFAULT 0.00 CHECK (subtotal >= 0.00),
    discount_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (discount_amount >= 0.00),
    tax_rate_percent DECIMAL(4, 2) DEFAULT 18.00 COMMENT 'GST or VAT percentage',
    tax_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (tax_amount >= 0.00),
    grand_total DECIMAL(12, 2) DEFAULT 0.00 CHECK (grand_total >= 0.00),
    payment_status ENUM('PAID', 'PENDING', 'PARTIAL', 'REFUNDED') DEFAULT 'PENDING',
    payment_method ENUM('CASH', 'CREDIT_CARD', 'UPI', 'BANK_TRANSFER', 'CHEQUE') DEFAULT 'CASH',
    order_status ENUM('CONFIRMED', 'DISPATCHED', 'DELIVERED', 'CANCELLED', 'RETURNED') DEFAULT 'CONFIRMED',
    remarks TEXT,
    CONSTRAINT fk_so_customer 
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 13. TABLE: sales_order_items
-- Line items for each sales transaction, linking to the source warehouse
-- -----------------------------------------------------------------------------
CREATE TABLE sales_order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    part_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0.00),
    discount_applied DECIMAL(10, 2) DEFAULT 0.00 CHECK (discount_applied >= 0.00),
    line_total DECIMAL(12, 2) NOT NULL CHECK (line_total >= 0.00),
    CONSTRAINT fk_soi_order 
        FOREIGN KEY (order_id) REFERENCES sales_orders(order_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_soi_part 
        FOREIGN KEY (part_id) REFERENCES parts(part_id) 
        ON UPDATE CASCADE,
    CONSTRAINT fk_soi_warehouse 
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) 
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 14. TABLE: stock_movements (Audit Ledger)
-- Immutable transaction ledger tracking all inventory changes
-- -----------------------------------------------------------------------------
CREATE TABLE stock_movements (
    movement_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    part_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    movement_type ENUM('PURCHASE_RECEIPT', 'SALE_DISPATCH', 'SALE_RETURN', 'WAREHOUSE_TRANSFER', 'MANUAL_ADJUSTMENT', 'SCRAP') NOT NULL,
    quantity_changed INT NOT NULL COMMENT 'Negative for outbound, Positive for inbound',
    balance_after_movement INT NOT NULL,
    reference_id VARCHAR(50) COMMENT 'Invoice No, PO No, or Transfer ID',
    notes VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sm_part 
        FOREIGN KEY (part_id) REFERENCES parts(part_id) 
        ON UPDATE CASCADE,
    CONSTRAINT fk_sm_warehouse 
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) 
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =============================================================================
-- PERFORMANCE INDEXES
-- Optimizes frequent search queries, lookups, and reporting joins
-- =============================================================================
CREATE INDEX idx_parts_number ON parts(part_number);
CREATE INDEX idx_parts_name ON parts(part_name);
CREATE INDEX idx_parts_category ON parts(category_id);
CREATE INDEX idx_parts_brand ON parts(brand_id);

CREATE INDEX idx_vehicle_lookup ON vehicles(make, model, year_start, year_end);
CREATE INDEX idx_compat_part_vehicle ON part_compatibility(part_id, vehicle_id);

CREATE INDEX idx_inventory_lookup ON inventory(part_id, warehouse_id);
CREATE INDEX idx_inventory_stock ON inventory(quantity_on_hand);

CREATE INDEX idx_po_supplier_status ON purchase_orders(supplier_id, status);
CREATE INDEX idx_po_date ON purchase_orders(order_date);

CREATE INDEX idx_so_customer ON sales_orders(customer_id);
CREATE INDEX idx_so_date ON sales_orders(order_date);
CREATE INDEX idx_so_status ON sales_orders(order_status, payment_status);

CREATE INDEX idx_stock_movements_part ON stock_movements(part_id, warehouse_id, created_at);
