#!/bin/bash

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path";

HOST=localhost
PORT=5432
DATABASE=pgsqlplus

ADMIN_NAME=postgres
ADMIN_PASSWORD=postgres

touch .pgpass
echo "$HOST:$PORT:*:$ADMIN_NAME:$ADMIN_PASSWORD" >> .pgpass
chmod 0600 .pgpass
export PGPASSFILE=.pgpass

psql --quiet --host $HOST --port $PORT --username $ADMIN_NAME --file init.sql
psql --quiet --host $HOST --port $PORT --dbname $DATABASE --username $ADMIN_NAME --file install.sql

psql --quiet --host $HOST --port $PORT --dbname $DATABASE --username $ADMIN_NAME --file role.sql
psql --quiet --host $HOST --port $PORT --dbname $DATABASE --username $ADMIN_NAME --file extension.sql

psql --quiet --host $HOST --port $PORT --dbname $DATABASE --username $ADMIN_NAME --file schema.sql
psql --quiet --host $HOST --port $PORT --dbname $DATABASE --username $ADMIN_NAME --file table.sql
psql --quiet --host $HOST --port $PORT --dbname $DATABASE --username $ADMIN_NAME --file column.sql
psql --quiet --host $HOST --port $PORT --dbname $DATABASE --username $ADMIN_NAME --file constraint.sql

psql --quiet --host $HOST --port $PORT --dbname $DATABASE --username $ADMIN_NAME --file domain.sql
psql --quiet --host $HOST --port $PORT --dbname $DATABASE --username $ADMIN_NAME --file collation.sql
psql --quiet --host $HOST --port $PORT --dbname $DATABASE --username $ADMIN_NAME --file tablespace.sql

#psql --quiet --host $HOST --port $PORT --dbname $DATABASE --username $ADMIN_NAME --file delete.sql

#psql --quiet --host $HOST --port $PORT --dbname $DATABASE --username $ADMIN_NAME --file selectObject.sql
#psql --quiet --host $HOST --port $PORT --dbname $DATABASE --username $ADMIN_NAME --file insertObject.sql
#psql --quiet --host $HOST --port $PORT --dbname $DATABASE --username $ADMIN_NAME --file databaseObject.sql

rm .pgpass
