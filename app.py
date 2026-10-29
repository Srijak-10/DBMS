"""
Flask Web Application for Vehicle Spare Parts & Inventory Management System.
Features:
- Executive Dashboard with KPI metrics and low stock alerts
- Parts Catalog with category & brand filtering
- Interactive Vehicle Fitment / Compatibility Finder
- Multi-Warehouse Stock Tracking & Restocking
- Point-of-Sale / Order Billing with real-time stock deduction and tax calculation
- Immutable Audit Ledger (Stock Movements)
"""

import os
import random
from datetime import datetime
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
import database

app = Flask(__name__)
app.secret_key = 'vsp-ims-secret-key-2026'

# Initialize Database Schema & Data on startup
database.init_database()

# -----------------------------------------------------------------------------
# Route: Dashboard
# -----------------------------------------------------------------------------
@app.route('/')
def dashboard():
    conn = database.get_connection()
    cursor = conn.cursor()

    # KPI Statistics
    cursor.execute("SELECT COUNT(*) FROM parts WHERE is_active = 1")
    total_parts = cursor.fetchone()[0]

    cursor.execute("SELECT COALESCE(SUM(quantity_on_hand), 0) FROM inventory")
    total_units_stock = cursor.fetchone()[0]

    cursor.execute("""
        SELECT COUNT(*) FROM inventory i
        JOIN parts p ON i.part_id = p.part_id
        WHERE i.quantity_on_hand <= p.min_stock_level
    """)
    low_stock_count = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*), COALESCE(SUM(grand_total), 0.0) FROM sales_orders WHERE order_status != 'CANCELLED'")
    orders_row = cursor.fetchone()
    total_orders = orders_row[0]
    total_revenue = round(orders_row[1], 2)

    # Low Stock Items
    cursor.execute("""
        SELECT 
            p.part_id, p.part_number, p.part_name, c.category_name, b.brand_name,
            w.warehouse_code, i.quantity_on_hand, p.min_stock_level,
            (p.max_stock_level - i.quantity_on_hand) AS reorder_qty,
            p.cost_price, i.aisle, i.shelf, i.bin
        FROM inventory i
        JOIN parts p ON i.part_id = p.part_id
        JOIN categories c ON p.category_id = c.category_id
        JOIN brands b ON p.brand_id = b.brand_id
        JOIN warehouses w ON i.warehouse_id = w.warehouse_id
        WHERE i.quantity_on_hand <= p.min_stock_level
        ORDER BY i.quantity_on_hand ASC
        LIMIT 6
    """)
    low_stock_items = cursor.fetchall()

    # Recent Orders
    cursor.execute("""
        SELECT so.order_id, so.invoice_number, c.full_name, c.customer_type,
               so.order_date, so.grand_total, so.payment_status, so.order_status
        FROM sales_orders so
        JOIN customers c ON so.customer_id = c.customer_id
        ORDER BY so.order_date DESC
        LIMIT 5
    """)
    recent_orders = cursor.fetchall()

    conn.close()
    return render_template(
        'index.html',
        total_parts=total_parts,
        total_units_stock=total_units_stock,
        low_stock_count=low_stock_count,
        total_orders=total_orders,
        total_revenue=total_revenue,
        low_stock_items=low_stock_items,
        recent_orders=recent_orders
    )

