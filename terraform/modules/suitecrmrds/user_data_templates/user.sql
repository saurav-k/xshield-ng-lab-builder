CREATE USER crm_admin@'%' IDENTIFIED BY 'crm_password';
GRANT ALL PRIVILEGES ON suitecrm.* TO crm_admin@'%';
FLUSH PRIVILEGES;
