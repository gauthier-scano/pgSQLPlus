#!/bin/bash

echo "Creating source..."
cat src/complain.sql src/system/table.sql src/system/table_config.sql src/system/user.sql src/common.sql src/database/tablespace.sql src/database/role.sql src/database/collation.sql src/database/domain.sql src/database/extension.sql src/database/schema.sql src/database/table.sql src/database/column.sql src/database/constraint.sql src/database/index.sql src/manage/history.sql src/manage/mask.sql src/manage/delete.sql src/manage/right.sql src/variable/variable.sql src/variable/delete.sql src/variable/history.sql src/variable/mask.sql src/variable/right.sql src/object/databaseObject.sql src/object/selectObject.sql src/object/insertObject.sql src/object/insertObject_str.sql > ./ext/pgSQLPlus--1.0.sql

echo "Installing files..."
cp ext/pgSQLPlus.control "C:/Program Files/PostgreSQL/10/share/extension/pgsqlplus.control"
cp ext/pgSQLPlus--1.0.sql "C:/Program Files/PostgreSQL/10/share/extension/pgsqlplus--1.0.sql"
#make -f Makefile

while test $# -gt 0; do
	case "$1" in
		-t|-test)
			echo "Deleting test database..."
			bash tst/retreat.sh
			
			echo "Running test..."
			bash tst/process.sh
			
			exit 0
		;;
	esac
done

echo "Done."
