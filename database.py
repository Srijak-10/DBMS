"""
Database Module for Vehicle Spare Parts and Inventory Management System.
Supports SQLite (zero-config, immediate out-of-the-box operation)
and MySQL/MariaDB (via mysql-connector-python when configured).
"""

import os
import sqlite3
from datetime import datetime

DB_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'vehicle_inventory.db')

def get_connection():
    """Returns a SQLite connection with row_factory set to sqlite3.Row for dict-like access."""
    conn = sqlite3.connect(DB_FILE)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn

def init_database():
    """Initializes the database schema and seeds initial data if not already present."""
    conn = get_connection()
    cursor = conn.cursor()

    # Create Tables
    cursor.executescript("""
    CREATE TABLE IF NOT EXISTS categories (
        category_id INTEGER PRIMARY KEY AUTOINCREMENT,
        parent_category_id INTEGER,
        category_name TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL
    );

    CREATE TABLE IF NOT EXISTS brands (
        brand_id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand_name TEXT NOT NULL UNIQUE,
        country_of_origin TEXT,
        website TEXT,
        is_oem BOOLEAN DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS parts (
        part_id INTEGER PRIMARY KEY AUTOINCREMENT,
        part_number TEXT NOT NULL UNIQUE,
        part_name TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        brand_id INTEGER NOT NULL,
        description TEXT,
        unit_of_measure TEXT DEFAULT 'PIECE',
        cost_price REAL NOT NULL CHECK (cost_price >= 0),
        selling_price REAL NOT NULL CHECK (selling_price >= cost_price),
        min_stock_level INTEGER NOT NULL DEFAULT 5,
        max_stock_level INTEGER NOT NULL DEFAULT 100,
        warranty_months INTEGER DEFAULT 12,
        is_active BOOLEAN DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories(category_id),
        FOREIGN KEY (brand_id) REFERENCES brands(brand_id)
    );

    CREATE TABLE IF NOT EXISTS vehicles (
        vehicle_id INTEGER PRIMARY KEY AUTOINCREMENT,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year_start INTEGER NOT NULL,
        year_end INTEGER NOT NULL,
        engine_displacement TEXT,
        fuel_type TEXT DEFAULT 'PETROL',
        transmission TEXT DEFAULT 'AUTOMATIC',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (make, model, year_start, year_end, engine_displacement, fuel_type)
    );

    CREATE TABLE IF NOT EXISTS part_compatibility (
        compatibility_id INTEGER PRIMARY KEY AUTOINCREMENT,
        part_id INTEGER NOT NULL,
        vehicle_id INTEGER NOT NULL,
        position_notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (part_id, vehicle_id),
        FOREIGN KEY (part_id) REFERENCES parts(part_id) ON DELETE CASCADE,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE CASCADE
    );

    CREATE TABLE IF NOT EXISTS warehouses (
        warehouse_id INTEGER PRIMARY KEY AUTOINCREMENT,
        warehouse_code TEXT NOT NULL UNIQUE,
        warehouse_name TEXT NOT NULL,
        contact_phone TEXT,
        contact_email TEXT,
        city TEXT NOT NULL,
        state TEXT,
        country TEXT DEFAULT 'India',
        address_line TEXT,
        is_active BOOLEAN DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS inventory (
        inventory_id INTEGER PRIMARY KEY AUTOINCREMENT,
        part_id INTEGER NOT NULL,
        warehouse_id INTEGER NOT NULL,
        aisle TEXT DEFAULT 'A1',
        shelf TEXT DEFAULT 'S1',
        bin TEXT DEFAULT 'B1',
        quantity_on_hand INTEGER NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
        quantity_reserved INTEGER NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
        last_restocked_at TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (part_id, warehouse_id),
        FOREIGN KEY (part_id) REFERENCES parts(part_id),
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
    );

    CREATE TABLE IF NOT EXISTS suppliers (
        supplier_id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_name TEXT NOT NULL UNIQUE,
        contact_name TEXT,
        phone TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        tax_registration_no TEXT,
        address TEXT,
        city TEXT,
        country TEXT DEFAULT 'India',
        payment_terms TEXT DEFAULT 'Net 30',
        rating REAL DEFAULT 4.0,
        is_active BOOLEAN DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS customers (
        customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_type TEXT DEFAULT 'RETAIL',
        full_name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        email TEXT,
        tax_id TEXT,
        address TEXT,
        city TEXT,
        discount_percentage REAL DEFAULT 0.0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS sales_orders (
        order_id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        customer_id INTEGER NOT NULL,
        order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        subtotal REAL DEFAULT 0.0,
        discount_amount REAL DEFAULT 0.0,
        tax_rate_percent REAL DEFAULT 18.0,
        tax_amount REAL DEFAULT 0.0,
        grand_total REAL DEFAULT 0.0,
        payment_status TEXT DEFAULT 'PENDING',
        payment_method TEXT DEFAULT 'CASH',
        order_status TEXT DEFAULT 'CONFIRMED',
        remarks TEXT,
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    );

    CREATE TABLE IF NOT EXISTS sales_order_items (
        order_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        part_id INTEGER NOT NULL,
        warehouse_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        unit_price REAL NOT NULL,
        discount_applied REAL DEFAULT 0.0,
        line_total REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES sales_orders(order_id) ON DELETE CASCADE,
        FOREIGN KEY (part_id) REFERENCES parts(part_id),
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
    );

    CREATE TABLE IF NOT EXISTS stock_movements (
        movement_id INTEGER PRIMARY KEY AUTOINCREMENT,
        part_id INTEGER NOT NULL,
        warehouse_id INTEGER NOT NULL,
        movement_type TEXT NOT NULL,
        quantity_changed INTEGER NOT NULL,
        balance_after_movement INTEGER NOT NULL,
        reference_id TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (part_id) REFERENCES parts(part_id),
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
    );

    -- Views
    CREATE VIEW IF NOT EXISTS vw_parts_catalog AS
    SELECT 
        p.part_id,
        p.part_number,
        p.part_name,
        c.category_name,
        b.brand_name,
        p.unit_of_measure,
        p.cost_price,
        p.selling_price,
        ROUND(p.selling_price - p.cost_price, 2) AS gross_profit,
        ROUND(((p.selling_price - p.cost_price) / p.cost_price) * 100, 1) AS markup_percent,
        COALESCE(SUM(i.quantity_on_hand), 0) AS total_stock,
        p.min_stock_level,
        p.max_stock_level,
        CASE 
            WHEN COALESCE(SUM(i.quantity_on_hand), 0) = 0 THEN 'OUT OF STOCK'
            WHEN COALESCE(SUM(i.quantity_on_hand), 0) <= p.min_stock_level THEN 'LOW STOCK'
            ELSE 'IN STOCK'
        END AS stock_status,
        p.warranty_months,
        p.is_active
    FROM parts p
    JOIN categories c ON p.category_id = c.category_id
    JOIN brands b ON p.brand_id = b.brand_id
    LEFT JOIN inventory i ON p.part_id = i.part_id
    GROUP BY p.part_id;

    CREATE VIEW IF NOT EXISTS vw_low_stock_alerts AS
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
        (p.max_stock_level - i.quantity_on_hand) AS reorder_quantity,
        p.cost_price,
        ROUND((p.max_stock_level - i.quantity_on_hand) * p.cost_price, 2) AS estimated_reorder_cost,
        i.aisle, i.shelf, i.bin
    FROM inventory i
    JOIN parts p ON i.part_id = p.part_id
    JOIN categories c ON p.category_id = c.category_id
    JOIN brands b ON p.brand_id = b.brand_id
    JOIN warehouses w ON i.warehouse_id = w.warehouse_id
    WHERE i.quantity_on_hand <= p.min_stock_level;
    """)

    # Seed data if empty
    cursor.execute("SELECT COUNT(*) FROM categories")
    if cursor.fetchone()[0] == 0:
        seed_data(cursor)

    conn.commit()
    conn.close()

