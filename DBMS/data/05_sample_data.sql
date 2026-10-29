-- =============================================================================
-- VEHICLE SPARE PARTS AND INVENTORY MANAGEMENT SYSTEM (VSP-IMS)
-- Script 05: Realistic Sample Seed Data (DML)
-- =============================================================================

USE vehicle_inventory_db;

-- -----------------------------------------------------------------------------
-- 1. Insert Categories (Hierarchical Vehicle Systems)
-- -----------------------------------------------------------------------------
INSERT INTO categories (category_id, parent_category_id, category_name, description) VALUES
(1, NULL, 'Braking System', 'Pads, discs, calipers, master cylinders, and brake fluid'),
(2, NULL, 'Engine Components', 'Pistons, valves, gaskets, belts, and ignition items'),
(3, NULL, 'Electrical & Lighting', 'Batteries, alternators, starters, bulbs, and sensors'),
(4, NULL, 'Suspension & Steering', 'Shock absorbers, struts, control arms, and tie rods'),
(5, NULL, 'Filters & Fluids', 'Oil filters, air filters, cabin filters, and lubricants'),
(6, NULL, 'Transmission & Drivetrain', 'Clutch kits, torque converters, CV axles, and gears'),
(7, 1, 'Brake Pads & Shoes', 'Friction pads for disc brakes and shoes for drum brakes'),
(8, 1, 'Brake Rotors & Drums', 'Ventilated and solid disc rotors and rear brake drums'),
(9, 2, 'Ignition & Plugs', 'Spark plugs, glow plugs, and ignition coils'),
(10, 5, 'Air & Cabin Filtration', 'Engine intake air cleaners and cabin AC pollen filters');

-- -----------------------------------------------------------------------------
-- 2. Insert Brands (Manufacturers & Suppliers)
-- -----------------------------------------------------------------------------
INSERT INTO brands (brand_id, brand_name, country_of_origin, website, is_oem) VALUES
(1, 'Bosch', 'Germany', 'https://www.bosch-automotive.com', TRUE),
(2, 'Brembo', 'Italy', 'https://www.brembo.com', TRUE),
(3, 'Denso', 'Japan', 'https://www.denso.com', TRUE),
(4, 'NGK Spark Plugs', 'Japan', 'https://www.ngkntk.com', TRUE),
(5, 'Mann-Filter', 'Germany', 'https://www.mann-filter.com', TRUE),
(6, 'Monroe', 'United States', 'https://www.monroe.com', FALSE),
(7, 'Exide Industries', 'India', 'https://www.exideindustries.com', TRUE),
(8, 'Mobil 1', 'United States', 'https://www.mobil.com', FALSE),
(9, 'Valeo', 'France', 'https://www.valeo.com', TRUE),
(10, 'OEM Genuine Spares', 'Japan', 'https://www.oem-auto.com', TRUE);

-- -----------------------------------------------------------------------------
-- 3. Insert Parts Catalog
-- -----------------------------------------------------------------------------
INSERT INTO parts (part_id, part_number, part_name, category_id, brand_id, unit_of_measure, cost_price, selling_price, min_stock_level, max_stock_level, warranty_months, is_active) VALUES
(1, 'BP-BOS-001', 'Bosch QuietCast Ceramic Front Brake Pads', 7, 1, 'SET', 28.00, 49.99, 10, 80, 12, TRUE),
(2, 'BP-BRE-002', 'Brembo Premium Disc Brake Rotor (Ventilated)', 8, 2, 'PIECE', 42.00, 78.50, 8, 60, 24, TRUE),
(3, 'SP-NGK-944', 'NGK Laser Iridium Spark Plug (Pack of 4)', 9, 4, 'SET', 22.50, 44.00, 15, 120, 36, TRUE),
(4, 'OF-MAN-501', 'Mann-Filter Spin-On Oil Filter W 610/3', 5, 5, 'PIECE', 5.20, 12.99, 20, 150, 6, TRUE),
(5, 'AF-DEN-112', 'Denso Premium Engine Air Filter', 10, 3, 'PIECE', 9.80, 21.50, 12, 90, 12, TRUE),
(6, 'CF-BOS-302', 'Bosch HEPA Cabin Air Filter', 10, 1, 'PIECE', 11.00, 24.99, 10, 75, 12, TRUE),
(7, 'SA-MON-780', 'Monroe OESpectrum Front Strut Assembly', 4, 6, 'PIECE', 68.00, 119.99, 6, 40, 24, TRUE),
(8, 'BT-EXI-065', 'Exide Matrix 12V 65Ah Sealed Automotive Battery', 3, 7, 'PIECE', 72.00, 115.00, 5, 35, 36, TRUE),
(9, 'AL-DEN-450', 'Denso High-Output 12V 110A Alternator', 3, 3, 'PIECE', 140.00, 245.00, 4, 25, 24, TRUE),
(10, 'OL-MOB-5W30', 'Mobil 1 Advanced Full Synthetic 5W-30 (4L Can)', 5, 8, 'CAN', 26.00, 45.00, 15, 100, 0, TRUE),
(11, 'CK-VAL-882', 'Valeo 3-Piece Heavy Duty Clutch Kit', 6, 9, 'SET', 110.00, 195.00, 5, 30, 24, TRUE),
(12, 'TB-BOS-901', 'Bosch High-Tensile Timing Belt & Water Pump Kit', 2, 1, 'SET', 75.00, 139.99, 6, 45, 24, TRUE);

