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
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('customer', 'admin') NOT NULL DEFAULT 'customer',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SET @add_user_role = (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE users ADD COLUMN role ENUM(''customer'', ''admin'') NOT NULL DEFAULT ''customer''',
    'SELECT 1'
  )
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'users'
    AND column_name = 'role'
);
PREPARE add_user_role FROM @add_user_role;
EXECUTE add_user_role;
DEALLOCATE PREPARE add_user_role;

SET @add_is_published = (
  SELECT IF(
    COUNT(*) = 0,
    'ALTER TABLE products ADD COLUMN is_published TINYINT(1) NOT NULL DEFAULT 1',
    'SELECT 1'
  )
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'products'
    AND column_name = 'is_published'
);
PREPARE add_is_published FROM @add_is_published;
EXECUTE add_is_published;
DEALLOCATE PREPARE add_is_published;

CREATE TABLE IF NOT EXISTS orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  product_id INT NULL,
  product_name VARCHAR(150) NOT NULL,
  quantity INT UNSIGNED NOT NULL,
  unit_price INT UNSIGNED NOT NULL,
  total_price BIGINT UNSIGNED NOT NULL,
  status ENUM('pending', 'confirmed', 'cancelled') NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT orders_user_fk FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT orders_product_fk FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS product_requests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(190) NOT NULL,
  product_name VARCHAR(150) NOT NULL,
  message TEXT NOT NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT product_requests_user_fk FOREIGN KEY (user_id) REFERENCES users(id)
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

INSERT INTO products (name, description, category, price, stock, image_url)
SELECT 'Nikolas Rendl (Pyromaniac) Lenticular Acrylic Pendant',
       'Gantungan Kunci Akrilik custom', 'Gantungan Kunci', 8000, 100,
       'https://res.cloudinary.com/exb1ugol/image/upload/f_auto/q_auto/combined-image_3.jpg'
WHERE NOT EXISTS (
  SELECT 1 FROM products
  WHERE name = 'Nikolas Rendl (Pyromaniac) Lenticular Acrylic Pendant'
);

INSERT INTO products (name, description, category, price, stock, image_url)
SELECT 'Uzi Doorman (Murder Drones) Plush Badge Mirror Keychains',
       'Gantungan Kunci Plush custom', 'Gantungan Kunci', 12000, 100,
       'https://res.cloudinary.com/exb1ugol/image/upload/f_auto/q_auto/combined-image_2.jpg'
WHERE NOT EXISTS (
  SELECT 1 FROM products
  WHERE name = 'Uzi Doorman (Murder Drones) Plush Badge Mirror Keychains'
);

SELECT * FROM products ORDER BY id ASC;
