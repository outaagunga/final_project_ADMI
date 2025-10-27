
# 🧱 Data Fundamentals Project: Admin Roles & Security in Supabase

<a name="readme-top"></a>

## 📗 Table of Contents
- [📖 Overview](#overview)
- [🛠 Built With](#built-with)
- [🧩 Database Design](#database-design)
- [🧑‍💻 Roles & Access Control](#roles--access-control)
- [🔐 Security Policies (RLS)](#security-policies-rls)
- [⚙️ Setup Instructions](#setup-instructions)
- [🧪 Testing the Setup](#testing-the-setup)
- [🧠 Key Learnings](#key-learnings)
- [👥 Author](#author)
- [🔭 Future Improvements](#future-improvements)

---

## 📖 Overview <a name="overview"></a>

This project is part of the **Data Fundamentals Unit**.  
It focuses on applying **data access control, admin privileges, and Row-Level Security (RLS)** using **Supabase (PostgreSQL)**.

> **Goal:** is to learn how to manage user roles, enforce least privilege, and document a secure data model.

---

## 🛠 Built With <a name="built-with"></a>

### Tech Stack
- **PostgreSQL (Supabase)**
- **SQL**
- **Supabase Auth**
- **GitHub**

### Tools
- Supabase SQL Editor
- GitHub for version control
- Supabase Dashboard for policy and auth testing

---

## 🧩 Database Design <a name="database-design"></a>

This project extends the **E-Commerce SQL Project** from the previous unit.  
It includes **3 core data tables** and a new **`app_users`** table for managing user roles and authentication links.

### Tables
1. **app_users** — stores user accounts and their assigned roles  
2. **customers** — customer information  
3. **products** — product catalog  
4. **orders** — order transactions linked to customers and products  

### Relationships
- Each `app_user` can be a **regular user** or an **admin**.
- Each `customer` can place **many orders**.
- Each `order` links to one `product`.

---

## 🧑‍💻 Roles & Access Control <a name="roles--access-control"></a>

### Defined Roles
| Role | Description | Permissions |
|------|--------------|--------------|
| `admin` | Has full access to all tables | SELECT, INSERT, UPDATE, DELETE |
| `user` | Can only access and modify their own data | SELECT, INSERT (own), UPDATE (own) |
| `readonly` | Can view but not modify data | SELECT only |

### app_users Table Example
```sql
CREATE TABLE app_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE,
  role text NOT NULL DEFAULT 'user'
    CHECK (role IN ('admin', 'user', 'readonly')),
  created_at timestamptz DEFAULT now()
);
````

Sample data:

```sql
INSERT INTO app_users (email, role) VALUES
('admin@example.com', 'admin'),
('user1@example.com', 'user'),
('user2@example.com', 'readonly');
```

---

## 🔐 Security Policies (RLS) <a name="security-policies-rls"></a>

RLS ensures that users only access data they are authorized to see.

### Enable RLS

```sql
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
```

### Example Policies

#### 1️⃣ Users can view and insert their own data

```sql
CREATE POLICY "Users can view their own customers"
ON customers
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own record"
ON customers
FOR INSERT WITH CHECK (auth.uid() = id);
```

#### 2️⃣ Admins can do everything

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

#### 3️⃣ Readonly users can only view data

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

## ⚙️ Setup Instructions <a name="setup-instructions"></a>

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/outaagunga/final_project_ADMI.git  
cd data_fundamentals  
```

### 2️⃣ Open Supabase SQL Editor

* Copy the SQL scripts from `/sql/schema.sql` and `/sql/policies.sql`
* Run them in Supabase

### 3️⃣ Enable Auth

* In Supabase Dashboard → Authentication → Enable Email/Password sign-in
* Create test users (`admin`, `user`, `readonly`)

### 4️⃣ Run the Data Scripts

* `/sql/sample_data.sql` → insert your test records

---

## 🧪 Testing the Setup <a name="testing-the-setup"></a>

### 1️⃣ Simulate User Sessions

In the SQL Editor:

```sql
-- Set the current test user
SELECT set_config('request.jwt.claim.sub', '<user-uuid>', true);
```

### 2️⃣ Test as Admin

```sql
SELECT * FROM customers;
UPDATE customers SET city = 'Nairobi' WHERE customer_id = 1;
```

### 3️⃣ Test as Regular User

```sql
SELECT * FROM customers;  -- should only see own rows
UPDATE customers SET city = 'Kisumu' WHERE id = auth.uid(); -- allowed only for own row
```

### 4️⃣ Test as Readonly User

```sql
SELECT * FROM customers;  -- works
INSERT INTO customers (...) VALUES (...);  -- should fail
```

---

## 🧠 Key Areas Covered  <a name="key-learnings"></a>

* How to implement **Row-Level Security (RLS)** in PostgreSQL
* How to link **Supabase Auth users** with app-specific roles
* How to define and test **SQL policies**
* How to simulate different user roles in Supabase

---

## 👥 Author <a name="author"></a>

👤 **Outa Agunga**

* GitHub: [@outaagunga](https://github.com/outaagunga)
* Twitter: [@jeconiaouta](https://twitter.com/jeconiaouta)
* LinkedIn: [@outaagunga](https://linkedin.com/in/outaagunga)

---

## 🔭 Future Improvements <a name="future-improvements"></a>

* [ ] Add audit logs for user activity
* [ ] Integrate Supabase storage policies
* [ ] Connect to a dashboard for admin analytics

---

<p align="right">(<a href="#readme-top">back to top</a>)</p>
```

---

