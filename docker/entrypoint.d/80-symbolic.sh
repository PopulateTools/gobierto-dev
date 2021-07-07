#!/bin/bash

export SECRET_KEY_BASE=$(rake secret)
export ROLLBAR_ACCESS_TOKEN=$(rake secret)
echo -e "[INFO] Execute Pre-Webpack"
yarn install

if [[ ! -f $PWD_APP/node_modules/css-loader/index.js ]]; then
  if [[ $RAILS_ENV == "production" ]]; then
      $PWD_APP/bin/webpack --verbose --mode production --config /gobierto/config/webpack/production.js
  else
      $PWD_APP/bin/webpack --verbose
  fi
fi

if [[ ! $(stat $PWD_APP/app/javascript/packs/custom_fields_data_grid_plugin.js | grep -o 'symbolic link') ]]; then
    echo -e "[INFO] Create symbolic link $PWD_APP/vendor/gobierto_engines/custom-fields-data-grid-plugin"
    ln -s \
      $PWD_APP/vendor/gobierto_engines/custom-fields-data-grid-plugin/app/javascripts/packs/custom_fields_data_grid_plugin.js \
      $PWD_APP/app/javascript/packs
    ln -s \
      $PWD_APP/vendor/gobierto_engines/custom-fields-data-grid-plugin/app/javascripts/custom_fields_data_grid_plugin \
      $PWD_APP/app/javascript
fi

if [[ ! $(stat $PWD_APP/app/javascript/packs/custom_fields_progress_plugin.js | grep -o 'symbolic link') ]]; then
    echo -e "[INFO] Create symbolic link $PWD_APP/vendor/gobierto_engines/custom-fields-progress-plugin"
    ln -s \
      $PWD_APP/vendor/gobierto_engines/custom-fields-progress-plugin/app/javascripts/packs/custom_fields_progress_plugin.js \
      $PWD_APP/app/javascript/packs
    ln -s \
      $PWD_APP/vendor/gobierto_engines/custom-fields-progress-plugin/app/javascripts/custom_fields_progress_plugin \
      $PWD_APP/app/javascript
fi

if [[ ! $(stat $PWD_APP/app/javascript/packs/custom_fields_table_plugin.js | grep -o 'symbolic link') ]]; then
    echo -e "[INFO] Create symbolic link $PWD_APP/vendor/gobierto_engines/custom-fields-table-plugin"
    ln -s \
      $PWD_APP/vendor/gobierto_engines/custom-fields-table-plugin/app/javascripts/packs/custom_fields_table_plugin.js \
      $PWD_APP/app/javascript/packs
    ln -s \
      $PWD_APP/vendor/gobierto_engines/custom-fields-table-plugin/app/javascripts/custom_fields_table_plugin \
      $PWD_APP/app/javascript
fi

if [[ ! $(stat $PWD_APP/node_modules | grep -o 'symbolic link') ]]; then
    echo -e "[INFO] Create symbolic link of all modules from gobierto_engines and i18n"
    ln -F -s \
      $PWD_APP/vendor/gobierto_engines/ \
      $PWD_APP/node_modules
    ln -s \
      $PWD_APP/ruby/2.7.0/gems/i18n-js-3.7.1/app/assets/javascripts/i18n/ \
      $PWD_APP/app/javascript/lib/i18n/modules
fi
