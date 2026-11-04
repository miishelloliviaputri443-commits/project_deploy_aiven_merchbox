CREATE DATABASE IF NOT EXISTS merchandise_db;
USE merchandise_db;

CREATE TABLE IF NOT EXISTS products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  description TEXT NOT NULL,
  category VARCHAR(80) NOT NULL DEFAULT 'Gantungan Kunci',
  price INT UNSIGNED NOT NULL,
  stock INT UNSIGNED NOT NULL DEFAULT 0,
  image_url VARCHAR(500) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT products_category_keychain CHECK (category = 'Gantungan Kunci')
);

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELETE FROM products WHERE category <> 'Gantungan Kunci';

INSERT INTO products(name,description,category,price,stock)
SELECT 'Gantungan Kunci Akrilik','Gantungan kunci akrilik desain pilihan','Gantungan Kunci',12000,75
WHERE NOT EXISTS (SELECT 1 FROM products WHERE name = 'Gantungan Kunci Akrilik');