# -----------------------------------------------------------------------------
# Route: Parts Catalog
# -----------------------------------------------------------------------------
@app.route('/parts', methods=['GET', 'POST'])
def parts_catalog():
    conn = database.get_connection()
    cursor = conn.cursor()

    if request.method == 'POST':
        part_number = request.form.get('part_number', '').strip()
        part_name = request.form.get('part_name', '').strip()
        category_id = request.form.get('category_id')
        brand_id = request.form.get('brand_id')
        cost_price = float(request.form.get('cost_price', 0))
        selling_price = float(request.form.get('selling_price', 0))
        min_stock = int(request.form.get('min_stock_level', 5))
        max_stock = int(request.form.get('max_stock_level', 50))
        unit = request.form.get('unit_of_measure', 'PIECE')
        warranty = int(request.form.get('warranty_months', 12))

        try:
            cursor.execute("""
                INSERT INTO parts (part_number, part_name, category_id, brand_id, cost_price, selling_price, min_stock_level, max_stock_level, unit_of_measure, warranty_months)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (part_number, part_name, category_id, brand_id, cost_price, selling_price, min_stock, max_stock, unit, warranty))
            new_id = cursor.lastrowid
            # Initialize zero stock slot in warehouse 1
            cursor.execute("INSERT INTO inventory (part_id, warehouse_id, quantity_on_hand) VALUES (?, 1, 0)", (new_id,))
            conn.commit()
            flash(f"Spare part '{part_name}' ({part_number}) created successfully!", 'success')
        except Exception as e:
            flash(f"Error adding part: {str(e)}", 'danger')
        return redirect(url_for('parts_catalog'))

    # Filters
    search_q = request.args.get('q', '').strip()
    cat_filter = request.args.get('category', '')
    brand_filter = request.args.get('brand', '')

    query = """
        SELECT 
            p.part_id, p.part_number, p.part_name, c.category_name, b.brand_name,
            p.unit_of_measure, p.cost_price, p.selling_price,
            ROUND(p.selling_price - p.cost_price, 2) AS profit,
            COALESCE(SUM(i.quantity_on_hand), 0) AS total_stock,
            p.min_stock_level, p.warranty_months, p.is_active
        FROM parts p
        JOIN categories c ON p.category_id = c.category_id
        JOIN brands b ON p.brand_id = b.brand_id
        LEFT JOIN inventory i ON p.part_id = i.part_id
        WHERE 1=1
    """
    params = []

    if search_q:
        query += " AND (p.part_number LIKE ? OR p.part_name LIKE ?)"
        params.extend([f"%{search_q}%", f"%{search_q}%"])
    if cat_filter:
        query += " AND p.category_id = ?"
        params.append(cat_filter)
    if brand_filter:
        query += " AND p.brand_id = ?"
        params.append(brand_filter)

    query += " GROUP BY p.part_id ORDER BY p.part_id DESC"
    cursor.execute(query, params)
    parts_list = cursor.fetchall()

    cursor.execute("SELECT category_id, category_name FROM categories ORDER BY category_name")
    categories = cursor.fetchall()

    cursor.execute("SELECT brand_id, brand_name FROM brands ORDER BY brand_name")
    brands = cursor.fetchall()

    conn.close()
    return render_template('parts.html', parts=parts_list, categories=categories, brands=brands, search_q=search_q, cat_filter=cat_filter, brand_filter=brand_filter)

# -----------------------------------------------------------------------------
# Route: Vehicle Compatibility Search
# -----------------------------------------------------------------------------
@app.route('/compatibility')
def compatibility():
    conn = database.get_connection()
    cursor = conn.cursor()

    selected_make = request.args.get('make', '').strip()
    selected_model = request.args.get('model', '').strip()
    selected_year = request.args.get('year', '').strip()

    # Get distinct vehicle makes for filter
    cursor.execute("SELECT DISTINCT make FROM vehicles ORDER BY make")
    makes = [row[0] for row in cursor.fetchall()]

    models = []
    if selected_make:
        cursor.execute("SELECT DISTINCT model FROM vehicles WHERE make = ? ORDER BY model", (selected_make,))
        models = [row[0] for row in cursor.fetchall()]

    results = []
    if selected_make and selected_model:
        query = """
            SELECT 
                v.make, v.model, v.year_start, v.year_end, v.engine_displacement, v.fuel_type,
                p.part_number, p.part_name, c.category_name, b.brand_name,
                p.selling_price, pc.position_notes,
                COALESCE(SUM(i.quantity_on_hand), 0) AS total_stock
            FROM vehicles v
            JOIN part_compatibility pc ON v.vehicle_id = pc.vehicle_id
            JOIN parts p ON pc.part_id = p.part_id
            JOIN categories c ON p.category_id = c.category_id
            JOIN brands b ON p.brand_id = b.brand_id
            LEFT JOIN inventory i ON p.part_id = i.part_id
            WHERE v.make = ? AND v.model = ?
        """
        params = [selected_make, selected_model]
        if selected_year and selected_year.isdigit():
            query += " AND (? BETWEEN v.year_start AND v.year_end)"
            params.append(int(selected_year))

        query += " GROUP BY p.part_id, pc.compatibility_id ORDER BY c.category_name, p.selling_price"
        cursor.execute(query, params)
        results = cursor.fetchall()

    conn.close()
    return render_template('compatibility.html', makes=makes, models=models, selected_make=selected_make, selected_model=selected_model, selected_year=selected_year, results=results)

# -----------------------------------------------------------------------------
# Route: Inventory & Warehouses
# -----------------------------------------------------------------------------
@app.route('/inventory')
def inventory_view():
    conn = database.get_connection()
    cursor = conn.cursor()

    wh_filter = request.args.get('warehouse', '')

    query = """
        SELECT 
            i.inventory_id, i.part_id, p.part_number, p.part_name, c.category_name, b.brand_name,
            w.warehouse_id, w.warehouse_code, w.warehouse_name,
            i.aisle, i.shelf, i.bin, i.quantity_on_hand, p.min_stock_level, p.max_stock_level,
            p.cost_price, p.selling_price, i.last_restocked_at
        FROM inventory i
        JOIN parts p ON i.part_id = p.part_id
        JOIN categories c ON p.category_id = c.category_id
        JOIN brands b ON p.brand_id = b.brand_id
        JOIN warehouses w ON i.warehouse_id = w.warehouse_id
        WHERE 1=1
    """
    params = []
    if wh_filter:
        query += " AND i.warehouse_id = ?"
        params.append(wh_filter)

    query += " ORDER BY w.warehouse_id, p.part_name"
    cursor.execute(query, params)
    inventory_items = cursor.fetchall()

    cursor.execute("SELECT warehouse_id, warehouse_code, warehouse_name, city FROM warehouses WHERE is_active = 1")
    warehouses = cursor.fetchall()

    conn.close()
    return render_template('inventory.html', inventory=inventory_items, warehouses=warehouses, wh_filter=wh_filter)

# -----------------------------------------------------------------------------
# Route: Restock / Adjust Stock
# -----------------------------------------------------------------------------
@app.route('/inventory/adjust', methods=['POST'])
def adjust_inventory():
    conn = database.get_connection()
    cursor = conn.cursor()

    inventory_id = request.form.get('inventory_id')
    quantity_to_add = int(request.form.get('quantity_to_add', 0))
    reason = request.form.get('reason', 'Stock Replenishment').strip()

    if quantity_to_add <= 0:
        flash("Quantity added must be greater than zero.", "danger")
        return redirect(url_for('inventory_view'))

    try:
        # Get part_id and warehouse_id
        cursor.execute("SELECT part_id, warehouse_id, quantity_on_hand FROM inventory WHERE inventory_id = ?", (inventory_id,))
        row = cursor.fetchone()
        if not row:
            flash("Inventory item not found.", "danger")
            return redirect(url_for('inventory_view'))

        part_id, warehouse_id, current_qty = row
        new_balance = current_qty + quantity_to_add

        # Update stock
        cursor.execute("""
            UPDATE inventory 
            SET quantity_on_hand = ?, last_restocked_at = CURRENT_TIMESTAMP 
            WHERE inventory_id = ?
        """, (new_balance, inventory_id))

        # Log in audit ledger
        cursor.execute("""
            INSERT INTO stock_movements (part_id, warehouse_id, movement_type, quantity_changed, balance_after_movement, reference_id, notes)
            VALUES (?, ?, 'PURCHASE_RECEIPT', ?, ?, 'RESTOCK-MANUAL', ?)
        """, (part_id, warehouse_id, quantity_to_add, new_balance, reason))

        conn.commit()
        flash(f"Successfully added +{quantity_to_add} units to inventory!", "success")
    except Exception as e:
        flash(f"Error adjusting stock: {str(e)}", "danger")

    conn.close()
    return redirect(url_for('inventory_view'))

# -----------------------------------------------------------------------------
# Route: Billing / POS (Create Sales Order)
# -----------------------------------------------------------------------------
@app.route('/billing', methods=['GET', 'POST'])
def billing():
    conn = database.get_connection()
    cursor = conn.cursor()

    if request.method == 'POST':
        customer_id = request.form.get('customer_id')
        warehouse_id = request.form.get('warehouse_id')
        part_id = request.form.get('part_id')
        quantity = int(request.form.get('quantity', 1))
        payment_method = request.form.get('payment_method', 'CASH')
        remarks = request.form.get('remarks', 'Counter Sale').strip()

        try:
            # 1. Check stock in warehouse
            cursor.execute("SELECT quantity_on_hand FROM inventory WHERE part_id = ? AND warehouse_id = ?", (part_id, warehouse_id))
            inv_row = cursor.fetchone()
            current_stock = inv_row[0] if inv_row else 0

            if current_stock < quantity:
                flash(f"Transaction Rejected: Insufficient inventory! Available in this warehouse: {current_stock} units.", "danger")
                conn.close()
                return redirect(url_for('billing'))

            # 2. Get customer discount & part selling price
            cursor.execute("SELECT discount_percentage FROM customers WHERE customer_id = ?", (customer_id,))
            cust_discount = cursor.fetchone()[0] or 0.0

            cursor.execute("SELECT selling_price, part_name, part_number FROM parts WHERE part_id = ?", (part_id,))
            part_row = cursor.fetchone()
            unit_price = part_row[0]

            # Computations
            raw_total = unit_price * quantity
            discount_amount = round(raw_total * (cust_discount / 100.0), 2)
            subtotal = raw_total - discount_amount
            tax_amount = round(subtotal * 0.18, 2)  # 18% GST
            grand_total = subtotal + tax_amount

            # 3. Create invoice
            inv_number = f"INV-{datetime.now().strftime('%Y%m%d')}-{random.randint(1000, 9999)}"
            cursor.execute("""
                INSERT INTO sales_orders (invoice_number, customer_id, order_date, subtotal, discount_amount, tax_rate_percent, tax_amount, grand_total, payment_status, payment_method, order_status, remarks)
                VALUES (?, ?, CURRENT_TIMESTAMP, ?, ?, 18.0, ?, ?, 'PAID', ?, 'CONFIRMED', ?)
            """, (inv_number, customer_id, raw_total, discount_amount, tax_amount, grand_total, payment_method, remarks))
            order_id = cursor.lastrowid

            # 4. Insert order item
            cursor.execute("""
                INSERT INTO sales_order_items (order_id, part_id, warehouse_id, quantity, unit_price, discount_applied, line_total)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (order_id, part_id, warehouse_id, quantity, unit_price, discount_amount, subtotal))

            # 5. Deduct inventory
            new_stock = current_stock - quantity
            cursor.execute("UPDATE inventory SET quantity_on_hand = ? WHERE part_id = ? AND warehouse_id = ?", (new_stock, part_id, warehouse_id))

            # 6. Audit Trail
            cursor.execute("""
                INSERT INTO stock_movements (part_id, warehouse_id, movement_type, quantity_changed, balance_after_movement, reference_id, notes)
                VALUES (?, ?, 'SALE_DISPATCH', ?, ?, ?, ?)
            """, (part_id, warehouse_id, -quantity, new_stock, inv_number, f"Order #{order_id} Billing"))

            conn.commit()
            flash(f"Invoice {inv_number} generated successfully! Grand Total: ${grand_total:.2f}. Stock updated.", "success")
            conn.close()
            return redirect(url_for('orders_list'))
        except Exception as e:
            flash(f"Error creating invoice: {str(e)}", "danger")

    # Load Customers, Warehouses, and Parts with Available Stock
    cursor.execute("SELECT customer_id, full_name, customer_type, discount_percentage FROM customers ORDER BY full_name")
    customers = cursor.fetchall()

    cursor.execute("SELECT warehouse_id, warehouse_code, warehouse_name FROM warehouses WHERE is_active = 1")
    warehouses = cursor.fetchall()

    cursor.execute("""
        SELECT p.part_id, p.part_number, p.part_name, p.selling_price, COALESCE(SUM(i.quantity_on_hand), 0) AS total_stock
        FROM parts p
        LEFT JOIN inventory i ON p.part_id = i.part_id
        WHERE p.is_active = 1
        GROUP BY p.part_id
        HAVING total_stock > 0
        ORDER BY p.part_name
    """)
    parts = cursor.fetchall()

    conn.close()
    return render_template('billing.html', customers=customers, warehouses=warehouses, parts=parts)