-- -----------------------------------------------------------------------------
-- 4. Insert Vehicles Reference Data
-- -----------------------------------------------------------------------------
INSERT INTO vehicles (vehicle_id, make, model, year_start, year_end, engine_displacement, fuel_type, transmission) VALUES
(1, 'Toyota', 'Corolla', 2014, 2019, '1.8L Dual VVT-i', 'PETROL', 'CVT'),
(2, 'Toyota', 'Camry', 2018, 2024, '2.5L Hybrid', 'HYBRID', 'CVT'),
(3, 'Honda', 'Civic', 2016, 2021, '1.5L Turbo', 'PETROL', 'CVT'),
(4, 'Honda', 'City', 2017, 2023, '1.5L i-VTEC', 'PETROL', 'MANUAL'),
(5, 'Ford', 'F-150', 2015, 2020, '3.5L EcoBoost V6', 'PETROL', 'AUTOMATIC'),
(6, 'Hyundai', 'Creta', 2018, 2023, '1.5L CRDi Diesel', 'DIESEL', 'AUTOMATIC'),
(7, 'Maruti Suzuki', 'Swift', 2017, 2024, '1.2L K12M DualJet', 'PETROL', 'MANUAL'),
(8, 'BMW', '3 Series (G20)', 2019, 2024, '2.0L TwinPower Turbo', 'DIESEL', 'AUTOMATIC');

-- -----------------------------------------------------------------------------
-- 5. Insert Part Compatibility (Fitment Matrix)
-- -----------------------------------------------------------------------------
INSERT INTO part_compatibility (part_id, vehicle_id, position_notes) VALUES
(1, 1, 'Front Axle (Both Wheels)'),
(1, 2, 'Front Axle (Fits LE & XLE trims)'),
(2, 1, 'Front Brake Discs (Ventilated 275mm)'),
(2, 2, 'Front Brake Discs (Ventilated 296mm)'),
(3, 1, 'Engine Cylinder Head - Gap 1.1mm'),
(3, 3, 'Engine Cylinder Head - Pre-gapped'),
(3, 4, 'Engine Cylinder Head'),
(3, 7, 'Cylinder Head - 4 Spark Plugs Required'),
(4, 1, 'Engine Oil Pan Filter Base'),
(4, 3, 'Engine Block Oil Filter Port'),
(4, 4, 'Engine Block Oil Filter Port'),
(5, 1, 'Air Cleaner Box Intake'),
(5, 4, 'Air Filter Housing'),
(6, 1, 'Behind Glovebox AC Unit'),
(6, 3, 'Under Dashboard HVAC Housing'),
(6, 6, 'AC Cabin Housing'),
(7, 1, 'Front Suspension Strut Left/Right'),
(7, 4, 'Front Strut Assembly'),
(8, 1, 'Engine Bay Battery Tray (Standard Terminal)'),
(8, 3, 'Engine Bay Battery Tray'),
(8, 6, 'Heavy Duty Diesel Starter Tray'),
(8, 7, 'Engine Bay Battery Bracket'),
(9, 1, 'Engine Front Accessory Belt Mount'),
(10, 1, 'Engine Crankcase (Requires 4.2 Liters)'),
(10, 3, 'Engine Crankcase (Requires 3.7 Liters)'),
(10, 7, 'Engine Crankcase (Requires 3.1 Liters)'),
(11, 4, 'Manual Transmission Bellhousing'),
(11, 7, 'Manual Transmission Bellhousing'),
(12, 1, 'Engine Timing Cover (Includes Tensioner & Idler)'),
(12, 6, 'Diesel Timing Drive Assembly');

