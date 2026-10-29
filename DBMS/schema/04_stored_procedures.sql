-- =============================================================================
-- VEHICLE SPARE PARTS AND INVENTORY MANAGEMENT SYSTEM (VSP-IMS)
-- Script 04: Stored Procedures & Business Logic Functions
-- =============================================================================

USE vehicle_inventory_db;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- 1. FUNCTION: fn_calculate_reorder_urgency
-- Evaluates stock level severity for procurement decisions
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_calculate_reorder_urgency$$
CREATE FUNCTION fn_calculate_reorder_urgency(
    p_current_stock INT,
    p_min_stock INT
) 
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE urgency VARCHAR(20);
    
    IF p_current_stock <= 0 THEN
        SET urgency = 'CRITICAL_OUT_OF_STOCK';
    ELSEIF p_current_stock < (p_min_stock / 2) THEN
        SET urgency = 'HIGH_PRIORITY';
    ELSEIF p_current_stock <= p_min_stock THEN
        SET urgency = 'MODERATE_REORDER';
    ELSE
        SET urgency = 'ADEQUATE';
    END IF;
    
    RETURN urgency;
END$$

-- -----------------------------------------------------------------------------
-- 2. PROCEDURE: sp_create_sales_order
-- Initializes a new sales order invoice with customer specific discount
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_create_sales_order$$
CREATE PROCEDURE sp_create_sales_order(
    IN p_customer_id INT,
    IN p_payment_method ENUM('CASH', 'CREDIT_CARD', 'UPI', 'BANK_TRANSFER', 'CHEQUE'),
    IN p_remarks TEXT,
    OUT p_order_id INT,
    OUT p_invoice_number VARCHAR(30)
)
BEGIN
    DECLARE customer_exists INT DEFAULT 0;
    DECLARE cust_discount DECIMAL(4, 2) DEFAULT 0.00;
    DECLARE generated_inv VARCHAR(30);

    -- Check if customer exists
    SELECT COUNT(*), COALESCE(discount_percentage, 0.00) 
    INTO customer_exists, cust_discount
    FROM customers
    WHERE customer_id = p_customer_id
    GROUP BY customer_id;

    IF customer_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Customer ID does not exist.';
    END IF;

    -- Generate Unique Invoice Number (Format: INV-YYYYMMDD-XXXX)
    SET generated_inv = CONCAT('INV-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(FLOOR(RAND() * 10000), 4, '0'));

    INSERT INTO sales_orders (
        invoice_number, customer_id, order_date,
        subtotal, discount_amount, tax_rate_percent, 
        tax_amount, grand_total, payment_status, 
        payment_method, order_status, remarks
    ) VALUES (
        generated_inv, p_customer_id, NOW(),
        0.00, 0.00, 18.00,
        0.00, 0.00, 'PENDING',
        p_payment_method, 'CONFIRMED', p_remarks
    );

    SET p_order_id = LAST_INSERT_ID();
    SET p_invoice_number = generated_inv;
END$$

-- -----------------------------------------------------------------------------
-- 3. PROCEDURE: sp_add_order_item
-- Adds an item to an active sales order, applies customer discount, and fires triggers
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_add_order_item$$
CREATE PROCEDURE sp_add_order_item(
    IN p_order_id INT,
    IN p_part_id INT,
    IN p_warehouse_id INT,
    IN p_quantity INT
)
BEGIN
    DECLARE v_selling_price DECIMAL(10, 2);
    DECLARE v_cust_id INT;
    DECLARE v_discount_percent DECIMAL(4, 2) DEFAULT 0.00;
    DECLARE v_discount_val DECIMAL(10, 2) DEFAULT 0.00;

    -- Verify order exists and is not cancelled
    SELECT customer_id INTO v_cust_id
    FROM sales_orders
    WHERE order_id = p_order_id AND order_status NOT IN ('CANCELLED', 'DELIVERED');

    IF v_cust_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Order is not eligible for line item additions.';
    END IF;

    -- Fetch Part Selling Price
    SELECT selling_price INTO v_selling_price
    FROM parts
    WHERE part_id = p_part_id AND is_active = TRUE;

    IF v_selling_price IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Part is either inactive or does not exist.';
    END IF;

    -- Fetch Customer Discount Percentage
    SELECT COALESCE(discount_percentage, 0.00) INTO v_discount_percent
    FROM customers
    WHERE customer_id = v_cust_id;

    -- Calculate item discount
    SET v_discount_val = ROUND((v_selling_price * p_quantity) * (v_discount_percent / 100.0), 2);

    -- Insert line item (Triggers will validate inventory, decrement stock, and update order totals)
    INSERT INTO sales_order_items (
        order_id, part_id, warehouse_id, 
        quantity, unit_price, discount_applied, line_total
    ) VALUES (
        p_order_id, p_part_id, p_warehouse_id, 
        p_quantity, v_selling_price, v_discount_val, 
        (p_quantity * v_selling_price) - v_discount_val
    );
END$$

-- -----------------------------------------------------------------------------
-- 4. PROCEDURE: sp_transfer_warehouse_stock
-- Atomically transfers stock between two warehouses with ledger auditing
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_transfer_warehouse_stock$$
CREATE PROCEDURE sp_transfer_warehouse_stock(
    IN p_part_id INT,
    IN p_source_wh INT,
    IN p_dest_wh INT,
    IN p_quantity INT,
    IN p_transfer_ref VARCHAR(50)
)
BEGIN
    DECLARE source_stock INT DEFAULT 0;
    DECLARE dest_balance INT DEFAULT 0;
    DECLARE source_balance INT DEFAULT 0;

    IF p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transfer quantity must be strictly greater than 0.';
    END IF;

    IF p_source_wh = p_dest_wh THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Source and destination warehouses cannot be the same.';
    END IF;

    START TRANSACTION;

    -- Check source stock
    SELECT quantity_on_hand INTO source_stock
    FROM inventory
    WHERE part_id = p_part_id AND warehouse_id = p_source_wh
    FOR UPDATE;

    IF source_stock IS NULL OR source_stock < p_quantity THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transfer Failed: Insufficient quantity at source warehouse.';
    END IF;

    -- 1. Deduct from source warehouse
    UPDATE inventory
    SET quantity_on_hand = quantity_on_hand - p_quantity
    WHERE part_id = p_part_id AND warehouse_id = p_source_wh;

    SELECT quantity_on_hand INTO source_balance
    FROM inventory
    WHERE part_id = p_part_id AND warehouse_id = p_source_wh;

    -- 2. Audit log source deduction
    INSERT INTO stock_movements (
        part_id, warehouse_id, movement_type,
        quantity_changed, balance_after_movement,
        reference_id, notes
    ) VALUES (
        p_part_id, p_source_wh, 'WAREHOUSE_TRANSFER',
        -p_quantity, source_balance,
        p_transfer_ref, CONCAT('Transferred to Warehouse #', p_dest_wh)
    );

    -- 3. Add to destination warehouse (or create slot if not present)
    INSERT INTO inventory (part_id, warehouse_id, quantity_on_hand, last_restocked_at)
    VALUES (p_part_id, p_dest_wh, p_quantity, NOW())
    ON DUPLICATE KEY UPDATE
        quantity_on_hand = quantity_on_hand + p_quantity,
        last_restocked_at = NOW();

    SELECT quantity_on_hand INTO dest_balance
    FROM inventory
    WHERE part_id = p_part_id AND warehouse_id = p_dest_wh;

    -- 4. Audit log destination addition
    INSERT INTO stock_movements (
        part_id, warehouse_id, movement_type,
        quantity_changed, balance_after_movement,
        reference_id, notes
    ) VALUES (
        p_part_id, p_dest_wh, 'WAREHOUSE_TRANSFER',
        p_quantity, dest_balance,
        p_transfer_ref, CONCAT('Received from Warehouse #', p_source_wh)
    );

    COMMIT;
END$$

-- -----------------------------------------------------------------------------
-- 5. PROCEDURE: sp_find_compatible_parts
-- Flexible fitment search procedure by Make, Model, and optional Year/Category
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_find_compatible_parts$$
CREATE PROCEDURE sp_find_compatible_parts(
    IN p_make VARCHAR(50),
    IN p_model VARCHAR(70),
    IN p_year INT,
    IN p_category_filter VARCHAR(100)
)
BEGIN
    SELECT 
        v.make,
        v.model,
        v.year_start,
        v.year_end,
        v.engine_displacement,
        p.part_number,
        p.part_name,
        c.category_name,
        b.brand_name,
        p.selling_price,
        p.warranty_months,
        pc.position_notes,
        COALESCE(SUM(i.quantity_on_hand), 0) AS total_in_stock
    FROM vehicles v
    JOIN part_compatibility pc ON v.vehicle_id = pc.vehicle_id
    JOIN parts p ON pc.part_id = p.part_id
    JOIN categories c ON p.category_id = c.category_id
    JOIN brands b ON p.brand_id = b.brand_id
    LEFT JOIN inventory i ON p.part_id = i.part_id
    WHERE LOWER(v.make) = LOWER(p_make)
      AND LOWER(v.model) = LOWER(p_model)
      AND (p_year IS NULL OR (p_year BETWEEN v.year_start AND v.year_end))
      AND (p_category_filter IS NULL OR LOWER(c.category_name) LIKE CONCAT('%', LOWER(p_category_filter), '%'))
    GROUP BY 
        v.make, v.model, v.year_start, v.year_end, v.engine_displacement,
        p.part_number, p.part_name, c.category_name, b.brand_name,
        p.selling_price, p.warranty_months, pc.position_notes
    ORDER BY c.category_name, p.selling_price ASC;
END$$

-- -----------------------------------------------------------------------------
-- 6. PROCEDURE: sp_monthly_financial_report
-- Comprehensive revenue, cost of goods, and net profit report
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_monthly_financial_report$$
CREATE PROCEDURE sp_monthly_financial_report(
    IN p_year INT,
    IN p_month INT
)
BEGIN
    SELECT 
        p_year AS report_year,
        p_month AS report_month,
        COUNT(DISTINCT so.order_id) AS total_invoices_issued,
        SUM(soi.quantity) AS total_items_sold,
        ROUND(SUM(soi.line_total), 2) AS gross_sales,
        ROUND(SUM(so.discount_amount), 2) AS total_discounts_granted,
        ROUND(SUM(so.tax_amount), 2) AS total_tax_collected,
        ROUND(SUM(so.grand_total), 2) AS net_revenue,
        ROUND(SUM(soi.quantity * p.cost_price), 2) AS total_cost_of_goods,
        ROUND(SUM(soi.line_total) - SUM(soi.quantity * p.cost_price), 2) AS gross_profit
    FROM sales_orders so
    JOIN sales_order_items soi ON so.order_id = soi.order_id
    JOIN parts p ON soi.part_id = p.part_id
    WHERE YEAR(so.order_date) = p_year
      AND MONTH(so.order_date) = p_month
      AND so.order_status NOT IN ('CANCELLED');
END$$

DELIMITER ;
