-- Run with env-substitution so secrets stay out of the file, e.g.:
--   envsubst < /sql/init.sql | mysql -h${DB_HOST} -u${ADMIN_USER} -p${ADMIN_PASSWORD} ${MYSQL_DATABASE}
-- Assumes ADMIN_USER is the master user; MYSQL_USER/MYSQL_PASSWORD come from Secrets Manager; MYSQL_DATABASE via env/var.

CREATE DATABASE IF NOT EXISTS `${MYSQL_DATABASE}`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${MYSQL_PASSWORD}';
-- Ensure plugin/password even if user exists
ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED WITH mysql_native_password BY '${MYSQL_PASSWORD}';

-- Grant privileges on this DB
GRANT ALL PRIVILEGES ON `${MYSQL_DATABASE}`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;

-- Ensure session charset
SET NAMES 'utf8mb4';
