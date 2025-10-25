
--Creating a app_users table to store users and their roles
CREATE TABLE app_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),  -- auto-generate UUIDs automatically for development use
  email text NOT NULL UNIQUE,
  role text NOT NULL DEFAULT 'user'
    CHECK (role IN ('admin', 'user', 'readonly')),
  created_at timestamptz DEFAULT now()
);


-- inserting sample data to the created app_users table  
INSERT INTO app_users (email, role)
VALUES
('outa.agunga@mail.admi.ac.ke', 'admin'),
('typingpool.astu@gmail.com', 'user'),
('alice@example.com', 'user'),
('brian@example.com', 'user'),
('cynthia@example.com', 'user'),
('david@example.com', 'user'),
('eva@example.com', 'user');

-- Creating tables for our project
-- 1️⃣ Create customers table
CREATE TABLE customers (
  customer_id SERIAL PRIMARY KEY,
  user_id uuid REFERENCES app_users(id) ON DELETE CASCADE,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20),
  city VARCHAR(50),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);


-- 2️⃣ Create products table
CREATE TABLE IF NOT EXISTS products (
  product_id SERIAL PRIMARY KEY,
  product_name VARCHAR(100) NOT NULL,
  category VARCHAR(50),
  price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
  stock_quantity INT DEFAULT 0 CHECK (stock_quantity >= 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 3️⃣ Create orders table
CREATE TABLE orders (
  order_id SERIAL PRIMARY KEY,
  customer_id INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
  product_id INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
  user_id uuid REFERENCES app_users(id) ON DELETE CASCADE,
  quantity INT NOT NULL CHECK (quantity > 0),
  total_amount NUMERIC(12,2),
  order_date TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- adding triggers to autocalculate total amount incase it fails
-- helper function
CREATE OR REPLACE FUNCTION calculate_order_total()
RETURNS TRIGGER AS $$
BEGIN
  -- calculate total using product price
  SELECT p.price * NEW.quantity INTO NEW.total_amount
  FROM products p
  WHERE p.product_id = NEW.product_id;

  -- set user_id to current authenticated uid if not provided
  IF NEW.user_id IS NULL THEN
    NEW.user_id := auth.uid();  -- supabase helper
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- trigger
CREATE TRIGGER trg_calc_order_total
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION calculate_order_total();

-- inserting sample data to our tables
-- Customers
INSERT INTO customers (full_name, email, phone, city)
VALUES
('Outa Agunga', 'outa.agunga@mail.admi.ac.ke', '0724907275', 'Nairobi'),
('Typing Pool', 'typingpool.astu@gmail.com', '0703645678', 'Machakos'),
('Alice Mwangi', 'alice@example.com', '0712345678', 'Turkana'),
('Brian Otieno', 'brian@example.com', '0723456789', 'Mombasa'),
('Cynthia Njeri', 'cynthia@example.com', '0734567890', 'Kisumu'),
('David Kimani', 'david@example.com', '0745678901', 'Nakuru'),
('Eva Wambui', 'eva@example.com', '0756789012', 'Eldoret');

-- Products
INSERT INTO products (product_name, category, price, stock_quantity)
VALUES
('Wireless Mouse', 'Electronics', 1200.00, 50),
('Micro Wave', 'Household', 7500.00, 17),
('Casio Calcualtor', 'Electronics', 2500.00, 21),
('Laptop Backpack', 'Accessories', 2500.00, 30),
('USB Flash Drive 64GB', 'Storage', 1500.00, 40),
('Bluetooth Speaker', 'Electronics', 4500.00, 20),
('Laptop Stand', 'Accessories', 3000.00, 25);

-- Orders (note total_amount will be auto-calculated by trigger)
INSERT INTO orders (customer_id, product_id, quantity)
VALUES
(1, 2, 1),
(2, 1, 2),
(3, 4, 1),
(4, 5, 1),
(5, 3, 3),
(6, 3, 3),
(7, 3, 3);

-- linking customers table to users table using uuid
UPDATE customers AS c
SET user_id = au.id
FROM app_users AS au
WHERE LOWER(TRIM(c.email)) = LOWER(TRIM(au.email))
  AND c.user_id IS NULL;

  --also update tables for orders
UPDATE orders AS o
SET user_id = c.user_id
FROM customers AS c
WHERE o.customer_id = c.customer_id
  AND o.user_id IS NULL;

-- Enable RLS security on all tables
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;



-- revoke all default public access
-- Customers
REVOKE ALL ON customers FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON customers TO authenticated;

-- Products
REVOKE ALL ON products FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON products TO authenticated;

-- Orders
REVOKE ALL ON orders FROM PUBLIC;
GRANT SELECT, INSERT, UPDATE, DELETE ON orders TO authenticated;


--Policies on customers table 

-- 1️⃣ Admin: full visibility and control
CREATE POLICY customers_admin_all ON customers
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM app_users au
    WHERE au.id = auth.uid() AND au.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM app_users au
    WHERE au.id = auth.uid() AND au.role = 'admin'
  )
);


-- 2️⃣ Users: view only their own profile
CREATE POLICY customers_user_select_own ON customers
FOR SELECT
USING (
  user_id = auth.uid()
);


-- 3️⃣ Users: insert only their own record
CREATE POLICY customers_user_insert_own ON customers
FOR INSERT
WITH CHECK (
  user_id = auth.uid()
);


-- 4️⃣ Users: update their own record
CREATE POLICY customers_user_update_own ON customers
FOR UPDATE
USING (
  user_id = auth.uid()
)
WITH CHECK (
  user_id = auth.uid()
);


-- 5️⃣ Users: delete their own profile
CREATE POLICY customers_user_delete_own ON customers
FOR DELETE
USING (
  user_id = auth.uid()
);

--Polies on orders table
-- 1️⃣ Admin: full access
CREATE POLICY orders_admin_all ON orders
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM app_users au
    WHERE au.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM app_users au
    WHERE au.role = 'admin'
  )
);


