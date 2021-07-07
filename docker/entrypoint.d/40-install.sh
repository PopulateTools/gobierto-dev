#!/bin/bash
set -e

cd $PWD_APP
echo -e "[INFO] Recovery gems"
$PWD_APP/bin/bundle install --binstubs=$PWD_APP/bin --gemfile=$PWD_APP/Gemfile --path=$PWD_APP

echo -e "[INFO] Check health of keys"
$PWD_APP/bin/i18n-tasks normalize
$PWD_APP/bin/i18n-tasks health
