#!/bin/bash
set -e
if [[ ! $(ls -A $PWD_APP/public) ]]; then
    echo "[INFO] New mount volume, move content to directory with persistence"
    echo -e "[INFO] Moving the content"
    rsync -asr --ignore-existing /app/* $PWD_APP  
else
    echo -e "[INFO] Detected Volume with data"
fi

if [ ! -f $PWD_APP/config/database.yml ]; then
    echo "[INFO] Change name of file database.yml.example to database.yml"
    cd $PWD_APP
    cp config/database.yml.example config/database.yml
fi

if [ ! -f $PWD_APP/.env ]; then
    echo "[INFO] Change name of file .env.example to .env"
    cd $PWD_APP
    cp .env.example .env
fi

if [ ! -L $PWD_APP/.rbenv-vars ]; then
    echo "[INFO] Symbolic link of .env with name .rbenv-vars"
    cd $PWD_APP
    ln -s .env .rbenv-vars
fi