-- -----------------------------------------------------------------------------
-- 6. Insert Warehouses
-- -----------------------------------------------------------------------------
INSERT INTO warehouses (warehouse_id, warehouse_code, warehouse_name, contact_phone, contact_email, city, state, country, address_line) VALUES
(1, 'WH-DEL-01', 'North Zone Central Hub', '+91-11-23456789', 'delhi.hub@autospares.com', 'New Delhi', 'Delhi', 'India', 'Sector 18 Industrial Area, Okhla Phase III'),
(2, 'WH-BLR-02', 'South Regional Logistics Depot', '+91-80-98765432', 'blr.depot@autospares.com', 'Bengaluru', 'Karnataka', 'India', 'Plot 45, Peenya Industrial Estate 2nd Stage'),
(3, 'WH-MUM-03', 'Western Coastal Distribution Center', '+91-22-45678901', 'mumbai.wh@autospares.com', 'Mumbai', 'Maharashtra', 'India', 'Bhiwandi Warehousing Logistics Park, Thane');

-- -----------------------------------------------------------------------------
-- 7. Insert Suppliers
-- -----------------------------------------------------------------------------
INSERT INTO suppliers (supplier_id, company_name, contact_name, phone, email, tax_registration_no, address, city, country, payment_terms, rating) VALUES
(1, 'Bosch India Distribution Ltd.', 'Rajesh Sharma', '+91-9811002233', 'orders@bosch-aftermarket.in', '07AAACB1234F1Z1', 'Electronic City Phase 1', 'Bengaluru', 'India', 'Net 30', 4.9),
(2, 'Brembo Brake Systems India', 'Marco Rossi', '+91-9822334455', 'sales@brembo-india.com', '27AABCB5678G2Z3', 'Chakan Industrial Area', 'Pune', 'India', 'Net 45', 4.8),
(3, 'Denso Kirloskar Spares Corp.', 'Kiran Nair', '+91-9844556677', 'b2b@densokirloskar.com', '29AACCD9012H1Z5', 'Whitefield Main Road', 'Bengaluru', 'India', 'Net 30', 4.7),
(4, 'Mann & Hummel Filtration Spares', 'Vikram Desai', '+91-9877889900', 'spares@mann-hummel.in', '24AAACM3456J1Z8', 'Bawal Growth Centre', 'Rewari', 'India', 'Net 15', 4.6),
(5, 'Apex Fleet Wholesale Distributors', 'Suresh Gupta', '+91-9899112233', 'apex.dist@gmail.com', '07AAACA7890K1Z9', 'Kashmere Gate Motor Market', 'Delhi', 'India', 'Immediate', 4.2);

-- -----------------------------------------------------------------------------
-- 8. Insert Inventory Stock
-- -----------------------------------------------------------------------------
INSERT INTO inventory (inventory_id, part_id, warehouse_id, aisle, shelf, bin, quantity_on_hand, quantity_reserved, last_restocked_at) VALUES
-- Warehouse 1 (Delhi)
(1, 1, 1, 'A-01', 'S-02', 'B-14', 45, 2, '2026-10-15 09:30:00'),
(2, 2, 1, 'A-01', 'S-04', 'B-08', 25, 0, '2026-10-15 09:30:00'),
(3, 3, 1, 'A-02', 'S-01', 'B-22', 60, 4, '2026-10-18 11:15:00'),
(4, 4, 1, 'A-03', 'S-05', 'B-01', 85, 5, '2026-10-20 14:00:00'),
(5, 5, 1, 'A-03', 'S-03', 'B-09', 30, 0, '2026-10-12 10:00:00'),
(6, 6, 1, 'A-03', 'S-03', 'B-10', 4, 0, '2026-09-25 16:00:00'), -- Low stock (min: 10)
(7, 7, 1, 'B-01', 'S-01', 'B-04', 15, 1, '2026-10-05 13:30:00'),
(8, 8, 1, 'B-02', 'S-01', 'B-01', 3, 0, '2026-09-20 10:00:00'),  -- Low stock (min: 5)
(9, 9, 1, 'B-02', 'S-03', 'B-07', 8, 0, '2026-10-02 12:00:00'),
(10, 10, 1, 'C-01', 'S-01', 'B-12', 40, 2, '2026-10-22 15:00:00'),
(11, 11, 1, 'C-02', 'S-02', 'B-05', 2, 0, '2026-09-18 11:00:00'), -- Low stock (min: 5)
(12, 12, 1, 'C-02', 'S-04', 'B-03', 18, 0, '2026-10-10 16:45:00'),

