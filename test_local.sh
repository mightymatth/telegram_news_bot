#!/usr/bin/env bash

echo 'Install dependency layer'
docker run -v `pwd`:`pwd` -w `pwd` -i -t lambci/lambda:build-ruby2.5 bundle install --without development test --path vendor/bundle
mkdir -p dependencies/ruby/gems
cp -rf vendor/bundle/ruby/ dependencies/ruby/gems

echo 'Starting SAM local start-api'
sam local start-api --debug