def seed_data(cursor):
    """Populates standard sample data into SQLite."""
    cursor.executescript("""
    INSERT INTO categories (category_id, parent_category_id, category_name, description) VALUES
    (1, NULL, 'Braking System', 'Pads, discs, calipers, master cylinders'),
    (2, NULL, 'Engine Components', 'Pistons, valves, belts, spark plugs, ignition'),
    (3, NULL, 'Electrical & Lighting', 'Batteries, alternators, starters, bulbs'),
    (4, NULL, 'Suspension & Steering', 'Shock absorbers, struts, tie rods, control arms'),
    (5, NULL, 'Filters & Fluids', 'Engine oil, oil filters, air filters, cabin filters'),
    (6, NULL, 'Transmission & Drivetrain', 'Clutch kits, CV joints, gearboxes');

    INSERT INTO brands (brand_id, brand_name, country_of_origin, website, is_oem) VALUES
    (1, 'Bosch', 'Germany', 'https://www.bosch-automotive.com', 1),
    (2, 'Brembo', 'Italy', 'https://www.brembo.com', 1),
    (3, 'Denso', 'Japan', 'https://www.denso.com', 1),
    (4, 'NGK Spark Plugs', 'Japan', 'https://www.ngkntk.com', 1),
    (5, 'Mann-Filter', 'Germany', 'https://www.mann-filter.com', 1),
    (6, 'Monroe', 'United States', 'https://www.monroe.com', 0),
    (7, 'Exide Industries', 'India', 'https://www.exideindustries.com', 1),
    (8, 'Mobil 1', 'United States', 'https://www.mobil.com', 0);

    INSERT INTO parts (part_id, part_number, part_name, category_id, brand_id, unit_of_measure, cost_price, selling_price, min_stock_level, max_stock_level, warranty_months, is_active) VALUES
    (1, 'BP-BOS-001', 'Bosch QuietCast Ceramic Front Brake Pads', 1, 1, 'SET', 28.00, 49.99, 10, 80, 12, 1),
    (2, 'BP-BRE-002', 'Brembo Premium Disc Brake Rotor (Ventilated)', 1, 2, 'PIECE', 42.00, 78.50, 8, 60, 24, 1),
    (3, 'SP-NGK-944', 'NGK Laser Iridium Spark Plug (Pack of 4)', 2, 4, 'SET', 22.50, 44.00, 15, 120, 36, 1),
    (4, 'OF-MAN-501', 'Mann-Filter Spin-On Oil Filter W 610/3', 5, 5, 'PIECE', 5.20, 12.99, 20, 150, 6, 1),
    (5, 'AF-DEN-112', 'Denso Premium Engine Air Filter', 5, 3, 'PIECE', 9.80, 21.50, 12, 90, 12, 1),
    (6, 'CF-BOS-302', 'Bosch HEPA Cabin Air Filter', 5, 1, 'PIECE', 11.00, 24.99, 10, 75, 12, 1),
    (7, 'SA-MON-780', 'Monroe OESpectrum Front Strut Assembly', 4, 6, 'PIECE', 68.00, 119.99, 6, 40, 24, 1),
    (8, 'BT-EXI-065', 'Exide Matrix 12V 65Ah Sealed Automotive Battery', 3, 7, 'PIECE', 72.00, 115.00, 5, 35, 36, 1);

    INSERT INTO vehicles (vehicle_id, make, model, year_start, year_end, engine_displacement, fuel_type, transmission) VALUES
    (1, 'Toyota', 'Corolla', 2014, 2019, '1.8L Dual VVT-i', 'PETROL', 'CVT'),
    (2, 'Toyota', 'Camry', 2018, 2024, '2.5L Hybrid', 'HYBRID', 'CVT'),
    (3, 'Honda', 'Civic', 2016, 2021, '1.5L Turbo', 'PETROL', 'CVT'),
    (4, 'Honda', 'City', 2017, 2023, '1.5L i-VTEC', 'PETROL', 'MANUAL'),
    (5, 'Hyundai', 'Creta', 2018, 2023, '1.5L CRDi Diesel', 'DIESEL', 'AUTOMATIC'),
    (6, 'Maruti Suzuki', 'Swift', 2017, 2024, '1.2L DualJet', 'PETROL', 'MANUAL');

    INSERT INTO part_compatibility (part_id, vehicle_id, position_notes) VALUES
    (1, 1, 'Front Axle (Both Wheels)'),
    (1, 2, 'Front Axle (LE & XLE trims)'),
    (2, 1, 'Front Brake Discs 275mm'),
    (3, 1, 'Cylinder Head - Gap 1.1mm'),
    (3, 3, 'Engine Block Cylinder Head'),
    (3, 6, 'Pack of 4 plugs'),
    (4, 1, 'Engine Oil Pan Filter Base'),
    (4, 3, 'Engine Block Oil Filter Port'),
    (5, 1, 'Air Cleaner Box Intake'),
    (6, 1, 'Behind Glovebox AC Unit'),
    (7, 1, 'Front Strut Assembly Left/Right'),
    (8, 1, 'Engine Bay Battery Tray'),
    (8, 5, 'Diesel Starter Heavy Duty Tray');

    INSERT INTO warehouses (warehouse_id, warehouse_code, warehouse_name, contact_phone, city, address_line) VALUES
    (1, 'WH-DEL-01', 'North Zone Central Hub', '+91-11-23456789', 'New Delhi', 'Okhla Phase III'),
    (2, 'WH-BLR-02', 'South Regional Depot', '+91-80-98765432', 'Bengaluru', 'Peenya Industrial Estate'),
    (3, 'WH-MUM-03', 'Western Logistics Park', '+91-22-45678901', 'Mumbai', 'Bhiwandi Hub');

    INSERT INTO inventory (inventory_id, part_id, warehouse_id, aisle, shelf, bin, quantity_on_hand, last_restocked_at) VALUES
    (1, 1, 1, 'A-01', 'S-02', 'B-14', 45, '2026-10-15 09:30:00'),
    (2, 2, 1, 'A-01', 'S-04', 'B-08', 25, '2026-10-15 09:30:00'),
    (3, 3, 1, 'A-02', 'S-01', 'B-22', 60, '2026-10-18 11:15:00'),
    (4, 4, 1, 'A-03', 'S-05', 'B-01', 85, '2026-10-20 14:00:00'),
    (5, 5, 1, 'A-03', 'S-03', 'B-09', 30, '2026-10-12 10:00:00'),
    (6, 6, 1, 'A-03', 'S-03', 'B-10', 4, '2026-09-25 16:00:00'),
    (7, 7, 1, 'B-01', 'S-01', 'B-04', 15, '2026-10-05 13:30:00'),
    (8, 8, 1, 'B-02', 'S-01', 'B-01', 3, '2026-09-20 10:00:00'),
    (9, 1, 2, 'A-10', 'S-01', 'B-02', 30, '2026-10-14 10:00:00'),
    (10, 2, 2, 'A-10', 'S-03', 'B-05', 18, '2026-10-14 10:00:00');

    INSERT INTO suppliers (supplier_id, company_name, contact_name, phone, email, rating) VALUES
    (1, 'Bosch India Distribution Ltd.', 'Rajesh Sharma', '+91-9811002233', 'orders@bosch-aftermarket.in', 4.9),
    (2, 'Brembo Brake Systems India', 'Marco Rossi', '+91-9822334455', 'sales@brembo-india.com', 4.8),
    (3, 'Denso Kirloskar Spares Corp.', 'Kiran Nair', '+91-9844556677', 'b2b@densokirloskar.com', 4.7);

    INSERT INTO customers (customer_id, customer_type, full_name, phone, email, city, discount_percentage) VALUES
    (1, 'WORKSHOP', 'Apex Precision Auto Workshop', '+91-9811223344', 'service@apexauto.in', 'New Delhi', 10.0),
    (2, 'FLEET', 'Metro City Cabs & Transport', '+91-9822334455', 'fleet@metrocabs.com', 'Mumbai', 15.0),
    (3, 'RETAIL', 'Arun Kumar', '+91-9876501234', 'arun.kumar@gmail.com', 'New Delhi', 0.0);

    INSERT INTO sales_orders (order_id, invoice_number, customer_id, order_date, subtotal, discount_amount, tax_rate_percent, tax_amount, grand_total, payment_status, payment_method, order_status, remarks) VALUES
    (1, 'INV-202610-1001', 1, '2026-10-20 11:30:00', 374.95, 37.50, 18.00, 60.74, 398.19, 'PAID', 'UPI', 'DELIVERED', 'Fleet maintenance batch');

    INSERT INTO sales_order_items (order_item_id, order_id, part_id, warehouse_id, quantity, unit_price, discount_applied, line_total) VALUES
    (1, 1, 1, 1, 5, 49.99, 25.00, 224.95),
    (2, 1, 4, 1, 10, 12.99, 12.99, 116.91);

    INSERT INTO stock_movements (part_id, warehouse_id, movement_type, quantity_changed, balance_after_movement, reference_id, notes) VALUES
    (1, 1, 'PURCHASE_RECEIPT', 50, 50, 'PO-202610-001', 'Initial stock intake'),
    (1, 1, 'SALE_DISPATCH', -5, 45, 'INV-202610-1001', 'Dispatched to Apex Precision'),
    (4, 1, 'SALE_DISPATCH', -10, 85, 'INV-202610-1001', 'Dispatched to Apex Precision');
    """)