-- Warehouse 2 (Bengaluru)
(13, 1, 2, 'A-10', 'S-01', 'B-02', 30, 0, '2026-10-14 10:00:00'),
(14, 2, 2, 'A-10', 'S-03', 'B-05', 18, 1, '2026-10-14 10:00:00'),
(15, 3, 2, 'A-11', 'S-02', 'B-12', 50, 0, '2026-10-16 11:30:00'),
(16, 4, 2, 'A-12', 'S-04', 'B-18', 70, 0, '2026-10-17 14:20:00'),
(17, 7, 2, 'B-05', 'S-02', 'B-02', 8, 0, '2026-10-08 09:15:00'),
(18, 8, 2, 'B-06', 'S-01', 'B-03', 12, 0, '2026-10-11 15:40:00'),
(19, 10, 2, 'C-04', 'S-02', 'B-08', 35, 0, '2026-10-21 16:00:00');

-- -----------------------------------------------------------------------------
-- 9. Insert Customers
-- -----------------------------------------------------------------------------
INSERT INTO customers (customer_id, customer_type, full_name, phone, email, tax_id, address, city, discount_percentage) VALUES
(1, 'WORKSHOP', 'Apex Precision Auto Workshop', '+91-9811223344', 'service@apexauto.in', '07AAAAA1111A1Z1', '42, Industrial Area, Mayapuri', 'New Delhi', 10.00),
(2, 'FLEET', 'Metro City Cabs & Transport Services', '+91-9822334455', 'fleetmanager@metrocabs.com', '27BBBBB2222B2Z2', 'Andheri East Commercial Complex', 'Mumbai', 15.00),
(3, 'RETAIL', 'Arun Kumar', '+91-9876501234', 'arun.kumar@gmail.com', NULL, 'Flat 302, Green Park Apartments', 'New Delhi', 0.00),
(4, 'WORKSHOP', 'FastTrack Motors Multi-Brand Garage', '+91-9833445566', 'care@fasttrackmotors.com', '29CCCCC3333C3Z3', 'Koramangala 4th Block', 'Bengaluru', 8.00),
(5, 'RETAIL', 'Pooja Verma', '+91-9844551122', 'pooja.verma88@yahoo.com', NULL, 'B-12, Sector 62', 'Noida', 0.00);

-- -----------------------------------------------------------------------------
-- 10. Insert Purchase Orders
-- -----------------------------------------------------------------------------
INSERT INTO purchase_orders (po_id, po_number, supplier_id, warehouse_id, order_date, expected_delivery_date, received_date, total_amount, status, notes) VALUES
(1, 'PO-202610-001', 1, 1, '2026-10-01', '2026-10-10', '2026-10-09', 2850.00, 'COMPLETED', 'Stock replenishment for Q4 Braking & Timing kits'),
(2, 'PO-202610-002', 2, 1, '2026-10-05', '2026-10-15', '2026-10-14', 1680.00, 'COMPLETED', 'Brembo Brake Rotors batch order'),
(3, 'PO-202610-003', 3, 2, '2026-10-25', '2026-11-05', NULL, 1890.00, 'ORDERED', 'Denso Filters & Alternators delivery for Bangalore'),
(4, 'PO-202610-004', 1, 1, '2026-10-28', '2026-11-04', NULL, 1100.00, 'PENDING', 'Urgent reorder for Bosch HEPA cabin filters');

