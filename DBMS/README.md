# Vehicle Spare Parts and Inventory Management System (VSP-IMS)
### Production-Grade Relational Database Management System (DBMS) Project
**Target RDBMS**: MySQL 8.0+ / MariaDB 10.5+ | **Engine**: InnoDB | **Charset**: `utf8mb4`

---

## 📌 1. Project Overview & Objectives

Modern automotive workshops, multi-brand service centers, and spare parts distributors handle thousands of unique Stock Keeping Units (SKUs). Managing vehicle spare parts presents distinct challenges compared to standard retail:
1. **Complex Fitment Matrix (Part Compatibility)**: A single brake pad or spark plug fits specific vehicle makes, models, model years, and engine displacements.
2. **Multi-Location Inventory**: Parts are distributed across central hubs, regional logistics depots, and retail counter bins.
3. **Automated Stock Integrity**: Inventory levels must decrement automatically upon dispatch and replenish upon purchase order reception, with strict prevention of negative stock.
4. **Regulatory Audit Trail**: Every stock movement (sales, purchases, returns, transfers) must maintain an immutable ledger.

This DBMS project provides a complete, 3NF/BCNF compliant relational database solution with **automated triggers, stored procedures, business views, realistic sample data, and analytical queries**.

---

## 🗂️ 2. Repository Structure

```
DBMS/
│
├── README.md                                  # Complete Project Manual, Guide & Viva QA
├── run_all.sql                                # CLI runner script (executes all scripts in order)
│
├── schema/
│   ├── 01_database_and_tables.sql             # DDL: Tables, Foreign Keys, CHECK constraints, Indexes
│   ├── 02_views.sql                           # DDL: Reporting, Fitment Search & Stock Views
│   ├── 03_triggers.sql                        # DDL: Stock auto-deduction, negative stock prevention & auditing
│   ├── 04_stored_procedures.sql               # DDL: Stored procedures, functions, transactions
│   └── consolidated_database_setup.sql        # All-in-one file (One-click import for phpMyAdmin / Workbench)
│
├── data/
│   └── 05_sample_data.sql                     # DML: Realistic seed data (Parts, Vehicles, POs, Invoices)
│
├── queries/
│   └── 06_analytical_queries.sql              # 10 Complex Analytical & Business Intelligence Queries
│
└── docs/
    ├── ER_DIAGRAM.md                          # Full Entity-Relationship (ER) Diagram & Cardinality
    └── DATA_DICTIONARY.md                     # Complete Data Dictionary & Normalization Proofs
```

---

## 📊 3. Database Architecture & Entity Summary

The database consists of **14 interconnected relational tables**:

