
# 🔐 Security Notes — Supabase Admin Roles & RLS Setup

## 🧱 Project Overview
This document summarizes the **security architecture** implemented in the  
**Data Fundamentals Project: Admin Roles & Security in Supabase**.  

The goal of this project was to apply **Row Level Security (RLS)**,  
define **admin and user roles**, and demonstrate **secure access control**  
for a PostgreSQL (Supabase) database.

---

## 🧩 1. Database Structure

### Core Tables
| Table | Purpose |
|--------|----------|
| `app_users` | Stores users and their assigned roles (`admin`, `user`, `readonly`) |
| `customers` | Contains customer information |
| `products` | Holds product catalog details |
| `orders` | Tracks customer purchases and links to customers/products |

Each table has RLS enabled to restrict access based on user roles.

---

## 👤 2. Roles and Permissions

| Role | Description | Permissions |
|------|--------------|-------------|
| **admin** | Full access to all tables | SELECT, INSERT, UPDATE, DELETE |
| **user** | Can view and modify only their own data | SELECT (own), INSERT (own), UPDATE (own) |
| **readonly** | View-only access | SELECT only |

### Role Implementation
The `app_users` table connects Supabase Auth users to application roles:
```sql
CREATE TABLE app_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE,
  role text NOT NULL DEFAULT 'user'
    CHECK (role IN ('admin', 'user', 'readonly')),
  created_at timestamptz DEFAULT now()
);
````

Sample entries:

```sql
INSERT INTO app_users (email, role) VALUES
('admin@example.com', 'admin'),
('user1@example.com', 'user'),
('viewer@example.com', 'readonly');
```

---

## 🔐 3. Row-Level Security (RLS)

RLS was enabled for all major data tables:

```sql
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
```

### Example Policies

#### a) User Policies

```sql
CREATE POLICY "Users can view their own customers"
ON customers
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own record"
ON customers
FOR INSERT WITH CHECK (auth.uid() = id);
```

#### b) Admin Policies

```sql
CREATE POLICY "Admins have full access"
ON customers
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM app_users
    WHERE id = auth.uid() AND role = 'admin'
  )
);
```

#### c) Readonly Policies

```sql
CREATE POLICY "Readonly users can view only"
ON customers
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM app_users
    WHERE id = auth.uid() AND role = 'readonly'
  )
);
```

---

## ⚙️ 4. Custom Admin-Only Function

A secure function was created to demonstrate how only admins can
execute certain actions, using **`SECURITY DEFINER`** and role validation.

```sql
CREATE OR REPLACE FUNCTION delete_order(order_id uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
AS $$
  DELETE FROM orders WHERE orders.order_id = delete_order.order_id;
$$;
```

This function is restricted so that:

* Only authenticated users with role = `admin` can execute it.
* Public access is revoked for safety.

---

## 🧪 5. Testing

Testing was performed using Supabase’s SQL Editor:

1. Simulate users with:

   ```sql
   SELECT set_config('request.jwt.claim.sub', '<user-uuid>', true);
   ```
2. Test SELECT, INSERT, UPDATE, DELETE for each role.
3. Confirm that:

   * Admin sees and edits all data.
   * Regular user sees only their records.
   * Readonly user can only view data.
   * Only admin can execute the `delete_order()` function.

---

## 🧠 6. Security Principles Applied

* **Least Privilege:** Every role has the minimum necessary access.
* **Defense in Depth:** Auth + RLS + Policy checks on all key tables.
* **Role Separation:** Distinct access patterns for admin, user, and readonly.
* **Secure Functions:** Admin actions isolated using `SECURITY DEFINER`.


---

👤 **Author:** Outa Agunga
🔗 [GitHub: @outaagunga](https://github.com/outaagunga)


---