-- 2️⃣ Users: view only their own orders
CREATE POLICY orders_user_select_own ON orders
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM app_users au
    WHERE au.id = orders.user_id
  )
);


-- 3️⃣ Users: insert orders only for themselves
CREATE POLICY orders_user_insert_own ON orders
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM app_users au
    WHERE au.id = orders.user_id
  )
);


-- 4️⃣ Users: update their own orders
CREATE POLICY orders_user_update_own ON orders
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM app_users au
    WHERE au.id = orders.user_id
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM app_users au
    WHERE au.id = orders.user_id
  )
);


-- 5️⃣ Users: delete their own orders
CREATE POLICY orders_user_delete_own ON orders
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM app_users au
    WHERE au.id = orders.user_id
  )
);

-- List all policies we've created
SELECT tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE schemaname = 'public';


--Test and Validate Policies 

--Prepare Mock Data- We’ll simulate a few users and sample data to test policies.
-- 👥 Create 2 fake app users (acting as Supabase Auth substitutes)
INSERT INTO app_users (id, email, role)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'admin@example.com', 'admin'),
  ('22222222-2222-2222-2222-222222222222', 'user1@example.com', 'user'),
  ('33333333-3333-3333-3333-333333333333', 'user2@example.com', 'user')
ON CONFLICT (id) DO NOTHING;

-- 🧍‍♂️ Customers (linked to app_users)
INSERT INTO customers (full_name, email, user_id)
VALUES
  ('Admin Tester', 'admin@example.com', '11111111-1111-1111-1111-111111111111'),
  ('John User', 'user1@example.com', '22222222-2222-2222-2222-222222222222'),
  ('Mary User', 'user2@example.com', '33333333-3333-3333-3333-333333333333')
ON CONFLICT DO NOTHING;

