CREATE DATABASE IF NOT EXISTS merchandise_db;
USE merchandise_db;
CREATE TABLE IF NOT EXISTS products(id INT AUTO_INCREMENT PRIMARY KEY,name VARCHAR(150) NOT NULL,description TEXT NOT NULL,category VARCHAR(80) NOT NULL,price INT UNSIGNED NOT NULL,stock INT UNSIGNED NOT NULL DEFAULT 0,image_url VARCHAR(500) NULL,created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE IF NOT EXISTS orders(id INT AUTO_INCREMENT PRIMARY KEY,customer_name VARCHAR(150) NOT NULL,email VARCHAR(190) NOT NULL,phone VARCHAR(40) NOT NULL,address TEXT NOT NULL,items JSON NOT NULL,total INT UNSIGNED NOT NULL,status VARCHAR(30) DEFAULT 'Menunggu',created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO products(name,description,category,price,stock) VALUES('Pin Akrilik Custom','Pin custom untuk komunitas dan hadiah','Pin',8000,100),('Gantungan Kunci Akrilik','Gantungan kunci akrilik desain pilihan','Gantungan Kunci',12000,75),('Sticker Pack','Paket stiker merchandise','Stiker',10000,120);