-- -----------------------------------------------------------------------------
-- 11. Insert Purchase Order Line Items
-- -----------------------------------------------------------------------------
INSERT INTO purchase_order_items (po_item_id, po_id, part_id, quantity_ordered, quantity_received, unit_cost) VALUES
(1, 1, 1, 50, 50, 28.00),
(2, 1, 12, 20, 20, 75.00),
(3, 2, 2, 40, 40, 42.00),
(4, 3, 5, 50, 0, 9.80),
(5, 3, 9, 10, 0, 140.00),
(6, 4, 6, 100, 0, 11.00);

-- -----------------------------------------------------------------------------
-- 12. Insert Sales Orders (Direct Seed)
-- Note: We disable triggers temporarily during initial seed to avoid double deduction
-- -----------------------------------------------------------------------------
SET @TRIGGER_DISABLED = TRUE;

INSERT INTO sales_orders (order_id, invoice_number, customer_id, order_date, subtotal, discount_amount, tax_rate_percent, tax_amount, grand_total, payment_status, payment_method, order_status, remarks) VALUES
(1, 'INV-202610-1001', 1, '2026-10-20 11:30:00', 374.95, 37.50, 18.00, 60.74, 398.19, 'PAID', 'UPI', 'DELIVERED', 'Fleet maintenance order for 5 Corolla units'),
(2, 'INV-202610-1002', 2, '2026-10-22 14:15:00', 890.00, 133.50, 18.00, 136.17, 892.67, 'PAID', 'BANK_TRANSFER', 'DELIVERED', 'Quarterly servicing batch'),
(3, 'INV-202610-1003', 3, '2026-10-26 16:45:00', 49.99, 0.00, 18.00, 9.00, 58.99, 'PAID', 'CREDIT_CARD', 'CONFIRMED', 'Retail counter sale - Walk-in'),
(4, 'INV-202610-1004', 4, '2026-10-28 10:20:00', 585.00, 46.80, 18.00, 96.88, 635.08, 'PENDING', 'CHEQUE', 'CONFIRMED', 'Commercial garage account sale');

INSERT INTO sales_order_items (order_item_id, order_id, part_id, warehouse_id, quantity, unit_price, discount_applied, line_total) VALUES
-- Order 1: Apex Workshop
(1, 1, 1, 1, 5, 49.99, 25.00, 224.95),
(2, 1, 4, 1, 10, 12.99, 12.99, 116.91),
(3, 1, 3, 1, 1, 44.00, 4.40, 39.60),
-- Order 2: Metro Cabs
(4, 2, 10, 1, 10, 45.00, 67.50, 382.50),
(5, 2, 8, 1, 2, 115.00, 34.50, 195.50),
(6, 2, 2, 1, 4, 78.50, 47.10, 266.90),
-- Order 3: Retail Arun Kumar
(7, 3, 1, 1, 1, 49.99, 0.00, 49.99),
-- Order 4: FastTrack Motors
(8, 4, 11, 2, 3, 195.00, 46.80, 538.20);

-- -----------------------------------------------------------------------------
-- 13. Insert Initial Stock Movement Audit Logs
-- -----------------------------------------------------------------------------
INSERT INTO stock_movements (part_id, warehouse_id, movement_type, quantity_changed, balance_after_movement, reference_id, notes) VALUES
(1, 1, 'PURCHASE_RECEIPT', 50, 50, 'PO-202610-001', 'Initial stock intake'),
(1, 1, 'SALE_DISPATCH', -5, 45, 'INV-202610-1001', 'Order dispatched to Apex Precision'),
(2, 1, 'PURCHASE_RECEIPT', 40, 40, 'PO-202610-002', 'Brembo intake'),
(2, 1, 'SALE_DISPATCH', -4, 36, 'INV-202610-1002', 'Dispatched to Metro City Cabs'),
(4, 1, 'SALE_DISPATCH', -10, 85, 'INV-202610-1001', 'Dispatched to Apex Precision'),
(10, 1, 'SALE_DISPATCH', -10, 40, 'INV-202610-1002', 'Dispatched to Metro City Cabs'),
(11, 2, 'SALE_DISPATCH', -3, 2, 'INV-202610-1004', 'Dispatched to FastTrack Motors');
