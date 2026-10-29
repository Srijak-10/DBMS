# Entity-Relationship (ER) Diagram
## Vehicle Spare Parts and Inventory Management System (VSP-IMS)

### 1. Conceptual ER Diagram (Mermaid)

```mermaid
erDiagram
    CATEGORIES ||--o{ CATEGORIES : "parent of"
    CATEGORIES ||--o{ PARTS : "classifies"
    BRANDS ||--o{ PARTS : "manufactures"
    
    PARTS ||--o{ PART_COMPATIBILITY : "fits into"
    VEHICLES ||--o{ PART_COMPATIBILITY : "compatible with"
    
    PARTS ||--o{ INVENTORY : "stocked as"
    WAREHOUSES ||--o{ INVENTORY : "stored in"
    
    SUPPLIERS ||--o{ PURCHASE_ORDERS : "supplies"
    WAREHOUSES ||--o{ PURCHASE_ORDERS : "received at"
    PURCHASE_ORDERS ||--|{ PURCHASE_ORDER_ITEMS : "contains"
    PARTS ||--o{ PURCHASE_ORDER_ITEMS : "ordered in"
    
    CUSTOMERS ||--o{ SALES_ORDERS : "places"
    SALES_ORDERS ||--|{ SALES_ORDER_ITEMS : "consists of"
    PARTS ||--o{ SALES_ORDER_ITEMS : "billed in"
    WAREHOUSES ||--o{ SALES_ORDER_ITEMS : "fulfilled from"
    
    PARTS ||--o{ STOCK_MOVEMENTS : "audits"
    WAREHOUSES ||--o{ STOCK_MOVEMENTS : "tracks location"

    CATEGORIES {
        int category_id PK
        int parent_category_id FK
        string category_name
        string description
    }

    BRANDS {
        int brand_id PK
        string brand_name
        string country_of_origin
        boolean is_oem
    }

    PARTS {
        int part_id PK
        string part_number UK
        string part_name
        int category_id FK
        int brand_id FK
        decimal cost_price
        decimal selling_price
        int min_stock_level
        int max_stock_level
        int warranty_months
    }

    VEHICLES {
        int vehicle_id PK
        string make
        string model
        int year_start
        int year_end
        string engine_displacement
        string fuel_type
        string transmission
    }

    PART_COMPATIBILITY {
        int compatibility_id PK
        int part_id FK
        int vehicle_id FK
        string position_notes
    }

    WAREHOUSES {
        int warehouse_id PK
        string warehouse_code UK
        string warehouse_name
        string city
        string state
    }

    INVENTORY {
        int inventory_id PK
        int part_id FK
        int warehouse_id FK
        string aisle
        string shelf
        string bin
        int quantity_on_hand
        timestamp last_restocked_at
    }

    SUPPLIERS {
        int supplier_id PK
        string company_name UK
        string contact_name
        string phone
        string email
        decimal rating
    }

    PURCHASE_ORDERS {
        int po_id PK
        string po_number UK
        int supplier_id FK
        int warehouse_id FK
        date order_date
        date expected_delivery_date
        decimal total_amount
        string status
    }

    PURCHASE_ORDER_ITEMS {
        int po_item_id PK
        int po_id FK
        int part_id FK
        int quantity_ordered
        int quantity_received
        decimal unit_cost
    }

    CUSTOMERS {
        int customer_id PK
        string customer_type
        string full_name
        string phone UK
        decimal discount_percentage
    }

    SALES_ORDERS {
        int order_id PK
        string invoice_number UK
        int customer_id FK
        timestamp order_date
        decimal subtotal
        decimal discount_amount
        decimal tax_amount
        decimal grand_total
        string payment_status
        string order_status
    }

    SALES_ORDER_ITEMS {
        int order_item_id PK
        int order_id FK
        int part_id FK
        int warehouse_id FK
        int quantity
        decimal unit_price
        decimal discount_applied
        decimal line_total
    }

    STOCK_MOVEMENTS {
        bigint movement_id PK
        int part_id FK
        int warehouse_id FK
        string movement_type
        int quantity_changed
        int balance_after_movement
        string reference_id
        timestamp created_at
    }
```

---

### 2. Entity Relationships & Cardinality Description

| Relationship | Entities Involved | Cardinality | Business Rule |
|---|---|---|---|
| **Category Hierarchy** | `categories` $\rightarrow$ `categories` | $1 : N$ (Optional) | A parent category can have multiple subcategories (e.g., Braking $\rightarrow$ Brake Rotors). |
| **Catalog Classification** | `categories` $\rightarrow$ `parts` | $1 : N$ (Mandatory) | Every part belongs to exactly one category; a category groups multiple parts. |
| **Brand Manufacturing** | `brands` $\rightarrow$ `parts` | $1 : N$ (Mandatory) | Every part is produced by a manufacturer / brand (Bosch, Brembo, etc.). |
| **Vehicle Fitment** | `parts` $\leftrightarrow$ `vehicles` | $M : N$ via `part_compatibility` | A spare part can fit multiple vehicles (e.g. spark plug fits Corolla and Civic); a vehicle requires many parts. |
| **Multi-Location Inventory** | `parts` $\leftrightarrow$ `warehouses` | $M : N$ via `inventory` | A part can be stored across multiple warehouses with bin/shelf coordinates. |
| **Procurement PO** | `suppliers` $\rightarrow$ `purchase_orders` | $1 : N$ | A supplier receives multiple purchase orders for stock replenishment. |
| **PO Line Items** | `purchase_orders` $\rightarrow$ `purchase_order_items` | $1 : N$ (Mandatory) | A PO consists of multiple items ordered. |
| **Customer Orders** | `customers` $\rightarrow$ `sales_orders` | $1 : N$ | Retail buyers, workshops, or fleet clients place multiple sales orders. |
| **Invoice Line Items** | `sales_orders` $\rightarrow$ `sales_order_items` | $1 : N$ (Mandatory) | An invoice contains one or more line items dispatched from specific warehouses. |
| **Inventory Audit Trail** | `parts` / `warehouses` $\rightarrow$ `stock_movements` | $1 : N$ | Immutable audit ledger logging every stock increase, decrease, or internal transfer. |
