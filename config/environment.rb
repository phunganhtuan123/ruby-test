# frozen_string_literal: true

# Define App Environment
APP_ENVIRONMENT = {
  development: 'development',
  staging: 'staging',
  production: 'production',
  test: 'test'
}.freeze

# set default application environment
ENV['RACK_ENV'] ||= 'development'
RACK_ENV = ENV['RACK_ENV']

$_PROD_ENV = RACK_ENV == APP_ENVIRONMENT[:production]
$_STAG_ENV = RACK_ENV == APP_ENVIRONMENT[:staging]
$_DEV_ENV = RACK_ENV == APP_ENVIRONMENT[:development]
$_TEST_ENV = RACK_ENV == APP_ENVIRONMENT[:test]
