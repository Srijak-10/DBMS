-- =============================================================================
-- VEHICLE SPARE PARTS AND INVENTORY MANAGEMENT SYSTEM (VSP-IMS)
-- Script 03: Automated Triggers (Integrity, Stock Auto-Deduction & Auditing)
-- =============================================================================

USE vehicle_inventory_db;

DELIMITER $$

-- -----------------------------------------------------------------------------
-- 1. TRIGGER: trg_validate_and_calc_sales_item (BEFORE INSERT)
-- - Verifies stock availability before an item is added to an order.
-- - Automatically calculates line_total factoring unit_price & discounts.
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_validate_and_calc_sales_item$$
CREATE TRIGGER trg_validate_and_calc_sales_item
BEFORE INSERT ON sales_order_items
FOR EACH ROW
BEGIN
    DECLARE current_stock INT DEFAULT 0;
    DECLARE part_sku VARCHAR(50);

    -- Fetch current stock in the targeted warehouse
    SELECT quantity_on_hand INTO current_stock
    FROM inventory
    WHERE part_id = NEW.part_id AND warehouse_id = NEW.warehouse_id;

    -- Fetch SKU for descriptive error message
    SELECT part_number INTO part_sku
    FROM parts
    WHERE part_id = NEW.part_id;

    -- Stock check validation
    IF current_stock IS NULL OR current_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction Rejected: Insufficient inventory on hand for this spare part.';
    END IF;

    -- Automatic line total computation
    SET NEW.line_total = (NEW.quantity * NEW.unit_price) - COALESCE(NEW.discount_applied, 0.00);
END$$

-- -----------------------------------------------------------------------------
-- 2. TRIGGER: trg_after_sales_item_insert (AFTER INSERT)
-- - Deducts inventory quantity from warehouse in real-time.
-- - Records an immutable entry in stock_movements ledger.
-- - Updates parent sales order subtotal and grand total.
-- -----------------------------------------------------------------------------
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

    -- Deduct inventory
    UPDATE inventory
    SET quantity_on_hand = quantity_on_hand - NEW.quantity
    WHERE part_id = NEW.part_id AND warehouse_id = NEW.warehouse_id;

    -- Retrieve remaining balance
    SELECT quantity_on_hand INTO new_balance
    FROM inventory
    WHERE part_id = NEW.part_id AND warehouse_id = NEW.warehouse_id;

    -- Retrieve invoice number
    SELECT invoice_number INTO invoice_ref
    FROM sales_orders
    WHERE order_id = NEW.order_id;

    -- Write audit log entry into stock_movements
    INSERT INTO stock_movements (
        part_id, warehouse_id, movement_type, 
        quantity_changed, balance_after_movement, 
        reference_id, notes
    ) VALUES (
        NEW.part_id, NEW.warehouse_id, 'SALE_DISPATCH',
        -NEW.quantity, new_balance,
        invoice_ref, CONCAT('Dispatched on Order #', NEW.order_id)
    );

    -- Recalculate parent sales_order totals
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

-- -----------------------------------------------------------------------------
-- 3. TRIGGER: trg_after_sales_item_delete (AFTER DELETE)
-- - Automatically restores inventory if a line item is cancelled/removed.
-- - Logs compensating entry in stock_movements.
-- - Recalculates order grand total.
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_after_sales_item_delete$$
CREATE TRIGGER trg_after_sales_item_delete
AFTER DELETE ON sales_order_items
FOR EACH ROW
BEGIN
    DECLARE new_balance INT;
    DECLARE invoice_ref VARCHAR(30);
    DECLARE order_subtotal DECIMAL(12, 2);
    DECLARE order_tax_rate DECIMAL(4, 2);
    DECLARE order_tax DECIMAL(10, 2);
    DECLARE order_discount DECIMAL(10, 2);

    -- Restock inventory
    UPDATE inventory
    SET quantity_on_hand = quantity_on_hand + OLD.quantity
    WHERE part_id = OLD.part_id AND warehouse_id = OLD.warehouse_id;

    -- Get new balance
    SELECT quantity_on_hand INTO new_balance
    FROM inventory
    WHERE part_id = OLD.part_id AND warehouse_id = OLD.warehouse_id;

    SELECT invoice_number INTO invoice_ref
    FROM sales_orders
    WHERE order_id = OLD.order_id;

    -- Record compensating movement
    INSERT INTO stock_movements (
        part_id, warehouse_id, movement_type, 
        quantity_changed, balance_after_movement, 
        reference_id, notes
    ) VALUES (
        OLD.part_id, OLD.warehouse_id, 'SALE_RETURN',
        OLD.quantity, new_balance,
        invoice_ref, CONCAT('Line item deleted from Order #', OLD.order_id)
    );

    -- Recalculate totals
    SELECT COALESCE(SUM(line_total), 0.00) INTO order_subtotal
    FROM sales_order_items
    WHERE order_id = OLD.order_id;

    SELECT tax_rate_percent, discount_amount INTO order_tax_rate, order_discount
    FROM sales_orders
    WHERE order_id = OLD.order_id;

    SET order_tax = ROUND((order_subtotal - order_discount) * (order_tax_rate / 100.0), 2);

    UPDATE sales_orders
    SET 
        subtotal = order_subtotal,
        tax_amount = order_tax,
        grand_total = (order_subtotal - order_discount) + order_tax
    WHERE order_id = OLD.order_id;
END$$

-- -----------------------------------------------------------------------------
-- 4. TRIGGER: trg_after_po_item_receive (AFTER UPDATE)
-- - Increases inventory stock when goods are received from supplier PO.
-- - Automatically timestamps last_restocked_at.
-- - Logs audit entry in stock_movements.
-- -----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_after_po_item_receive$$
CREATE TRIGGER trg_after_po_item_receive
AFTER UPDATE ON purchase_order_items
FOR EACH ROW
BEGIN
    DECLARE diff_received INT DEFAULT 0;
    DECLARE po_wh_id INT;
    DECLARE po_ref VARCHAR(30);
    DECLARE new_balance INT;

    SET diff_received = NEW.quantity_received - OLD.quantity_received;

    -- Only execute if incoming goods were actually received
    IF diff_received > 0 THEN
        SELECT warehouse_id, po_number INTO po_wh_id, po_ref
        FROM purchase_orders
        WHERE po_id = NEW.po_id;

        -- Update or insert into inventory
        INSERT INTO inventory (part_id, warehouse_id, quantity_on_hand, last_restocked_at)
        VALUES (NEW.part_id, po_wh_id, diff_received, NOW())
        ON DUPLICATE KEY UPDATE
            quantity_on_hand = quantity_on_hand + diff_received,
            last_restocked_at = NOW();

        -- Query updated balance
        SELECT quantity_on_hand INTO new_balance
        FROM inventory
        WHERE part_id = NEW.part_id AND warehouse_id = po_wh_id;

        -- Log in audit ledger
        INSERT INTO stock_movements (
            part_id, warehouse_id, movement_type, 
            quantity_changed, balance_after_movement, 
            reference_id, notes
        ) VALUES (
            NEW.part_id, po_wh_id, 'PURCHASE_RECEIPT',
            diff_received, new_balance,
            po_ref, CONCAT('Received from PO #', NEW.po_id)
        );
    END IF;
END$$

DELIMITER ;
