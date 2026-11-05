CREATE DATABASE IF NOT EXISTS merchandise_db;
USE merchandise_db;

CREATE TABLE IF NOT EXISTS products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  description TEXT NOT NULL,
  category ENUM('Gantungan Kunci', 'Pin') NOT NULL DEFAULT 'Gantungan Kunci',
  price INT UNSIGNED NOT NULL,
  stock INT UNSIGNED NOT NULL DEFAULT 0,
  image_url VARCHAR(500) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SET @drop_old_category_check = (
  SELECT IF(
    COUNT(*) > 0,
    'ALTER TABLE products DROP CHECK products_category_keychain',
    'SELECT 1'
  )
  FROM information_schema.table_constraints
  WHERE constraint_schema = DATABASE()
    AND table_name = 'products'
    AND constraint_name = 'products_category_keychain'
);
PREPARE drop_old_category_check FROM @drop_old_category_check;
EXECUTE drop_old_category_check;
DEALLOCATE PREPARE drop_old_category_check;

ALTER TABLE products
  MODIFY category ENUM('Gantungan Kunci', 'Pin')
  NOT NULL DEFAULT 'Gantungan Kunci';

SET @add_updated_at = (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE products ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',
    'SELECT 1'
  )
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'products'
    AND column_name = 'updated_at'
);
PREPARE add_updated_at FROM @add_updated_at;
EXECUTE add_updated_at;
DEALLOCATE PREPARE add_updated_at;

INSERT INTO products(name, description, category, price, stock)
SELECT 'Gantungan Kunci Akrilik', 'Gantungan kunci akrilik desain pilihan',
       'Gantungan Kunci', 12000, 75
WHERE NOT EXISTS (
  SELECT 1 FROM products WHERE name = 'Gantungan Kunci Akrilik'
);

INSERT INTO products(name, description, category, price, stock)
SELECT 'Pin Akrilik Custom', 'Pin akrilik custom untuk komunitas dan hadiah',
       'Pin', 8000, 100
WHERE NOT EXISTS (
  SELECT 1 FROM products WHERE name = 'Pin Akrilik Custom'
);
