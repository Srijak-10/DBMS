# Data Dictionary & Relational Normalization
## Vehicle Spare Parts and Inventory Management System (VSP-IMS)

---

## 1. Relational Schema Data Dictionary

### Table: `categories`
| Column Name | Data Type | Nullable | Constraints / Default | Description |
|---|---|---|---|---|
| `category_id` | INT | NO | PRIMARY KEY, AUTO_INCREMENT | Unique category identifier |
| `parent_category_id` | INT | YES | FOREIGN KEY (`categories.category_id`) | Parent category for hierarchy |
| `category_name` | VARCHAR(100) | NO | UNIQUE | Category name (e.g., Braking System) |
| `description` | TEXT | YES | NULL | Overview of parts classified here |
| `created_at` | TIMESTAMP | NO | CURRENT_TIMESTAMP | Record creation timestamp |

---

### Table: `brands`
| Column Name | Data Type | Nullable | Constraints / Default | Description |
|---|---|---|---|---|
| `brand_id` | INT | NO | PRIMARY KEY, AUTO_INCREMENT | Unique brand identifier |
| `brand_name` | VARCHAR(100) | NO | UNIQUE | Brand name (e.g., Bosch, Brembo) |
| `country_of_origin` | VARCHAR(60) | YES | NULL | Country of origin |
| `website` | VARCHAR(255) | YES | NULL | Official manufacturer website |
| `is_oem` | BOOLEAN | NO | DEFAULT FALSE | TRUE if Original Equipment Manufacturer |
| `created_at` | TIMESTAMP | NO | CURRENT_TIMESTAMP | Record creation timestamp |

---

### Table: `parts`
| Column Name | Data Type | Nullable | Constraints / Default | Description |
|---|---|---|---|---|
| `part_id` | INT | NO | PRIMARY KEY, AUTO_INCREMENT | Internal unique part key |
| `part_number` | VARCHAR(50) | NO | UNIQUE | Manufacturer SKU / Part Number |
| `part_name` | VARCHAR(150) | NO | NOT NULL | Human-readable part title |
| `category_id` | INT | NO | FOREIGN KEY (`categories.category_id`) | Category association |
| `brand_id` | INT | NO | FOREIGN KEY (`brands.brand_id`) | Manufacturer association |
| `description` | TEXT | YES | NULL | Technical specifications |
| `unit_of_measure` | VARCHAR(20) | NO | DEFAULT 'PIECE' | SET, PIECE, CAN, LITER, PAIR |
| `cost_price` | DECIMAL(10,2) | NO | CHECK (cost_price >= 0.00) | Supplier procurement price |
| `selling_price` | DECIMAL(10,2) | NO | CHECK (selling_price >= cost_price) | Retail / counter sale price |
| `min_stock_level` | INT | NO | DEFAULT 5, CHECK (>= 0) | Reorder threshold limit |
| `max_stock_level` | INT | NO | DEFAULT 100, CHECK (>= min_stock) | Overstock upper threshold |
| `warranty_months` | INT | YES | DEFAULT 12, CHECK (>= 0) | Manufacturer warranty in months |
| `is_active` | BOOLEAN | NO | DEFAULT TRUE | Soft delete / active flag |
| `created_at` | TIMESTAMP | NO | CURRENT_TIMESTAMP | Creation timestamp |
| `updated_at` | TIMESTAMP | NO | CURRENT_TIMESTAMP ON UPDATE | Last modification timestamp |

---

### Table: `vehicles`
| Column Name | Data Type | Nullable | Constraints / Default | Description |
|---|---|---|---|---|
| `vehicle_id` | INT | NO | PRIMARY KEY, AUTO_INCREMENT | Vehicle specification identifier |
| `make` | VARCHAR(50) | NO | NOT NULL | Brand (Toyota, Honda, BMW, Ford) |
| `model` | VARCHAR(70) | NO | NOT NULL | Model (Corolla, Civic, Swift) |
| `year_start` | INT | NO | CHECK (1950 - 2100) | Production start model year |
| `year_end` | INT | NO | CHECK (year_end >= year_start) | Production end model year |
| `engine_displacement` | VARCHAR(30) | YES | NULL | Engine code / volume (e.g. 1.8L) |
| `fuel_type` | ENUM | NO | DEFAULT 'PETROL' | PETROL, DIESEL, HYBRID, ELECTRIC, CNG |
| `transmission` | ENUM | NO | DEFAULT 'AUTOMATIC' | MANUAL, AUTOMATIC, CVT, DUAL_CLUTCH |
| `created_at` | TIMESTAMP | NO | CURRENT_TIMESTAMP | Creation timestamp |

