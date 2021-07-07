#!/bin/bash
set -x

echo "[INFO] Wait server PostgreSQL"
END=25
for i in $(seq 1 $END); do
	echo "  Try connect to PostgreSQL, num $i..."
	if PGPASSWORD=$PG_PASSWORD psql --username=$PG_USERNAME --host=$PG_HOST \
      --dbname=postgres --command='SELECT now()'; then
		echo "[INFO] Postgres working!"
		break
	fi
	sleep 4
done
