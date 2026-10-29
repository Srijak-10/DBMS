-- =============================================================================
-- VEHICLE SPARE PARTS AND INVENTORY MANAGEMENT SYSTEM (VSP-IMS)
-- Script 06: Comprehensive Analytical, Reporting & Business Queries
-- Designed for DBMS Lab, Viva, Reporting Dashboards & Audits
-- =============================================================================

USE vehicle_inventory_db;

-- -----------------------------------------------------------------------------
-- QUERY 1: Vehicle Specific Fitment Lookup
-- Scenario: A customer walks into the shop with a 2018 Toyota Corolla.
-- Find all compatible parts, their category, price, and stock in Delhi Central Hub.
-- -----------------------------------------------------------------------------
SELECT 
    v.make,
    v.model,
    v.year_start,
    v.year_end,
    p.part_number,
    p.part_name,
    c.category_name,
    b.brand_name,
    p.selling_price,
    pc.position_notes,
    COALESCE(i.quantity_on_hand, 0) AS stock_in_delhi
FROM vehicles v
JOIN part_compatibility pc ON v.vehicle_id = pc.vehicle_id
JOIN parts p ON pc.part_id = p.part_id
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
LEFT JOIN inventory i ON p.part_id = i.part_id AND i.warehouse_id = 1
WHERE v.make = 'Toyota' 
  AND v.model = 'Corolla'
  AND (2018 BETWEEN v.year_start AND v.year_end)
ORDER BY c.category_name, p.selling_price;

-- -----------------------------------------------------------------------------
-- QUERY 2: Top 5 Best-Selling Spare Parts by Revenue & Units
-- Scenario: Identify highest-earning catalog items for marketing campaigns.
-- -----------------------------------------------------------------------------
SELECT 
    p.part_number,
    p.part_name,
    b.brand_name,
    c.category_name,
    SUM(soi.quantity) AS total_units_sold,
    ROUND(SUM(soi.line_total), 2) AS total_revenue_generated,
    ROUND(SUM(soi.line_total) - SUM(soi.quantity * p.cost_price), 2) AS net_profit
FROM sales_order_items soi
JOIN parts p ON soi.part_id = p.part_id
JOIN brands b ON p.brand_id = b.brand_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY p.part_id, p.part_number, p.part_name, b.brand_name, c.category_name
ORDER BY total_revenue_generated DESC
LIMIT 5;

-- -----------------------------------------------------------------------------
-- QUERY 3: Dead Stock / Slow-Moving Inventory Detection
-- Scenario: Find active parts with stock on hand that have NEVER been sold,
-- or have had zero sales to identify dead capital.
-- -----------------------------------------------------------------------------
SELECT 
    p.part_id,
    p.part_number,
    p.part_name,
    b.brand_name,
    c.category_name,
    SUM(i.quantity_on_hand) AS total_unsold_stock,
    ROUND(SUM(i.quantity_on_hand * p.cost_price), 2) AS capital_tied_up
FROM parts p
JOIN brands b ON p.brand_id = b.brand_id
JOIN categories c ON p.category_id = c.category_id
JOIN inventory i ON p.part_id = i.part_id
WHERE p.part_id NOT IN (
    SELECT DISTINCT part_id FROM sales_order_items
)
GROUP BY p.part_id, p.part_number, p.part_name, b.brand_name, c.category_name
HAVING total_unsold_stock > 0
ORDER BY capital_tied_up DESC;

-- -----------------------------------------------------------------------------
-- QUERY 4: Multi-Warehouse Inventory Pivot Matrix
-- Scenario: Compare stock across Delhi, Bengaluru, and Mumbai side-by-side.
-- -----------------------------------------------------------------------------
SELECT 
    p.part_number,
    p.part_name,
    b.brand_name,
    COALESCE(SUM(CASE WHEN i.warehouse_id = 1 THEN i.quantity_on_hand ELSE 0 END), 0) AS delhi_stock,
    COALESCE(SUM(CASE WHEN i.warehouse_id = 2 THEN i.quantity_on_hand ELSE 0 END), 0) AS blr_stock,
    COALESCE(SUM(CASE WHEN i.warehouse_id = 3 THEN i.quantity_on_hand ELSE 0 END), 0) AS mumbai_stock,
    COALESCE(SUM(i.quantity_on_hand), 0) AS total_network_stock,
    p.min_stock_level,
    CASE 
        WHEN COALESCE(SUM(i.quantity_on_hand), 0) <= p.min_stock_level THEN 'ALERT: REORDER'
        ELSE 'HEALTHY'
    END AS status
FROM parts p
JOIN brands b ON p.brand_id = b.brand_id
LEFT JOIN inventory i ON p.part_id = i.part_id
GROUP BY p.part_id, p.part_number, p.part_name, b.brand_name, p.min_stock_level
ORDER BY p.part_name;

