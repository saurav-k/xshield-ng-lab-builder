#!/bin/bash
set -x

# Update packages and install necessary dependencies
apt-get update
apt-get install -y mysql-client php wget

# Define variables
DB_ENDPOINT=${db_endpoint}      # RDS Aurora endpoint
DB_PORT=${db_port}              # RDS port (default is 3306)
DB_NAME=${db_name}              # Database name
DB_USERNAME=${db_username}      # Database username
DB_PASSWORD=${db_password}      # Database password
crm_password=${crm_password}    # CRM admin password
# Download SQL files from public URLs (or from S3 if needed)
wget https://ct-xshield-lab-assets.s3.amazonaws.com/crm/suitecrm.sql -O /tmp/suitecrm.sql
wget https://ct-xshield-lab-assets.s3.amazonaws.com/crm/user.sql -O /tmp/user.sql
wget https://ct-xshield-lab-assets.s3.amazonaws.com/crm/hash.php -O /tmp/hash.php

# Replace the placeholder password in user.sql with the actual CRM password
sed -i "s/crm_password/${crm_password}/" /tmp/user.sql

# Generate hashed password using PHP and insert it into suitecrm.sql
export CRM_HASHED_PASSWORD=$(php /tmp/hash.php "${crm_password}")
sed -i "s|admin_password_hash|$CRM_HASHED_PASSWORD|" /tmp/suitecrm.sql

# Connect to the RDS Aurora MySQL instance and run the SQL scripts
mysql --host=$DB_ENDPOINT --port=$DB_PORT --user=$DB_USERNAME --password=$DB_PASSWORD <<EOF
  -- Create user and database schema
  source /tmp/user.sql;
  source /tmp/suitecrm.sql;
  FLUSH PRIVILEGES;
EOF

# Remove the SQL files after the setup (optional)
rm /tmp/suitecrm.sql /tmp/user.sql /tmp/hash.php

# Continue with other application startup tasks (e.g., starting services)
# Start application or any additional steps here

echo "Database setup completed and application is ready."
