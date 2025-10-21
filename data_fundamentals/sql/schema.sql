--Creating table customers
CREATE TABLE customers (
  customer_id SERIAL PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20),
  city VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);

--Creating table Products
CREATE TABLE products (
  product_id SERIAL PRIMARY KEY,
  product_name VARCHAR(100) NOT NULL,
  category VARCHAR(50),
  price DECIMAL(10,2) NOT NULL,
  stock_quantity INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

--Creating table Orders
CREATE TABLE orders (
  order_id SERIAL PRIMARY KEY,
  customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
  product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
  quantity INT NOT NULL,
  total_amount DECIMAL(10,2),
  order_date TIMESTAMP DEFAULT NOW()
);

--Inserting Values Customers
INSERT INTO customers (full_name, email, phone, city) VALUES
('Alice Mwangi', 'alice@example.com', '0712345678', 'Nairobi'),
('Brian Otieno', 'brian@example.com', '0723456789', 'Mombasa'),
('Cynthia Njeri', 'cynthia@example.com', '0734567890', 'Kisumu'),
('David Kimani', 'david@example.com', '0745678901', 'Nakuru'),
('Eva Wambui', 'eva@example.com', '0756789012', 'Eldoret');

-- Inserting Values products
INSERT INTO products (product_name, category, price, stock_quantity) VALUES
('Wireless Mouse', 'Electronics', 1200.00, 50),
('Laptop Backpack', 'Accessories', 2500.00, 30),
('USB Flash Drive 64GB', 'Storage', 1500.00, 40),
('Bluetooth Speaker', 'Electronics', 4500.00, 20),
('Laptop Stand', 'Accessories', 3000.00, 25);

--Inserting values orders
INSERT INTO orders (customer_id, product_id, quantity) VALUES
(1, 2, 1),
(2, 1, 2),
(3, 4, 1),
(4, 5, 1),
(5, 3, 3);

-- update order amount incase it fails to autocalcualte
UPDATE orders AS o
SET total_amount = p.price * o.quantity
FROM products AS p
WHERE o.product_id = p.product_id
  AND o.total_amount IS NULL;

  SELECT order_id, customer_id, product_id, quantity, total_amount
FROM orders
ORDER BY order_id;


-- Check if RLS is enabled for all your tables
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public';

--Authentication and Users

-- Create a users table linked to Supabase Auth users
create table if not exists users (
  id uuid references auth.users on delete cascade,
  email text not null,
  role text check (role in ('admin', 'user')) default 'user',
  primary key (id)
);

-- Check if the users are successfully created
select *
from auth.users;

-- Assigning sample user roles
insert into users (id, email, role)
values
  ('24f29f59-89c1-4f1d-97e9-554029e6a3f3', 'outa.agunga@mail.admi.ac.ke', 'admin'),
  ('b5fa48df-c568-4d73-b42c-e19896d9cfa8', 'typingpool.astu@gmail.com', 'user');

-- Linking orders and customers to authenticated users
--First we are going to add references column to track who created or own data
alter table orders
add column user_id uuid references auth.users (id);

--we are going to do the same for customers table
alter table customers
add column user_id uuid references auth.users (id);

--Check if user_id is added to orders table
select *
from orders;

--then we are going to backfill all existing rows
update orders
set user_id = 'b5fa48df-c568-4d73-b42c-e19896d9cfa8'
where order_id is not null;

--we have not set any policy so, this should return permision denied
select *
from customers;

--enable row level security

-- Enable RLS for customers
alter table customers enable row level security;

-- Enable RLS for products
alter table products enable row level security;

-- Enable RLS for orders
alter table orders enable row level security;

--add roles column to customers table
alter table customers
add column role text default 'user' check (role in ('admin', 'user'));

--cretaing admin policy on customers table. admin can view all customers
create policy "Admins can view all customers"
on customers
for select
using (exists (
  select 1 from customers where user_id = auth.uid() and role = 'admin'
));

-- policy on customers table so users can view own profile
create policy "Users can view their own profile"
on customers
for select
using (auth.uid() = user_id);

--policy on customer tables so users can update their profile
create policy "Users can update their own profile"
on customers
for update
using (auth.uid() = user_id);

--policy on products table
--admin
create policy "Admins can manage all products"
on products
for all
using (exists (
  select 1 from customers where user_id = auth.uid() and role = 'admin'
));

--user
create policy "Users can view products"
on products
for select
using (true);

-- Policies for orders table
create policy "Users can view their own orders"
on orders
for select
using (auth.uid() = customer_id);


create policy "Users can create their own orders"
on orders
for insert
with check (auth.uid() = customer_id);

--policy so Admins can manage all orders
create policy "Admins can manage all orders"
on orders
for all
using (exists (
  select 1 from customers where id = auth.uid() and role = 'admin'
));

-- Test your policies i.e:
--Select all customers → should fail for normal user.
--Select all products → should pass for any user.
--Insert an order for another user → should fail.
--Admin → should have full access.

--Create a Trigger to Sync Auth and Customers
-- Function to auto-create a customer after signup
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
as $$
begin
  insert into customers (id, name, email, role)
  values (new.id, new.email, new.email, 'user');
  return new;
end;
$$;

-- Trigger: runs whenever a new auth user is created
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function handle_new_user();


--policy to Allow only logged-in users to access data
create policy "Only logged-in users can access data"
on customers
for select
using (auth.role() = 'authenticated');

--Create a Secure Admin-only Function. Example 1: Delete a Product (Admin only)
create or replace function admin_delete_product(prod_id uuid)
returns void
language plpgsql
security definer
as $$
begin
  if exists (
    select 1 from customers where id = auth.uid() and role = 'admin'
  ) then
    delete from products where id = prod_id;
  else
    raise exception 'Permission denied: admin access required.';
  end if;
end;
$$;

-- Example 2: View All Orders (Admin only)
create or replace function admin_view_all_orders()
returns table (
  order_id uuid,
  customer_id uuid,
  total_amount numeric,
  order_date timestamp
)
language sql
security definer
as $$
  select id, customer_id, total_amount, created_at
  from orders
  where exists (
    select 1 from customers where id = auth.uid() and role = 'admin'
  );
$$;

-- Testing the Security Rules
-- Simulate admin user
select admin_delete_product('e7a19b7f-56dd-45b0-8a01-927f9cb9a123');