| # | Entity / Table | Purpose & Description | Key Relationships |
|---|---|---|---|
| 1 | `categories` | Hierarchical vehicle systems (Engine, Braking, Electrical) | Self-referencing parent category |
| 2 | `brands` | Manufacturers (Bosch, Brembo, Denso, NGK, OEM) | 1:N with `parts` |
| 3 | `parts` | Master spare parts catalog (Part #, pricing, thresholds) | N:1 with `categories`, `brands` |
| 4 | `vehicles` | Vehicle models (Make, Model, Year Range, Fuel, Engine) | Reference table |
| 5 | `part_compatibility` | Many-to-Many fitment matrix linking parts to vehicles | Junction between `parts` & `vehicles` |
| 6 | `warehouses` | Storage facilities and regional distribution centers | 1:N with `inventory` |
| 7 | `inventory` | Real-time stock levels with aisle, shelf, and bin tracking | Composite link: `parts` $\times$ `warehouses` |
| 8 | `suppliers` | Verified suppliers and distributors with ratings | 1:N with `purchase_orders` |
| 9 | `purchase_orders` | Procurement orders placed with auto parts suppliers | N:1 with `suppliers`, `warehouses` |
| 10 | `purchase_order_items` | Line items with unit cost and quantities received | N:1 with `purchase_orders`, `parts` |
| 11 | `customers` | Retail motorists, repair garages, and corporate fleets | 1:N with `sales_orders` |
| 12 | `sales_orders` | Invoices with subtotal, discount, GST tax, payment status | N:1 with `customers` |
| 13 | `sales_order_items` | Individual line items dispatched from specific warehouses | N:1 with `sales_orders`, `parts`, `warehouses` |
| 14 | `stock_movements` | Immutable audit ledger tracking every stock delta | Audit trail for `parts` & `warehouses` |

---

## ⚙️ 4. Key DBMS Features Implemented

### A. Automated Triggers (`03_triggers.sql`)
1. **`trg_validate_and_calc_sales_item` (BEFORE INSERT)**:
   - Validates that the requested quantity exists in the designated warehouse.
   - Raises a custom SQL exception (`SIGNAL SQLSTATE '45000'`) if inventory is insufficient.
   - Automatically computes `line_total = (quantity * unit_price) - discount`.
2. **`trg_after_sales_item_insert` (AFTER INSERT)**:
   - Atomically deducts `quantity_on_hand` in the target warehouse.
   - Appends an audit record to `stock_movements` (`SALE_DISPATCH`).
   - Automatically recalculates parent `sales_orders` subtotal, GST tax (18%), and grand total.
3. **`trg_after_sales_item_delete` (AFTER DELETE)**:
   - Restores stock back to the warehouse if an item is cancelled or removed.
   - Logs compensating movement (`SALE_RETURN`).
   - Recalculates order grand total.
4. **`trg_after_po_item_receive` (AFTER UPDATE)**:
   - Increments inventory stock whenever `quantity_received` increases on a purchase order.
   - Updates `last_restocked_at` timestamp.
   - Logs audit record (`PURCHASE_RECEIPT`).

### B. Stored Procedures & Functions (`04_stored_procedures.sql`)
- **`fn_calculate_reorder_urgency(current, min)`**: Evaluates stock urgency (`CRITICAL_OUT_OF_STOCK`, `HIGH_PRIORITY`, `MODERATE_REORDER`, `ADEQUATE`).
- **`sp_create_sales_order(customer_id, payment_method, ...)`**: Generates unique invoice number, applies customer standing discount, and initializes order.
- **`sp_add_order_item(order_id, part_id, warehouse_id, qty)`**: Validates and inserts line item with customer discounts.
- **`sp_transfer_warehouse_stock(part_id, src_wh, dest_wh, qty, ref)`**: Safe transaction-wrapped inter-warehouse stock transfer with rollback on insufficient balance.
- **`sp_find_compatible_parts(make, model, year, category)`**: Fast vehicle fitment search.
- **`sp_monthly_financial_report(year, month)`**: Computes revenue, COGS, tax collected, and net profit.

### C. Database Views (`02_views.sql`)
- **`vw_parts_catalog`**: Unified catalog with margins, markup percentage, and total network stock.
- **`vw_vehicle_compatibility_search`**: Search-ready view joining vehicle specifications with parts.
- **`vw_low_stock_alerts`**: Procurement manager alert view identifying items at or below reorder threshold.
- **`vw_warehouse_valuation`**: Total capital invested per warehouse (cost value vs retail value).
- **`vw_sales_summary_by_category`**: Financial performance grouped by vehicle system.
- **`vw_customer_purchase_history`**: Customer Lifetime Value (CLV) and order frequency.

---

## 🚀 5. How to Setup and Run

### A. Run the Interactive Web Server (Instant UI & Database)
A complete interactive web application with dashboard, fitment finder, inventory tracking, and billing is included in the project.

#### Option 1: Double-Click Launcher (Easiest)
Simply double-click:
`start_server.bat`

This will:
1. Detect Python 3 on your machine.
2. Initialize and seed the database (`vehicle_inventory.db`).
3. Automatically launch your default web browser to:
   **`http://127.0.0.1:5000`**

#### Option 2: PowerShell
```powershell
.\start_server.ps1
```

#### Option 3: Python Command
```bash
python app.py
```

---

### B. Setup Pure SQL Database in MySQL / MariaDB

#### Method 1: One-Click Import in phpMyAdmin / XAMPP
1. Open **phpMyAdmin** (`http://localhost/phpmyadmin`).
2. Click the **Import** tab on the top menu.
3. Click **Choose File** and select:
   `DBMS/schema/consolidated_database_setup.sql`
4. Click **Go** / **Import**. The entire database, tables, views, triggers, and sample data will be created!

#### Method 2: MySQL Workbench
1. Open **MySQL Workbench** and connect to your local MySQL instance.
2. Go to **File** $\rightarrow$ **Open SQL Script...**
3. Select `DBMS/schema/consolidated_database_setup.sql`.
4. Click the **Execute (Lightning Bolt ⚡)** button.
5. In the left Navigator pane, right-click and click **Refresh All**. You will see `vehicle_inventory_db`.

#### Method 3: MySQL Command Line (CLI)
Open terminal / command prompt in this `DBMS` directory:
```bash
mysql -u root -p
```
Inside the MySQL shell:
```sql
SOURCE run_all.sql;
```

---

## 🔍 6. Sample Verification Queries

Once installed, test the system with these commands:

```sql
USE vehicle_inventory_db;

-- 1. Check all low-stock items needing urgent replenishment:
SELECT * FROM vw_low_stock_alerts;

-- 2. Find all parts compatible with a 2018 Toyota Corolla:
CALL sp_find_compatible_parts('Toyota', 'Corolla', 2018, NULL);

-- 3. Check warehouse total asset valuation:
SELECT * FROM vw_warehouse_valuation;

-- 4. Check category sales and profit margins:
SELECT * FROM vw_sales_summary_by_category;

-- 5. View complete audit history of stock changes:
SELECT * FROM stock_movements ORDER BY created_at DESC;
```

---

## 🎓 7. Academic Viva / Oral Examination Questions & Answers

**Q1: Why is Part Compatibility modeled as a Many-to-Many ($M:N$) relationship?**
> *Answer*: A single spare part (e.g., NGK Spark Plug #944) fits multiple different car models (Corolla, Civic, Swift). Likewise, a single vehicle requires hundreds of different spare parts. An $M:N$ relationship resolved via the junction table `part_compatibility` eliminates data duplication and avoids multi-valued attributes, ensuring 1NF and 3NF.

**Q2: How does the system prevent negative inventory during high concurrent sales?**
> *Answer*: The `trg_validate_and_calc_sales_item` trigger performs an automated BEFORE INSERT stock check. If the requested quantity exceeds `quantity_on_hand` in the target warehouse, the database raises `SIGNAL SQLSTATE '45000'`, aborting the insert. Additionally, the inter-warehouse transfer procedure `sp_transfer_warehouse_stock` uses `FOR UPDATE` row-level locks within an explicit `START TRANSACTION ... COMMIT / ROLLBACK` block.

**Q3: What normal form does this database satisfy?**
> *Answer*: The entire database satisfies **Third Normal Form (3NF)** and **Boyce-Codd Normal Form (BCNF)**. All attributes are atomic (1NF), all non-key columns depend on the entire primary key with zero partial dependencies (2NF), and all transitive dependencies are eliminated (e.g., customer details reside in `customers`, warehouse metadata in `warehouses`).

**Q4: Why maintain a separate `stock_movements` ledger when `inventory` already stores `quantity_on_hand`?**
> *Answer*: `inventory.quantity_on_hand` stores only the current state (a snapshot). In accounting and inventory management, auditing requires knowing *why*, *when*, and *by what document* stock changed (sales invoice, supplier delivery, warehouse transfer, or scrap). The immutable `stock_movements` table provides complete regulatory and financial auditability.
