#!/bin/bash
# Runs once, on the first start of an empty MySQL volume.
# One database and one user per service; no service can read another's tables.
set -euo pipefail

create() {
  local db="$1" password="$2"
  mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<SQL
CREATE DATABASE IF NOT EXISTS \`$db\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$db'@'%' IDENTIFIED BY '$password';
GRANT ALL PRIVILEGES ON \`$db\`.* TO '$db'@'%';
SQL
}

create famexus_gateway  "$GATEWAY_DB_PASSWORD"
create famexus_todo     "$TODO_DB_PASSWORD"
create famexus_calendar "$CALENDAR_DB_PASSWORD"
create wallit           "$WALLIT_DB_PASSWORD"

mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"