-- 📦 Products
INSERT INTO products (product_name, category, price)
VALUES
  ('Laptop', 'Electronics', 85000),
  ('Shoes', 'Fashion', 2500),
  ('Book', 'Education', 1200)
ON CONFLICT DO NOTHING;

-- 🧾 Orders
INSERT INTO orders (customer_id, product_id, quantity, user_id)
VALUES
  (1, 1, 1, '22222222-2222-2222-2222-222222222222'),
  (2, 2, 2, '33333333-3333-3333-3333-333333333333');


--Setting up Helper Function to test as specific users
-- Create a helper to simulate "logged in" user sessions
-- Create a helper to simulate logged-in user
CREATE OR REPLACE FUNCTION current_app_user_id()
RETURNS uuid AS $$
  SELECT current_setting('app.current_user', true)::uuid;
$$ LANGUAGE sql STABLE;

-- Helper to set the simulated user id
CREATE OR REPLACE FUNCTION set_app_user(uid uuid)
RETURNS void AS $$
BEGIN
  PERFORM set_config('app.current_user', uid::text, false);
END;
$$ LANGUAGE plpgsql;





--Test as Admin 
-- 🧑‍💼 Simulate admin login
SELECT set_local_user('11111111-1111-1111-1111-111111111111');

-- ✅ Admin should see all customers
SELECT * FROM customers;

-- ✅ Admin should see all orders
SELECT * FROM orders;

-- ✅ Admin can update anyone’s order
UPDATE orders SET quantity = 10 WHERE order_id = 1 RETURNING *;

-- ✅ Admin can insert new products
INSERT INTO products (product_name, category, price)
VALUES ('Tablet', 'Electronics', 40000)
RETURNING *;

-- Test as Regular User (User1)
-- 👤 Simulate user1 login
SELECT set_local_user('22222222-2222-2222-2222-222222222222');

-- ✅ Should only see their own customer record
--Not working
SELECT * FROM customers;

-- ✅ Should only see their own orders
--Not working
SELECT * FROM orders;

-- ✅ Can create their own order
--Not working
INSERT INTO orders (customer_id, product_id, quantity, user_id)
VALUES (1, 3, 1, '22222222-2222-2222-2222-222222222222')
RETURNING *;

-- ❌ Should NOT see other users' orders
--Not working
SELECT * FROM orders WHERE user_id = '33333333-3333-3333-3333-333333333333';

-- ❌ Should NOT update another user’s order
UPDATE orders SET quantity = 5 WHERE user_id = '33333333-3333-3333-3333-333333333333' RETURNING *;


-- Drop all policies for all your main tables
DROP POLICY IF EXISTS customers_admin_all ON customers;
DROP POLICY IF EXISTS customers_user_select_own ON customers;
DROP POLICY IF EXISTS customers_user_insert_own ON customers;
DROP POLICY IF EXISTS customers_user_update_own ON customers;
DROP POLICY IF EXISTS customers_user_delete_own ON customers;

DROP POLICY IF EXISTS orders_admin_all ON orders;
DROP POLICY IF EXISTS orders_user_select_own ON orders;
DROP POLICY IF EXISTS orders_user_insert_own ON orders;
DROP POLICY IF EXISTS orders_user_update_own ON orders;
DROP POLICY IF EXISTS orders_user_delete_own ON orders;

DROP POLICY IF EXISTS products_admin_all ON products;
DROP POLICY IF EXISTS products_user_insert ON products;
DROP POLICY IF EXISTS products_user_update_own ON products;
DROP POLICY IF EXISTS products_user_select_all ON products;

DROP POLICY IF EXISTS app_users_admin_all ON app_users;
DROP POLICY IF EXISTS app_users_user_select_own ON app_users;


DROP FUNCTION IF EXISTS set_local_user;
DROP FUNCTION IF EXISTS set_local_user(uuid);
DROP FUNCTION IF EXISTS current_local_user_id();