---

### Table: `part_compatibility`
| Column Name | Data Type | Nullable | Constraints / Default | Description |
|---|---|---|---|---|
| `compatibility_id`| INT | NO | PRIMARY KEY, AUTO_INCREMENT | Fitment record ID |
| `part_id` | INT | NO | FOREIGN KEY (`parts.part_id`) | Part reference |
| `vehicle_id` | INT | NO | FOREIGN KEY (`vehicles.vehicle_id`) | Vehicle reference |
| `position_notes` | VARCHAR(100) | YES | NULL | Axle position, trim constraints |
| `created_at` | TIMESTAMP | NO | CURRENT_TIMESTAMP | Creation timestamp |

---

### Table: `warehouses`
| Column Name | Data Type | Nullable | Constraints / Default | Description |
|---|---|---|---|---|
| `warehouse_id` | INT | NO | PRIMARY KEY, AUTO_INCREMENT | Warehouse facility ID |
| `warehouse_code` | VARCHAR(20) | NO | UNIQUE | Code (e.g., WH-DEL-01) |
| `warehouse_name` | VARCHAR(100) | NO | NOT NULL | Descriptive facility name |
| `contact_phone` | VARCHAR(25) | YES | NULL | Facility phone number |
| `contact_email` | VARCHAR(100) | YES | NULL | Facility email address |
| `city` | VARCHAR(60) | NO | NOT NULL | Operating city |
| `state` | VARCHAR(60) | YES | NULL | Operating state/province |
| `country` | VARCHAR(60) | NO | DEFAULT 'India' | Country location |
| `address_line` | TEXT | YES | NULL | Physical address |
| `is_active` | BOOLEAN | NO | DEFAULT TRUE | Operational status |
| `created_at` | TIMESTAMP | NO | CURRENT_TIMESTAMP | Creation timestamp |

---

### Table: `inventory`
| Column Name | Data Type | Nullable | Constraints / Default | Description |
|---|---|---|---|---|
| `inventory_id` | INT | NO | PRIMARY KEY, AUTO_INCREMENT | Inventory bin record ID |
| `part_id` | INT | NO | FOREIGN KEY (`parts.part_id`) | Part reference |
| `warehouse_id` | INT | NO | FOREIGN KEY (`warehouses.warehouse_id`) | Facility location |
| `aisle` | VARCHAR(15) | NO | DEFAULT 'A1' | Warehouse aisle identifier |
| `shelf` | VARCHAR(15) | NO | DEFAULT 'S1' | Shelf tier identifier |
| `bin` | VARCHAR(15) | NO | DEFAULT 'B1' | Exact bin compartment |
| `quantity_on_hand`| INT | NO | DEFAULT 0, CHECK (>= 0) | Physical stock available |
| `quantity_reserved`| INT | NO | DEFAULT 0, CHECK (>= 0) | Stock reserved for pending orders |
| `last_restocked_at`| TIMESTAMP | YES | NULL | Timestamp of last replenishment |
| `updated_at` | TIMESTAMP | NO | CURRENT_TIMESTAMP ON UPDATE | Last modification timestamp |

---

### Table: `suppliers`
| Column Name | Data Type | Nullable | Constraints / Default | Description |
|---|---|---|---|---|
| `supplier_id` | INT | NO | PRIMARY KEY, AUTO_INCREMENT | Supplier key |
| `company_name` | VARCHAR(120) | NO | UNIQUE | Registered business name |
| `contact_name` | VARCHAR(80) | YES | NULL | Primary contact person |
| `phone` | VARCHAR(25) | NO | NOT NULL | Phone contact |
| `email` | VARCHAR(100) | NO | UNIQUE | Email address |
| `tax_registration_no`| VARCHAR(50)| YES | NULL | GSTIN / Tax Identification |
| `address` | TEXT | YES | NULL | Registered office address |
| `city` | VARCHAR(60) | YES | NULL | City |
| `country` | VARCHAR(60) | NO | DEFAULT 'India' | Country |
| `payment_terms` | VARCHAR(50) | NO | DEFAULT 'Net 30' | Payment terms (Net 30, Net 45) |
| `rating` | DECIMAL(2,1) | NO | DEFAULT 4.0, CHECK (1.0 - 5.0) | Supplier performance score |
| `is_active` | BOOLEAN | NO | DEFAULT TRUE | Active vendor status |
| `created_at` | TIMESTAMP | NO | CURRENT_TIMESTAMP | Supplier registration date |

