# 📘 Data Dictionary — E-Commerce Database

This document provides a comprehensive description of all tables, columns, constraints, and relationships in the e-commerce database.   
It serves as a reference for developers, analysts, and maintainers working with the Supabase-hosted schema.  

---

## 🧱 Table: `customers`

| Column Name | Data Type | Constraints | Default | Description | Example |
|--------------|------------|--------------|-----------|--------------|----------|
| customer_id | SERIAL | PRIMARY KEY | — | Unique customer identifier | 1 |
| full_name | VARCHAR(100) | NOT NULL | — | Customer’s full name | “Alice Mwangi” |
| email | VARCHAR(100) | UNIQUE, NOT NULL | — | Customer email address | “alice@example.com” |
| phone | VARCHAR(20) | — | — | Customer contact number | “0712345678” |
| city | VARCHAR(50) | — | — | Customer’s city or location | “Nairobi” |
| created_at | TIMESTAMP | — | NOW() | Timestamp when record was created | “2025-10-18 12:45:00” |

---

## 🧱 Table: `products`

| Column Name | Data Type | Constraints | Default | Description | Example |
|--------------|------------|--------------|-----------|--------------|----------|
| product_id | SERIAL | PRIMARY KEY | — | Unique product identifier | 101 |
| product_name | VARCHAR(100) | UNIQUE, NOT NULL | — | Name of the product | “Wireless Mouse” |
| category | VARCHAR(50) | — | — | Product category or type | “Electronics” |
| price | DECIMAL(10,2) | NOT NULL | — | Unit price of the product | 1200.00 |
| stock_quantity | INT | CHECK (stock_quantity >= 0) | 0 | Available stock count | 50 |
| created_at | TIMESTAMP | — | NOW() | Record creation timestamp | “2025-10-18 12:50:00” |

---

## 🧱 Table: `orders`

| Column Name | Data Type | Constraints | Default | Description | Example |
|--------------|------------|--------------|-----------|--------------|----------|
| order_id | SERIAL | PRIMARY KEY | — | Unique order identifier | 1001 |
| customer_id | INT | FOREIGN KEY → `customers(customer_id)` ON DELETE CASCADE | — | Customer placing the order | 1 |
| product_id | INT | FOREIGN KEY → `products(product_id)` ON DELETE CASCADE | — | Product being ordered | 2 |
| quantity | INT | NOT NULL CHECK (quantity > 0) | — | Number of units purchased | 2 |
| total_amount | DECIMAL(10,2) | COMPUTED (quantity × product.price) | — | Automatically calculated order total | 2400.00 |
| order_date | TIMESTAMP | — | NOW() | Timestamp when order was created | “2025-10-18 13:00:00” |
| status | VARCHAR(20) | CHECK (status IN ('pending', 'paid', 'shipped', 'cancelled', 'completed')) | 'pending' | Current order state | “paid” |

---

## 💳 Table: `payments`

| Column Name | Data Type | Constraints | Default | Description | Example |
|--------------|------------|--------------|-----------|--------------|----------|
| payment_id | SERIAL | PRIMARY KEY | — | Unique payment identifier | 501 |
| order_id | INT | FOREIGN KEY → `orders(order_id)` ON DELETE CASCADE | — | Order associated with the payment | 1001 |
| payment_method | VARCHAR(50) | — | — | Payment channel (e.g., M-Pesa, Card) | “M-Pesa” |
| amount | DECIMAL(10,2) | NOT NULL | — | Amount paid | 2400.00 |
| payment_date | TIMESTAMP | — | NOW() | Payment timestamp | “2025-10-18 13:15:00” |

---

## 🔄 Triggers & Automation

| Trigger Name | Table | Action | Description |
|---------------|--------|---------|--------------|
| `update_total_amount` | `orders` | BEFORE INSERT/UPDATE | Automatically calculates total_amount from `quantity × product.price` |
| `reduce_stock_after_order` | `orders` | AFTER INSERT | Deducts purchased quantity from `products.stock_quantity` |
| `mark_order_paid` | `payments` | AFTER INSERT | Sets order status to “paid” when payment is recorded |
| `restore_stock_on_cancel` | `orders` | AFTER UPDATE | Returns stock to inventory if an order is cancelled |

---

## 🔗 Relationships

| Relationship | Type | Description |
|---------------|------|-------------|
| `customers` → `orders` | One-to-Many | Each customer can place multiple orders |
| `products` → `orders` | One-to-Many | Each product can be included in many orders |
| `orders` → `payments` | One-to-One / Optional | Each order may have one or more payments |

---

## 📊 Views

| View Name | Description |
|------------|--------------|
| `order_summary` | Displays customer name, product, quantity, total amount, and status for each order |
| `sales_summary` | Aggregates total sales and number of orders by product category |

---

## 🔐 Constraints & Integrity Rules

- **All foreign keys use `ON DELETE CASCADE`** to maintain referential integrity.  
- **Check constraints** prevent negative stock or invalid order statuses.  
- **Triggers** ensure data consistency between tables.  
- **Schema normalization:** The database follows Third Normal Form (3NF).  
- **Indexes:** Implicit indexes exist on all primary and foreign key columns.  

---

## 🧠 Notes

- All timestamps use UTC by default (Supabase standard).  
- Supabase Row-Level Security (RLS) can be enabled for privacy control (e.g., users see only their own orders).  
- Suitable for extending into analytics or REST APIs via Supabase PostgREST.  
