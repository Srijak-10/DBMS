-- =============================================================================
-- VEHICLE SPARE PARTS AND INVENTORY MANAGEMENT SYSTEM (VSP-IMS)
-- ALL-IN-ONE CONSOLIDATED SCRIPT (FOR PHPMYADMIN / WORKBENCH DIRECT IMPORT)
-- Database: vehicle_inventory_db | Engine: InnoDB | Charset: utf8mb4
-- =============================================================================

DROP DATABASE IF EXISTS vehicle_inventory_db;
CREATE DATABASE vehicle_inventory_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE vehicle_inventory_db;

-- -----------------------------------------------------------------------------
-- 1. TABLE: categories
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
-- 2. TABLE: brands
-- -----------------------------------------------------------------------------
CREATE TABLE brands (
    brand_id INT AUTO_INCREMENT PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL UNIQUE,
    country_of_origin VARCHAR(60),
    website VARCHAR(255),
    is_oem BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 3. TABLE: parts
-- -----------------------------------------------------------------------------
CREATE TABLE parts (
    part_id INT AUTO_INCREMENT PRIMARY KEY,
    part_number VARCHAR(50) NOT NULL UNIQUE,
    part_name VARCHAR(150) NOT NULL,
    category_id INT NOT NULL,
    brand_id INT NOT NULL,
    description TEXT,
    unit_of_measure VARCHAR(20) DEFAULT 'PIECE',
    cost_price DECIMAL(10, 2) NOT NULL CHECK (cost_price >= 0.00),
    selling_price DECIMAL(10, 2) NOT NULL CHECK (selling_price >= cost_price),
    min_stock_level INT NOT NULL DEFAULT 5 CHECK (min_stock_level >= 0),
    max_stock_level INT NOT NULL DEFAULT 100 CHECK (max_stock_level >= min_stock_level),
    warranty_months INT DEFAULT 12 CHECK (warranty_months >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_parts_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON UPDATE CASCADE,
    CONSTRAINT fk_parts_brand FOREIGN KEY (brand_id) REFERENCES brands(brand_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 4. TABLE: vehicles
-- -----------------------------------------------------------------------------
CREATE TABLE vehicles (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(70) NOT NULL,
    year_start INT NOT NULL CHECK (year_start >= 1950 AND year_start <= 2100),
    year_end INT NOT NULL CHECK (year_end >= year_start),
    engine_displacement VARCHAR(30),
    fuel_type ENUM('PETROL', 'DIESEL', 'HYBRID', 'ELECTRIC', 'CNG') DEFAULT 'PETROL',
    transmission ENUM('MANUAL', 'AUTOMATIC', 'CVT', 'DUAL_CLUTCH') DEFAULT 'AUTOMATIC',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_vehicle_spec UNIQUE (make, model, year_start, year_end, engine_displacement, fuel_type)
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 5. TABLE: part_compatibility
-- -----------------------------------------------------------------------------
CREATE TABLE part_compatibility (
    compatibility_id INT AUTO_INCREMENT PRIMARY KEY,
    part_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    position_notes VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_part_vehicle UNIQUE (part_id, vehicle_id),
    CONSTRAINT fk_compat_part FOREIGN KEY (part_id) REFERENCES parts(part_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_compat_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 6. TABLE: warehouses
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
    CONSTRAINT fk_inv_part FOREIGN KEY (part_id) REFERENCES parts(part_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_inv_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 8. TABLE: suppliers
-- -----------------------------------------------------------------------------
CREATE TABLE suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(120) NOT NULL UNIQUE,
    contact_name VARCHAR(80),
    phone VARCHAR(25) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    tax_registration_no VARCHAR(50),
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
    CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON UPDATE CASCADE,
    CONSTRAINT fk_po_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 10. TABLE: purchase_order_items
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
    CONSTRAINT fk_poi_po FOREIGN KEY (po_id) REFERENCES purchase_orders(po_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_poi_part FOREIGN KEY (part_id) REFERENCES parts(part_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 11. TABLE: customers
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
-- 12. TABLE: sales_orders
-- -----------------------------------------------------------------------------
CREATE TABLE sales_orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_number VARCHAR(30) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(12, 2) DEFAULT 0.00 CHECK (subtotal >= 0.00),
    discount_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (discount_amount >= 0.00),
    tax_rate_percent DECIMAL(4, 2) DEFAULT 18.00,
    tax_amount DECIMAL(10, 2) DEFAULT 0.00 CHECK (tax_amount >= 0.00),
    grand_total DECIMAL(12, 2) DEFAULT 0.00 CHECK (grand_total >= 0.00),
    payment_status ENUM('PAID', 'PENDING', 'PARTIAL', 'REFUNDED') DEFAULT 'PENDING',
    payment_method ENUM('CASH', 'CREDIT_CARD', 'UPI', 'BANK_TRANSFER', 'CHEQUE') DEFAULT 'CASH',
    order_status ENUM('CONFIRMED', 'DISPATCHED', 'DELIVERED', 'CANCELLED', 'RETURNED') DEFAULT 'CONFIRMED',
    remarks TEXT,
    CONSTRAINT fk_so_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 13. TABLE: sales_order_items
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
    CONSTRAINT fk_soi_order FOREIGN KEY (order_id) REFERENCES sales_orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_soi_part FOREIGN KEY (part_id) REFERENCES parts(part_id) ON UPDATE CASCADE,
    CONSTRAINT fk_soi_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 14. TABLE: stock_movements (Audit Ledger)
-- -----------------------------------------------------------------------------
CREATE TABLE stock_movements (
    movement_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    part_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    movement_type ENUM('PURCHASE_RECEIPT', 'SALE_DISPATCH', 'SALE_RETURN', 'WAREHOUSE_TRANSFER', 'MANUAL_ADJUSTMENT', 'SCRAP') NOT NULL,
    quantity_changed INT NOT NULL,
    balance_after_movement INT NOT NULL,
    reference_id VARCHAR(50),
    notes VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sm_part FOREIGN KEY (part_id) REFERENCES parts(part_id) ON UPDATE CASCADE,
    CONSTRAINT fk_sm_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id) ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Indexes
CREATE INDEX idx_parts_number ON parts(part_number);
CREATE INDEX idx_parts_name ON parts(part_name);
CREATE INDEX idx_vehicle_lookup ON vehicles(make, model, year_start, year_end);
CREATE INDEX idx_compat_part_vehicle ON part_compatibility(part_id, vehicle_id);
CREATE INDEX idx_inventory_lookup ON inventory(part_id, warehouse_id);
CREATE INDEX idx_po_supplier_status ON purchase_orders(supplier_id, status);
CREATE INDEX idx_so_customer ON sales_orders(customer_id);
CREATE INDEX idx_stock_movements_part ON stock_movements(part_id, warehouse_id, created_at);

-- -----------------------------------------------------------------------------
-- VIEWS
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_parts_catalog AS
SELECT 
    p.part_id,
    p.part_number,
    p.part_name,
    c.category_name,
    b.brand_name,
    p.unit_of_measure,
    p.cost_price,
    p.selling_price,
    ROUND(p.selling_price - p.cost_price, 2) AS gross_profit_per_unit,
    ROUND(((p.selling_price - p.cost_price) / p.cost_price) * 100, 2) AS markup_percentage,
    COALESCE(SUM(i.quantity_on_hand), 0) AS total_stock_available,
    p.min_stock_level,
    p.max_stock_level,
    CASE 
        WHEN COALESCE(SUM(i.quantity_on_hand), 0) = 0 THEN 'OUT OF STOCK'
        WHEN COALESCE(SUM(i.quantity_on_hand), 0) <= p.min_stock_level THEN 'LOW STOCK'
        WHEN COALESCE(SUM(i.quantity_on_hand), 0) > p.max_stock_level THEN 'OVERSTOCK'
        ELSE 'OPTIMAL'
    END AS stock_status,
    p.warranty_months,
    p.is_active
FROM parts p
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
LEFT JOIN inventory i ON p.part_id = i.part_id
GROUP BY 
    p.part_id, p.part_number, p.part_name, c.category_name, b.brand_name, 
    p.unit_of_measure, p.cost_price, p.selling_price, 
    p.min_stock_level, p.max_stock_level, p.warranty_months, p.is_active;

CREATE OR REPLACE VIEW vw_low_stock_alerts AS
SELECT 
    p.part_id,
    p.part_number,
    p.part_name,
    c.category_name,
    b.brand_name,
    w.warehouse_code,
    w.warehouse_name,
    i.quantity_on_hand,
    p.min_stock_level,
    (p.min_stock_level - i.quantity_on_hand) AS shortage_quantity,
    (p.max_stock_level - i.quantity_on_hand) AS recommended_reorder_qty,
    p.cost_price,
    ROUND((p.max_stock_level - i.quantity_on_hand) * p.cost_price, 2) AS estimated_reorder_cost,
    i.aisle, i.shelf, i.bin
FROM inventory i
JOIN parts p ON i.part_id = p.part_id
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
JOIN warehouses w ON i.warehouse_id = w.warehouse_id
WHERE i.quantity_on_hand <= p.min_stock_level
  AND p.is_active = TRUE;

-- -----------------------------------------------------------------------------
-- TRIGGERS
-- -----------------------------------------------------------------------------
DELIMITER $$

DROP TRIGGER IF EXISTS trg_validate_and_calc_sales_item$$
CREATE TRIGGER trg_validate_and_calc_sales_item
BEFORE INSERT ON sales_order_items
FOR EACH ROW
BEGIN
    DECLARE current_stock INT DEFAULT 0;
    SELECT quantity_on_hand INTO current_stock
    FROM inventory
    WHERE part_id = NEW.part_id AND warehouse_id = NEW.warehouse_id;

    IF current_stock IS NULL OR current_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction Rejected: Insufficient inventory on hand for this spare part.';
    END IF;

    SET NEW.line_total = (NEW.quantity * NEW.unit_price) - COALESCE(NEW.discount_applied, 0.00);
END$$

DROP TRIGGER IF EXISTS trg_after_sales_item_insert$$
CREATE TRIGGER trg_after_sales_item_insert
AFTER INSERT ON sales_order_items
FOR EACH ROW
BEGIN
    DECLARE new_balance INT;
    DECLARE invoice_ref VARCHAR(30);
    DECLARE order_subtotal DECIMAL(12, 2);
    DECLARE order_tax_rate DECIMAL(4, 2);
    DECLARE order_tax DECIMAL(10, 2);
    DECLARE order_discount DECIMAL(10, 2);

    UPDATE inventory
    SET quantity_on_hand = quantity_on_hand - NEW.quantity
    WHERE part_id = NEW.part_id AND warehouse_id = NEW.warehouse_id;

    SELECT quantity_on_hand INTO new_balance
    FROM inventory
    WHERE part_id = NEW.part_id AND warehouse_id = NEW.warehouse_id;

    SELECT invoice_number INTO invoice_ref
    FROM sales_orders
    WHERE order_id = NEW.order_id;

    INSERT INTO stock_movements (
        part_id, warehouse_id, movement_type, 
        quantity_changed, balance_after_movement, 
        reference_id, notes
    ) VALUES (
        NEW.part_id, NEW.warehouse_id, 'SALE_DISPATCH',
        -NEW.quantity, new_balance,
        invoice_ref, CONCAT('Dispatched on Order #', NEW.order_id)
    );

    SELECT COALESCE(SUM(line_total), 0.00) INTO order_subtotal
    FROM sales_order_items
    WHERE order_id = NEW.order_id;

    SELECT tax_rate_percent, discount_amount INTO order_tax_rate, order_discount
    FROM sales_orders
    WHERE order_id = NEW.order_id;

    SET order_tax = ROUND((order_subtotal - order_discount) * (order_tax_rate / 100.0), 2);

    UPDATE sales_orders
    SET 
        subtotal = order_subtotal,
        tax_amount = order_tax,
        grand_total = (order_subtotal - order_discount) + order_tax
    WHERE order_id = NEW.order_id;
END$$

DELIMITER ;

-- -----------------------------------------------------------------------------
-- SAMPLE SEED DATA
-- -----------------------------------------------------------------------------
INSERT INTO categories (category_id, parent_category_id, category_name, description) VALUES
(1, NULL, 'Braking System', 'Pads, discs, calipers, master cylinders'),
(2, NULL, 'Engine Components', 'Pistons, valves, gaskets, belts, ignition'),
(3, NULL, 'Electrical & Lighting', 'Batteries, alternators, starters, sensors'),
(4, NULL, 'Suspension & Steering', 'Shock absorbers, struts, control arms'),
(5, NULL, 'Filters & Fluids', 'Oil filters, air filters, cabin filters'),
(6, NULL, 'Transmission & Drivetrain', 'Clutch kits, torque converters, CV axles');

INSERT INTO brands (brand_id, brand_name, country_of_origin, website, is_oem) VALUES
(1, 'Bosch', 'Germany', 'https://www.bosch-automotive.com', TRUE),
(2, 'Brembo', 'Italy', 'https://www.brembo.com', TRUE),
(3, 'Denso', 'Japan', 'https://www.denso.com', TRUE),
(4, 'NGK Spark Plugs', 'Japan', 'https://www.ngkntk.com', TRUE),
(5, 'Mann-Filter', 'Germany', 'https://www.mann-filter.com', TRUE),
(6, 'Monroe', 'United States', 'https://www.monroe.com', FALSE),
(7, 'Exide Industries', 'India', 'https://www.exideindustries.com', TRUE),
(8, 'Mobil 1', 'United States', 'https://www.mobil.com', FALSE);

INSERT INTO parts (part_id, part_number, part_name, category_id, brand_id, unit_of_measure, cost_price, selling_price, min_stock_level, max_stock_level, warranty_months, is_active) VALUES
(1, 'BP-BOS-001', 'Bosch QuietCast Ceramic Front Brake Pads', 1, 1, 'SET', 28.00, 49.99, 10, 80, 12, TRUE),
(2, 'BP-BRE-002', 'Brembo Premium Disc Brake Rotor (Ventilated)', 1, 2, 'PIECE', 42.00, 78.50, 8, 60, 24, TRUE),
(3, 'SP-NGK-944', 'NGK Laser Iridium Spark Plug (Pack of 4)', 2, 4, 'SET', 22.50, 44.00, 15, 120, 36, TRUE),
(4, 'OF-MAN-501', 'Mann-Filter Spin-On Oil Filter W 610/3', 5, 5, 'PIECE', 5.20, 12.99, 20, 150, 6, TRUE),
(5, 'AF-DEN-112', 'Denso Premium Engine Air Filter', 5, 3, 'PIECE', 9.80, 21.50, 12, 90, 12, TRUE),
(6, 'CF-BOS-302', 'Bosch HEPA Cabin Air Filter', 5, 1, 'PIECE', 11.00, 24.99, 10, 75, 12, TRUE),
(7, 'SA-MON-780', 'Monroe OESpectrum Front Strut Assembly', 4, 6, 'PIECE', 68.00, 119.99, 6, 40, 24, TRUE),
(8, 'BT-EXI-065', 'Exide Matrix 12V 65Ah Sealed Automotive Battery', 3, 7, 'PIECE', 72.00, 115.00, 5, 35, 36, TRUE);

INSERT INTO vehicles (vehicle_id, make, model, year_start, year_end, engine_displacement, fuel_type, transmission) VALUES
(1, 'Toyota', 'Corolla', 2014, 2019, '1.8L Dual VVT-i', 'PETROL', 'CVT'),
(2, 'Honda', 'Civic', 2016, 2021, '1.5L Turbo', 'PETROL', 'CVT'),
(3, 'Hyundai', 'Creta', 2018, 2023, '1.5L CRDi Diesel', 'DIESEL', 'AUTOMATIC'),
(4, 'Maruti Suzuki', 'Swift', 2017, 2024, '1.2L K12M DualJet', 'PETROL', 'MANUAL');

INSERT INTO part_compatibility (part_id, vehicle_id, position_notes) VALUES
(1, 1, 'Front Axle (Both Wheels)'),
(2, 1, 'Front Brake Discs (Ventilated 275mm)'),
(3, 1, 'Engine Cylinder Head - Gap 1.1mm'),
(3, 2, 'Engine Cylinder Head - Pre-gapped'),
(4, 1, 'Engine Oil Pan Filter Base'),
(5, 1, 'Air Cleaner Box Intake'),
(6, 1, 'Behind Glovebox AC Unit'),
(7, 1, 'Front Suspension Strut Left/Right'),
(8, 1, 'Engine Bay Battery Tray');

INSERT INTO warehouses (warehouse_id, warehouse_code, warehouse_name, contact_phone, city, address_line) VALUES
(1, 'WH-DEL-01', 'North Zone Central Hub', '+91-11-23456789', 'New Delhi', 'Okhla Phase III Industrial Area'),
(2, 'WH-BLR-02', 'South Regional Depot', '+91-80-98765432', 'Bengaluru', 'Peenya Industrial Estate 2nd Stage');

INSERT INTO suppliers (supplier_id, company_name, contact_name, phone, email, rating) VALUES
(1, 'Bosch India Distribution Ltd.', 'Rajesh Sharma', '+91-9811002233', 'orders@bosch-aftermarket.in', 4.9),
(2, 'Brembo Brake Systems India', 'Marco Rossi', '+91-9822334455', 'sales@brembo-india.com', 4.8),
(3, 'Denso Kirloskar Spares Corp.', 'Kiran Nair', '+91-9844556677', 'b2b@densokirloskar.com', 4.7);

INSERT INTO inventory (inventory_id, part_id, warehouse_id, aisle, shelf, bin, quantity_on_hand, last_restocked_at) VALUES
(1, 1, 1, 'A-01', 'S-02', 'B-14', 45, '2026-10-15 09:30:00'),
(2, 2, 1, 'A-01', 'S-04', 'B-08', 25, '2026-10-15 09:30:00'),
(3, 3, 1, 'A-02', 'S-01', 'B-22', 60, '2026-10-18 11:15:00'),
(4, 4, 1, 'A-03', 'S-05', 'B-01', 85, '2026-10-20 14:00:00'),
(5, 5, 1, 'A-03', 'S-03', 'B-09', 30, '2026-10-12 10:00:00'),
(6, 6, 1, 'A-03', 'S-03', 'B-10', 4, '2026-09-25 16:00:00'), -- Low stock
(7, 7, 1, 'B-01', 'S-01', 'B-04', 15, '2026-10-05 13:30:00'),
(8, 8, 1, 'B-02', 'S-01', 'B-01', 3, '2026-09-20 10:00:00'),  -- Low stock
(9, 1, 2, 'A-10', 'S-01', 'B-02', 30, '2026-10-14 10:00:00'),
(10, 2, 2, 'A-10', 'S-03', 'B-05', 18, '2026-10-14 10:00:00');

INSERT INTO customers (customer_id, customer_type, full_name, phone, email, city, discount_percentage) VALUES
(1, 'WORKSHOP', 'Apex Precision Auto Workshop', '+91-9811223344', 'service@apexauto.in', 'New Delhi', 10.00),
(2, 'FLEET', 'Metro City Cabs & Transport Services', '+91-9822334455', 'fleetmanager@metrocabs.com', 'Mumbai', 15.00),
(3, 'RETAIL', 'Arun Kumar', '+91-9876501234', 'arun.kumar@gmail.com', 'New Delhi', 0.00);

INSERT INTO sales_orders (order_id, invoice_number, customer_id, order_date, subtotal, discount_amount, tax_rate_percent, tax_amount, grand_total, payment_status, payment_method, order_status, remarks) VALUES
(1, 'INV-202610-1001', 1, '2026-10-20 11:30:00', 374.95, 37.50, 18.00, 60.74, 398.19, 'PAID', 'UPI', 'DELIVERED', 'Fleet maintenance batch');

INSERT INTO sales_order_items (order_item_id, order_id, part_id, warehouse_id, quantity, unit_price, discount_applied, line_total) VALUES
(1, 1, 1, 1, 5, 49.99, 25.00, 224.95),
(2, 1, 4, 1, 10, 12.99, 12.99, 116.91);
