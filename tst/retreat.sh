#!/bin/bash

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path";

HOST=localhost
PORT=5432

ADMIN_NAME=postgres
ADMIN_PASSWORD=postgres

touch .pgpass
echo "$HOST:$PORT:*:$ADMIN_NAME:$ADMIN_PASSWORD" >> .pgpass
chmod 0600 .pgpass
export PGPASSFILE=.pgpass

psql --quiet --host $HOST --port $PORT --username $ADMIN_NAME -d template1 --file uninstall.sql

rm .pgpass
