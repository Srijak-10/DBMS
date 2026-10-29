-- =============================================================================
-- VEHICLE SPARE PARTS AND INVENTORY MANAGEMENT SYSTEM (VSP-IMS)
-- Script 02: Database Views (Reporting, Catalog & Analytical Views)
-- =============================================================================

USE vehicle_inventory_db;

-- -----------------------------------------------------------------------------
-- 1. VIEW: vw_parts_catalog
-- Comprehensive catalog combining category, brand, margins, and total inventory
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_parts_catalog AS
SELECT 
    p.part_id,
    p.part_number,
    p.part_name,
    c.category_name,
    b.brand_name,
    b.country_of_origin AS brand_origin,
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
    b.country_of_origin, p.unit_of_measure, p.cost_price, p.selling_price, 
    p.min_stock_level, p.max_stock_level, p.warranty_months, p.is_active;

-- -----------------------------------------------------------------------------
-- 2. VIEW: vw_vehicle_compatibility_search
-- Allows immediate lookup of all compatible parts for any vehicle make/model/year
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_vehicle_compatibility_search AS
SELECT 
    v.vehicle_id,
    v.make,
    v.model,
    CONCAT(v.year_start, ' - ', v.year_end) AS production_years,
    v.engine_displacement,
    v.fuel_type,
    v.transmission,
    p.part_id,
    p.part_number,
    p.part_name,
    c.category_name,
    b.brand_name,
    p.selling_price,
    pc.position_notes,
    COALESCE(SUM(i.quantity_on_hand), 0) AS total_available_stock
FROM vehicles v
JOIN part_compatibility pc ON v.vehicle_id = pc.vehicle_id
JOIN parts p ON pc.part_id = p.part_id
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
LEFT JOIN inventory i ON p.part_id = i.part_id
GROUP BY 
    v.vehicle_id, v.make, v.model, v.year_start, v.year_end, v.engine_displacement, 
    v.fuel_type, v.transmission, p.part_id, p.part_number, p.part_name, 
    c.category_name, b.brand_name, p.selling_price, pc.position_notes;

-- -----------------------------------------------------------------------------
-- 3. VIEW: vw_low_stock_alerts
-- Inventory manager's dashboard view for triggering purchase orders
-- -----------------------------------------------------------------------------
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
    i.aisle,
    i.shelf,
    i.bin,
    i.last_restocked_at
FROM inventory i
JOIN parts p ON i.part_id = p.part_id
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
JOIN warehouses w ON i.warehouse_id = w.warehouse_id
WHERE i.quantity_on_hand <= p.min_stock_level
  AND p.is_active = TRUE;

-- -----------------------------------------------------------------------------
-- 4. VIEW: vw_warehouse_valuation
-- Total asset value stored in each warehouse (Cost Basis vs Retail Value)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_warehouse_valuation AS
SELECT 
    w.warehouse_id,
    w.warehouse_code,
    w.warehouse_name,
    w.city,
    COUNT(DISTINCT i.part_id) AS total_unique_skus,
    SUM(i.quantity_on_hand) AS total_units_in_stock,
    ROUND(SUM(i.quantity_on_hand * p.cost_price), 2) AS total_inventory_cost_value,
    ROUND(SUM(i.quantity_on_hand * p.selling_price), 2) AS total_inventory_retail_value,
    ROUND(SUM(i.quantity_on_hand * (p.selling_price - p.cost_price)), 2) AS potential_profit
FROM warehouses w
LEFT JOIN inventory i ON w.warehouse_id = i.warehouse_id
LEFT JOIN parts p ON i.part_id = p.part_id
GROUP BY w.warehouse_id, w.warehouse_code, w.warehouse_name, w.city;

-- -----------------------------------------------------------------------------
-- 5. VIEW: vw_sales_summary_by_category
-- High-level revenue and profit intelligence categorized by vehicle system
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_sales_summary_by_category AS
SELECT 
    c.category_id,
    c.category_name,
    COUNT(DISTINCT soi.order_id) AS total_orders,
    SUM(soi.quantity) AS total_units_sold,
    ROUND(SUM(soi.line_total), 2) AS gross_sales_revenue,
    ROUND(SUM(soi.quantity * p.cost_price), 2) AS total_cogs, -- Cost of Goods Sold
    ROUND(SUM(soi.line_total) - SUM(soi.quantity * p.cost_price), 2) AS net_margin
FROM categories c
JOIN parts p ON c.category_id = p.category_id
JOIN sales_order_items soi ON p.part_id = soi.part_id
JOIN sales_orders so ON soi.order_id = so.order_id
WHERE so.order_status NOT IN ('CANCELLED', 'RETURNED')
GROUP BY c.category_id, c.category_name;

-- -----------------------------------------------------------------------------
-- 6. VIEW: vw_customer_purchase_history
-- Lifetime customer value, frequency, and discount tier tracking
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_customer_purchase_history AS
SELECT 
    cust.customer_id,
    cust.full_name,
    cust.customer_type,
    cust.phone,
    cust.discount_percentage,
    COUNT(so.order_id) AS total_orders_placed,
    COALESCE(SUM(so.grand_total), 0.00) AS lifetime_expenditure,
    COALESCE(AVG(so.grand_total), 0.00) AS average_order_value,
    MAX(so.order_date) AS last_order_date
FROM customers cust
LEFT JOIN sales_orders so ON cust.customer_id = so.customer_id 
    AND so.order_status NOT IN ('CANCELLED')
GROUP BY 
    cust.customer_id, cust.full_name, cust.customer_type, cust.phone, cust.discount_percentage;
