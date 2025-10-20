
# JECO E-COMMERCE SQL Project

<a name="readme-top"></a>

<!-- TABLE OF CONTENTS -->

# 📗 Table of Contents

- [My SQL Project](#about-project)
- [📗 Table of Contents](#-table-of-contents)
- [📖 My SQL Project](#about-project)
  - [🛠 Built With ](#-built-with-)
    - [Tech Stack ](#tech-stack-)
    - [Key Features ](#key-features-)
  - [💻 Getting Started ](#-getting-started-)
    - [Prerequisites](#prerequisites)
    - [Setup](#setup)
    - [Usage](#usage)
  - [👥 Authors ](#-authors-)
  - [🔭 Future Features ](#-future-features-)
  - [🤝 Contributing ](#-contributing-)

<!-- PROJECT DESCRIPTION -->

# 📖 Jeco E-Commerce SQL Project <a name="about-project"></a>

**Jeco E-commerce SQL Project** is a simple Database that uses SQL, Postgres via Supabase to create, query and secure **E-Commerce** database.

## 🛠 Built With <a name="built-with"></a>

### Tech Stack <a name="tech-stack"></a>
- SQL
- Postgres DB

<!-- Features -->

### Key Features <a name="key-features"></a>

- [ ] **Tables**
- [ ] **Schema**
- [ ] **Access control**

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->

## 💻 Getting Started <a name="getting-started"></a>

To rebuild this E-Commerce SQL Database, follow these steps.

### Prerequisites

To run this project, you need:
- [A Supabase account](https://supabase.com/)
- [Knowledge on SQL](https://www.w3schools.com/sql/)
- A schema for creating your tables in the E-commerce Database

--- 
<!-- ### Project Overview -->

This project is a simple **E-commerce database** built using **Supabase (PostgreSQL)**.  
It demonstrates key database design principles including normalization, relationships, and data integrity.

## 🧱 Database Schema Overview
The database supports typical e-commerce operations:  
### Tables
1. **customers** — stores customer details  
2. **products** — stores product listings  
3. **orders** — records customer purchases

### Relationships
- Each **customer** can place **many orders**  
- Each **order** links to a **product**  

![ERD Diagram](https://github.com/outaagunga/final_project_ADMI/blob/working/data_tools/docs/ERD_Diagram.png)

---  

<!-- ### Setup -->
### Setup

Clone this repository for the E- Commerce Database to your desired folder on the local machine (pc):

```sh
  git clone https://github.com/outaagunga/final_project_ADMI.git
  
  # then change directory to the project directory, i,e 
  cd final_project_ADMI
```

<!-- ### Database Creation -->

### Database Schema

- The Database is made up of 3 tables ie `customers`, `products` and `orders`. Eaach table has atleast 5 entries (rows).  
- To create the table, you will need a schema as shown below:

Open Supabase SQL Editor and paste the contents of:

`/sql/schema.sql`
`/sql/sample_data.sql`  

For example:  

```sql
-- Drop old tables if they exist
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS orders CASCADE;

-- Create customers table
CREATE TABLE customers (
  customer_id SERIAL PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20),
  city VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create products table
CREATE TABLE products (
  product_id SERIAL PRIMARY KEY,
  product_name VARCHAR(100) NOT NULL,
  category VARCHAR(50),
  price DECIMAL(10,2) NOT NULL,
  stock_quantity INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create orders table
CREATE TABLE orders (
  order_id SERIAL PRIMARY KEY,
  customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
  product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
  quantity INT NOT NULL,
  total_amount DECIMAL(10,2),
  order_date TIMESTAMP DEFAULT NOW()
);


-- Insert data into customers table
INSERT INTO customers (full_name, email, phone, city) VALUES
('Alice Mwangi', 'alice@example.com', '0712345678', 'Nairobi'),
('Brian Otieno', 'brian@example.com', '0723456789', 'Mombasa'),
('Cynthia Njeri', 'cynthia@example.com', '0734567890', 'Kisumu'),
('David Kimani', 'david@example.com', '0745678901', 'Nakuru'),
('Eva Wambui', 'eva@example.com', '0756789012', 'Eldoret');


-- Insert data into products table
INSERT INTO products (product_name, category, price, stock_quantity) VALUES
('Wireless Mouse', 'Electronics', 1200.00, 50),
('Laptop Backpack', 'Accessories', 2500.00, 30),
('USB Flash Drive 64GB', 'Storage', 1500.00, 40),
('Bluetooth Speaker', 'Electronics', 4500.00, 20),
('Laptop Stand', 'Accessories', 3000.00, 25);


-- Insert data into orders table
INSERT INTO orders (customer_id, product_id, quantity) VALUES
(1, 2, 1),
(2, 1, 2),
(3, 4, 1),
(4, 5, 1),
(5, 3, 3);

```

- This is the visual snipppet of how the different tables look in the supabase:  

snippet of customers table
<img width="1893" height="476" alt="image" src="https://github.com/outaagunga/final_project_ADMI/blob/working/data_tools/docs/customers.png" />

snippet of products table:
<img width="1881" height="445" alt="image" src="https://github.com/outaagunga/final_project_ADMI/blob/working/data_tools/docs/products.png" />

snippets of orders table:
<img width="1881" height="505" alt="image" src="https://github.com/outaagunga/final_project_ADMI/blob/working/data_tools/docs/orders.png" />

snippets of customer and their order details:
<img width="1881" height="505" alt="image" src="https://github.com/outaagunga/final_project_ADMI/blob/working/data_tools/docs/customer_and_their_orders.png" />

snippets of order details:
<img width="1881" height="505" alt="image" src="https://github.com/outaagunga/final_project_ADMI/blob/working/data_tools/docs/order_details.png" />

snippets of total reveue:
<img width="1881" height="505" alt="image" src="https://github.com/outaagunga/final_project_ADMI/blob/working/data_tools/docs/total_revenue.png" />


- Visual snippet of ERD diagram as viewed in the supabase: 
<img width="1064" height="577" alt="image" src="https://github.com/outaagunga/final_project_ADMI/blob/working/data_tools/docs/ERD_Diagram.png" />

- To test the table, I used the queries:  

Get All Customers  
```sql
SELECT * 
FROM customers;
```

Get Order Details (with Customer & Product Info)  
```sql
SELECT o.order_id, c.full_name, p.product_name, o.quantity, o.total_amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p ON o.product_id = p.product_id;
```

Calculate Total Revenue  
```sql
SELECT SUM(total_amount) AS total_revenue FROM orders;
```

Show customers and their total orders  
```sql
SELECT c.full_name, COUNT(o.order_id) AS total_orders
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.full_name;
```


- Here are the results of the queries:
<img width="1460" height="791" alt="image" src="https://github.com/user-attachments/assets/37cf0a4e-ca92-4d8d-8888-2cca0165d32b" />

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- AUTHORS -->

## 👥 Authors <a name="authors"></a>

👤 **Joy Phoebe**

- GitHub: [@joyapisi](https://github.com/joyapisi)
- Twitter: [@joyphoebe300](https://twitter.com/joyphoebe300)
- LinkedIn: [@joyapisi](https://linkedin.com/in/joyapisi)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- FUTURE FEATURES -->

## 🔭 Future Features <a name="future-features"></a>

- [ ] **Add security**
- [ ] **Link DB to R for visualisation purposes and further analyses**

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTRIBUTING -->

## 🤝 Contributing <a name="contributing"></a>

Contributions, issues, and feature requests are welcome!

Feel free to check the [issues page](../../issues/).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- SUPPORT -->