-- -----------------------------------------------------------------------------
-- QUERY 5: Customer Ranking & Contribution (Window Function DENSE_RANK)
-- Scenario: Segment customers into VIP/Key Accounts by total spend.
-- -----------------------------------------------------------------------------
SELECT 
    c.customer_id,
    c.full_name,
    c.customer_type,
    c.phone,
    COUNT(so.order_id) AS total_orders,
    ROUND(SUM(so.grand_total), 2) AS total_spent,
    ROUND(AVG(so.grand_total), 2) AS avg_invoice_value,
    DENSE_RANK() OVER (ORDER BY SUM(so.grand_total) DESC) AS customer_revenue_rank
FROM customers c
JOIN sales_orders so ON c.customer_id = so.customer_id
WHERE so.order_status NOT IN ('CANCELLED')
GROUP BY c.customer_id, c.full_name, c.customer_type, c.phone;

-- -----------------------------------------------------------------------------
-- QUERY 6: Brand Profitability & Margin Comparison
-- Scenario: Compare OEM vs aftermarket brand profit margins.
-- -----------------------------------------------------------------------------
SELECT 
    b.brand_name,
    b.country_of_origin,
    b.is_oem,
    COUNT(DISTINCT p.part_id) AS total_catalog_parts,
    ROUND(AVG(p.cost_price), 2) AS avg_cost,
    ROUND(AVG(p.selling_price), 2) AS avg_retail,
    ROUND(AVG(((p.selling_price - p.cost_price) / p.cost_price) * 100), 1) AS avg_markup_percentage,
    COALESCE(SUM(soi.quantity), 0) AS total_units_sold,
    COALESCE(ROUND(SUM(soi.line_total), 2), 0.00) AS total_brand_revenue
FROM brands b
JOIN parts p ON b.brand_id = p.brand_id
LEFT JOIN sales_order_items soi ON p.part_id = soi.part_id
GROUP BY b.brand_id, b.brand_name, b.country_of_origin, b.is_oem
ORDER BY total_brand_revenue DESC;

-- -----------------------------------------------------------------------------
-- QUERY 7: Most Universal Spare Parts (High Fitment Count)
-- Scenario: Find parts that fit the largest variety of vehicle models.
-- -----------------------------------------------------------------------------
SELECT 
    p.part_number,
    p.part_name,
    c.category_name,
    b.brand_name,
    COUNT(pc.vehicle_id) AS compatible_vehicle_count,
    GROUP_CONCAT(CONCAT(v.make, ' ', v.model) SEPARATOR '; ') AS fits_models
FROM parts p
JOIN part_compatibility pc ON p.part_id = pc.part_id
JOIN vehicles v ON pc.vehicle_id = v.vehicle_id
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
GROUP BY p.part_id, p.part_number, p.part_name, c.category_name, b.brand_name
HAVING compatible_vehicle_count >= 2
ORDER BY compatible_vehicle_count DESC;

-- -----------------------------------------------------------------------------
-- QUERY 8: Purchase Order Fulfillment & Supplier On-Time Performance
-- Scenario: Assess supplier lead times and punctuality.
-- -----------------------------------------------------------------------------
SELECT 
    po.po_number,
    s.company_name AS supplier_name,
    s.contact_name,
    po.order_date,
    po.expected_delivery_date,
    po.received_date,
    DATEDIFF(po.received_date, po.expected_delivery_date) AS delivery_variance_days,
    CASE 
        WHEN po.received_date IS NULL THEN 'IN TRANSIT / PENDING'
        WHEN po.received_date <= po.expected_delivery_date THEN 'ON TIME'
        ELSE CONCAT('DELAYED BY ', DATEDIFF(po.received_date, po.expected_delivery_date), ' DAYS')
    END AS fulfillment_status,
    po.total_amount,
    po.status
FROM purchase_orders po
JOIN suppliers s ON po.supplier_id = s.supplier_id
ORDER BY po.order_date DESC;

-- -----------------------------------------------------------------------------
-- QUERY 9: Complete Audit Trail for Part (Stock Movement History)
-- Scenario: Trace every transaction involving 'Bosch QuietCast Ceramic Brake Pads' (part_id = 1).
-- -----------------------------------------------------------------------------
SELECT 
    sm.movement_id,
    sm.created_at AS timestamp,
    w.warehouse_code,
    sm.movement_type,
    sm.quantity_changed,
    sm.balance_after_movement,
    sm.reference_id,
    sm.notes
FROM stock_movements sm
JOIN warehouses w ON sm.warehouse_id = w.warehouse_id
WHERE sm.part_id = 1
ORDER BY sm.created_at ASC;

-- -----------------------------------------------------------------------------
-- QUERY 10: Frequently Bought Together (Cross-Selling / Market Basket Query)
-- Scenario: Find pairs of parts that appear together in the same sales invoice.
-- -----------------------------------------------------------------------------
SELECT 
    p1.part_name AS part_a,
    p2.part_name AS part_b,
    COUNT(*) AS times_bought_together
FROM sales_order_items item1
JOIN sales_order_items item2 ON item1.order_id = item2.order_id AND item1.part_id < item2.part_id
JOIN parts p1 ON item1.part_id = p1.part_id
JOIN parts p2 ON item2.part_id = p2.part_id
GROUP BY p1.part_name, p2.part_name
ORDER BY times_bought_together DESC;
