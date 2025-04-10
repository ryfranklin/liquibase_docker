#!/bin/bash
set -e

# set environment variables
set -o allexport
source .env
set +o allexport
 

# generate the liquibase.properties file
echo "Generating liquibase.properties from .env"
envsubst < liquibase/liquibase.properties.template > liquibase/liquibase.properties
exec "$@"

# # build the liquibase image
# echo "Building liquibase image"
# docker build -t liquibase-mysql .

# # start the docker compose
# echo "Starting docker compose"
# docker compose up --build

