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

--Show all customers 
select *
from customers;

--Joining orders table and products table
SELECT o.order_id, c.full_name, p.product_name, o.quantity, o.total_amount, o.order_date
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id;

--Show customers and number of orders placed
SELECT c.full_name, COUNT(o.order_id) AS total_orders
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.full_name;

-- Show the highest order amount
SELECT order_id, product_id, quantity, total_amount
FROM orders
ORDER BY order_id DESC
LIMIT 1;

-- update order amount incase it fails to autocalcualte
UPDATE orders AS o
SET total_amount = p.price * o.quantity
FROM products AS p
WHERE o.product_id = p.product_id
  AND o.total_amount IS NULL;

  SELECT order_id, customer_id, product_id, quantity, total_amount
FROM orders
ORDER BY order_id;


-- Reduce stock quantity after order is placed
CREATE OR REPLACE FUNCTION reduce_stock()
RETURNS TRIGGER AS $$
BEGIN
  -- Check stock availability
  IF (SELECT stock_quantity FROM products WHERE product_id = NEW.product_id) < NEW.quantity THEN
    RAISE EXCEPTION 'Not enough stock available for product_id %', NEW.product_id;
  END IF;

  -- Deduct stock
  UPDATE products
  SET stock_quantity = stock_quantity - NEW.quantity
  WHERE product_id = NEW.product_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to reduce stock after new order is plced
CREATE TRIGGER update_stock_after_order
AFTER INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION reduce_stock();

-- Show customers table
select *
from customers;

-- Show products table
select *
from products;

-- Show orders table 
select *
from orders;

-- Show customers and their orders
SELECT o.order_id, c.full_name, p.product_name, o.quantity, o.total_amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id;

-- Show total revenue
SELECT SUM(total_amount) AS total_revenue FROM orders;