#!/bin/bash
set -e

# Tunable settings
DB_USER=${DB_USER:-tempuser}
DB_PASS=${DB_PASS:-`date | md5sum | head -c10`}
DB_NAME=${DB_NAME:-tempdb}
DB_DIR=${DB_DIR:-/data/dbdata}
SETUP_DB_COMMANDS=${SETUP_DB_COMMANDS:-/config/postgresql/setupdb}

# Misc settings
CONF=/config/postgresql/postgresql.conf
PG_BIN=/usr/lib/postgresql/9.3/bin
PG_TERM=/usr/bin/psql
INIT_DB=$PG_BIN/initdb
PG_CMD=$PG_BIN/postgres
ERR_LOG=/log/$HOSTNAME/postgresql_stderr.log

# Postgres reads this implicitly. Location of configuration files.
export PGDATA=/config/postgresql

postgres_run() {
    su postgres sh -c "$@"
}

# create dirs if needed
mkdir -p $DB_DIR
postgres_run "mkdir -p -m 775 /var/run/postgresql"

# initialize db if needed
if [ ! "`ls -A $DB_DIR`" ] ; then
    chmod 700 $DB_DIR
    chown -R postgres $DB_DIR
    postgres_run "$INIT_DB $DB_DIR" | tee -a $ERR_LOG

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
    echo -e "Starting Postgres...\nInfo:\n  Username: $DB_USER\n  Password: $DB_PASS\n  Database: $DB_NAME\n  Location: $DB_DIR" | tee -a $ERR_LOG
fi

# Run
exec su postgres sh -c "$PG_CMD"
