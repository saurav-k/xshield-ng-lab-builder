CREATE USER hrms_user@'%' IDENTIFIED BY 'hrm_password';
GRANT ALL ON hrms.* TO hrms_user@'%';
CREATE DATABASE hrms;