---

### Table: `purchase_orders`
| Column Name | Data Type | Nullable | Constraints / Default | Description |
|---|---|---|---|---|
| `po_id` | INT | NO | PRIMARY KEY, AUTO_INCREMENT | Purchase order ID |
| `po_number` | VARCHAR(30) | NO | UNIQUE | Official PO document number |
| `supplier_id` | INT | NO | FOREIGN KEY (`suppliers.supplier_id`) | Supplier placed with |
| `warehouse_id` | INT | NO | FOREIGN KEY (`warehouses.warehouse_id`)| Delivery destination warehouse |
| `order_date` | DATE | NO | NOT NULL | Placement date |
| `expected_delivery_date` | DATE | YES | NULL | Estimated arrival date |
| `received_date` | DATE | YES | NULL | Actual goods arrival date |
| `total_amount` | DECIMAL(12,2) | NO | DEFAULT 0.00 | Total value of PO |
| `status` | ENUM | NO | DEFAULT 'PENDING' | PENDING, ORDERED, PARTIAL, COMPLETED, CANCELLED |
| `notes` | TEXT | YES | NULL | Special instructions |
| `created_at` | TIMESTAMP | NO | CURRENT_TIMESTAMP | Record creation timestamp |

---

### Table: `purchase_order_items`
| Column Name | Data Type | Nullable | Constraints / Default | Description |
|---|---|---|---|---|
| `po_item_id` | INT | NO | PRIMARY KEY, AUTO_INCREMENT | PO line item ID |
| `po_id` | INT | NO | FOREIGN KEY (`purchase_orders.po_id`) | Parent PO reference |
| `part_id` | INT | NO | FOREIGN KEY (`parts.part_id`) | Part ordered |
| `quantity_ordered` | INT | NO | CHECK (quantity_ordered > 0) | Quantity requested |
| `quantity_received` | INT | NO | DEFAULT 0, CHECK (>= 0) | Quantity received at dock |
| `unit_cost` | DECIMAL(10,2) | NO | CHECK (unit_cost >= 0.00) | Negotiated purchase unit cost |
| `total_line_cost` | DECIMAL(12,2) | NO | GENERATED ALWAYS AS (qty * unit) | Computed line total |

---

### Table: `customers`
| Column Name | Data Type | Nullable | Constraints / Default | Description |
|---|---|---|---|---|
| `customer_id` | INT | NO | PRIMARY KEY, AUTO_INCREMENT | Customer unique ID |
| `customer_type` | ENUM | NO | DEFAULT 'RETAIL' | RETAIL, WORKSHOP, FLEET, WHOLESALE |
| `full_name` | VARCHAR(100) | NO | NOT NULL | Customer / Company contact name |
| `phone` | VARCHAR(25) | NO | UNIQUE | Contact phone number |
| `email` | VARCHAR(100) | YES | NULL | Email address |
| `tax_id` | VARCHAR(50) | YES | NULL | Business Tax / GSTIN ID |
| `address` | TEXT | YES | NULL | Billing / shipping address |
| `city` | VARCHAR(60) | YES | NULL | City |
| `discount_percentage` | DECIMAL(4,2) | NO | DEFAULT 0.00, CHECK (0 - 50%) | Standing commercial discount |
| `created_at` | TIMESTAMP | NO | CURRENT_TIMESTAMP | Registration timestamp |

---

### Table: `sales_orders`
| Column Name | Data Type | Nullable | Constraints / Default | Description |
|---|---|---|---|---|
| `order_id` | INT | NO | PRIMARY KEY, AUTO_INCREMENT | Order ID |
| `invoice_number` | VARCHAR(30) | NO | UNIQUE | Legal tax invoice number |
| `customer_id` | INT | NO | FOREIGN KEY (`customers.customer_id`) | Customer reference |
| `order_date` | TIMESTAMP | NO | DEFAULT CURRENT_TIMESTAMP | Order creation timestamp |
| `subtotal` | DECIMAL(12,2) | NO | DEFAULT 0.00 | Sum of line items |
| `discount_amount`| DECIMAL(10,2) | NO | DEFAULT 0.00 | Total discount granted |
| `tax_rate_percent`| DECIMAL(4,2) | NO | DEFAULT 18.00 | Tax percentage (GST/VAT) |
| `tax_amount` | DECIMAL(10,2) | NO | DEFAULT 0.00 | Calculated tax |
| `grand_total` | DECIMAL(12,2) | NO | DEFAULT 0.00 | Final payable invoice total |
| `payment_status` | ENUM | NO | DEFAULT 'PENDING' | PAID, PENDING, PARTIAL, REFUNDED |
| `payment_method` | ENUM | NO | DEFAULT 'CASH' | CASH, CREDIT_CARD, UPI, BANK_TRANSFER, CHEQUE |
| `order_status` | ENUM | NO | DEFAULT 'CONFIRMED' | CONFIRMED, DISPATCHED, DELIVERED, CANCELLED |
| `remarks` | TEXT | YES | NULL | Special customer notes |

