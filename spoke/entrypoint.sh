#!/bin/bash
set -e

DB_USER=${DB_USER:-tempuser}
DB_PASS=${DB_PASS:-`date | md5sum | head -c10`}
DB_NAME=${DB_NAME:-tempdb}
SETUP_DB_COMMANDS=${SETUP_DB_COMMANDS:-/config/postgresql/setupdb}
PG_BIN=/usr/lib/postgresql/9.3/bin
INIT_DB=$PG_BIN/initdb
PG_CMD=$PG_BIN/postgres
PG_TERM=/usr/bin/psql
CONF=/config/postgresql/postgresql.conf
ERR_LOG=${ERR_LOG:-"/log/$HOSTNAME/postgresql_stderr.log"}
# postgres reads this implicitly
export PGDATA=${PGDATA:-/data/dbdata}

postgres_run() {
    su postgres sh -c "$@"
}

# create dirs if needed
mkdir -p $PGDATA
postgres_run "mkdir -p -m 775 /var/run/postgresql"

# initialize db if needed
if [ ! "`ls -A $PGDATA`" ] ; then
    chmod 700 $PGDATA
    chown -R postgres $PGDATA
    postgres_run "$INIT_DB $PGDATA" | tee -a $ERR_LOG

    # first-run db and owner setup
    postgres_run "$PG_BIN/pg_ctl start"
    sleep 2s
    echo "Setting up table..." | tee -a $ERR_LOG
    postgres_run "createdb --template=template0 -e $DB_NAME"
    postgres_run "$PG_BIN/pg_ctl stop" | tee -a $ERR_LOG
    sleep 2s

    echo "Running items from setupdb file..." | tee -a $ERR_LOG
    SETUP_COMMANDS=$(echo $(cat "$SETUP_DB_COMMANDS"))
    postgres_run "$PG_CMD --single -c config_file=$CONF" <<< "$(eval echo $SETUP_COMMANDS)" | tee -a $ERR_LOG
    sleep 2s

    # Info
    echo -e "Starting Postgres...\nInfo:\n  Username: $DB_USER\n  Password: $DB_PASS\n  Database: $DB_NAME" | tee -a $ERR_LOG
fi

# Run
exec su postgres sh -c "$PG_CMD -c config_file=$CONF"
