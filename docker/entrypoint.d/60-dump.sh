#!/bin/bash

# Reference: config/database.yml
if [ "$RAILS_ENV" == "development" ]; then
    PG_DATABASE="gobierto_development"
elif [ "$RAILS_ENV" == "test" ]; then
    PG_DATABASE="gobierto_test"
elif [ "$RAILS_ENV" == "staging" ]; then
    PG_DATABASE="gobierto_staging"
else
    PG_DATABASE="gobierto_production"
fi

# Check PostgreSQL
if PGPASSWORD=$PG_PASSWORD psql -h $PG_HOST -U $PG_USERNAME -d postgres -c '\q'; then
    echo -e "[INFO] Check Database: Ready"

    PG_DATABASE_CHECK=$(PGPASSWORD=$PG_PASSWORD psql -t -h $PG_HOST -U $PG_USERNAME \
      -d postgres \
      -c "SELECT datname FROM pg_database WHERE datname='$PG_DATABASE';")

    # If not exist database and file .create-finish execute setup
    if [ $( echo "$PG_DATABASE_CHECK" | grep -o "$PG_DATABASE" ) ]; then
        echo -e "[INFO] Database found: $PG_DATABASE, will not create database PostgreSQL and ElastickSearch"
    else
        echo -e "[INFO] Create database $PG_DATABASE"
        set -e
        echo -e "[INFO] Setup database PostgreSQL"
        cd $PWD_APP
        $PWD_APP/bin/rails db:setup
        
        echo -e "[INFO] Setup database ElastickSearch"
        $PWD_APP/bin/rails gobierto_budgets:elastic_search_schemas:manage:reset
        $PWD_APP/bin/rails gobierto_budgets:elastic_search_schemas:manage:create
        $PWD_APP/bin/rails gobierto_budgets:fixtures:load
        echo '::BudgetsSeeder.seed!' | $PWD_APP/bin/rails c
        touch $PWD_APP/db/.create-finish
        set +e
    fi

else
    echo -e "[WARNING] Check Database: Not ready"
fi