---

### Table: `sales_order_items`
| Column Name | Data Type | Nullable | Constraints / Default | Description |
|---|---|---|---|---|
| `order_item_id` | INT | NO | PRIMARY KEY, AUTO_INCREMENT | Line item unique ID |
| `order_id` | INT | NO | FOREIGN KEY (`sales_orders.order_id`)| Parent invoice reference |
| `part_id` | INT | NO | FOREIGN KEY (`parts.part_id`) | Part sold |
| `warehouse_id` | INT | NO | FOREIGN KEY (`warehouses.warehouse_id`)| Fulfilling warehouse |
| `quantity` | INT | NO | CHECK (quantity > 0) | Units purchased |
| `unit_price` | DECIMAL(10,2) | NO | CHECK (unit_price >= 0.00) | Selling price per unit at sale time |
| `discount_applied`| DECIMAL(10,2) | NO | DEFAULT 0.00 | Line-specific discount amount |
| `line_total` | DECIMAL(12,2) | NO | NOT NULL | Net line item total |

---

### Table: `stock_movements`
| Column Name | Data Type | Nullable | Constraints / Default | Description |
|---|---|---|---|---|
| `movement_id` | BIGINT | NO | PRIMARY KEY, AUTO_INCREMENT | Ledger transaction ID |
| `part_id` | INT | NO | FOREIGN KEY (`parts.part_id`) | Part reference |
| `warehouse_id` | INT | NO | FOREIGN KEY (`warehouses.warehouse_id`)| Warehouse facility |
| `movement_type` | ENUM | NO | NOT NULL | PURCHASE_RECEIPT, SALE_DISPATCH, SALE_RETURN, WAREHOUSE_TRANSFER, MANUAL_ADJUSTMENT, SCRAP |
| `quantity_changed`| INT | NO | NOT NULL | Delta (+ for in, - for out) |
| `balance_after_movement` | INT | NO | NOT NULL | Snapshot balance after event |
| `reference_id` | VARCHAR(50) | YES | NULL | Invoice No / PO No / Transfer Ref |
| `notes` | VARCHAR(255) | YES | NULL | Descriptive explanation |
| `created_at` | TIMESTAMP | NO | CURRENT_TIMESTAMP | Audit timestamp |

---

## 2. Relational Normalization Analysis

### First Normal Form (1NF) Compliance
- Every table has a well-defined **Primary Key**.
- All columns store **atomic (indivisible) values** (e.g., no comma-separated lists of vehicles in `parts`, no multi-value addresses).
- Repeating groups are eliminated:
  - Multi-vehicle fitments are placed in a dedicated junction table: `part_compatibility`.
  - Multiple order items are stored in dedicated child tables: `purchase_order_items` and `sales_order_items`.

### Second Normal Form (2NF) Compliance
- The schema is in 1NF.
- There are **no partial dependencies**:
  - In tables with composite candidate keys (e.g. `part_compatibility(part_id, vehicle_id)` or `inventory(part_id, warehouse_id)`), every non-key attribute depends on the *entire* primary key, not a subset.
  - Surrogate primary keys (`compatibility_id`, `inventory_id`) are utilized alongside strict composite UNIQUE constraints to ensure strict 2NF conformity.

### Third Normal Form (3NF) Compliance
- The schema is in 2NF.
- There are **no transitive dependencies**:
  - Non-key attributes do not depend on other non-key attributes ($X \rightarrow Y \rightarrow Z$).
  - Example: Manufacturer address/country is stored in `brands`, not duplicated inside `parts`. `parts` holds only `brand_id`.
  - Example: Customer address/discount is stored in `customers`, not duplicated in `sales_orders`. `sales_orders` references `customer_id`.
  - Example: Warehouse details are stored in `warehouses`, not duplicated inside `inventory`.

### Boyce-Codd Normal Form (BCNF) Compliance
- For every non-trivial functional dependency $X \rightarrow Y$, $X$ is a superkey.
- All candidate keys and determinant attributes are unique keys across the schema.