# -----------------------------------------------------------------------------
# Route: Orders & Invoices List
# -----------------------------------------------------------------------------
@app.route('/orders')
def orders_list():
    conn = database.get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT 
            so.order_id, so.invoice_number, c.full_name, c.customer_type,
            so.order_date, so.subtotal, so.discount_amount, so.tax_amount,
            so.grand_total, so.payment_status, so.payment_method, so.order_status
        FROM sales_orders so
        JOIN customers c ON so.customer_id = c.customer_id
        ORDER BY so.order_id DESC
    """)
    orders = cursor.fetchall()

    conn.close()
    return render_template('orders.html', orders=orders)

# -----------------------------------------------------------------------------
# Route: Stock Movement Audit Log
# -----------------------------------------------------------------------------
@app.route('/audit')
def audit_ledger():
    conn = database.get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT 
            sm.movement_id, sm.created_at, p.part_number, p.part_name,
            w.warehouse_code, sm.movement_type, sm.quantity_changed,
            sm.balance_after_movement, sm.reference_id, sm.notes
        FROM stock_movements sm
        JOIN parts p ON sm.part_id = p.part_id
        JOIN warehouses w ON sm.warehouse_id = w.warehouse_id
        ORDER BY sm.movement_id DESC
        LIMIT 100
    """)
    movements = cursor.fetchall()

    conn.close()
    return render_template('audit.html', movements=movements)

# -----------------------------------------------------------------------------
# Main entrypoint
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"\n=======================================================")
    print(f"  VEHICLE SPARE PARTS & INVENTORY MANAGEMENT SYSTEM  ")
    print(f"  Server URL: http://127.0.0.1:{port}")
    print(f"=======================================================\n")
    app.run(host='0.0.0.0', port=port, debug=False)
