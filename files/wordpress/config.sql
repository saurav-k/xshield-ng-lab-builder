CREATE DATABASE wordpress_db;
CREATE USER wordpress_user@'%' IDENTIFIED BY '{PASSWORD}';
GRANT ALL ON wordpress_db.* TO wordpress_user@'%';
