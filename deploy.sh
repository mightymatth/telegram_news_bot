#!/usr/bin/env bash

echo 'Install dependency layer'
docker run -v `pwd`:`pwd` -w `pwd` -i -t lambci/lambda:build-ruby2.5 bundle install --without development test --path vendor/bundle
mkdir -p dependencies/ruby/gems
cp -r vendor/bundle/ruby/ dependencies/ruby/gems

echo 'Packaging...'
sam package --template-file template.yaml --output-template-file packaged.yaml --s3-bucket mpevec-lambda-pkgs

echo 'Deploying...'
sam deploy --template-file packaged.yaml --capabilities CAPABILITY_IAM --stack-name telegram-news-bot

echo 'Cleaning up...'
rm -rf dependencies

echo 'API endpoint for Webhook'
aws cloudformation describe-stacks --stack-name telegram-news-bot --query 'Stacks[].Outputs[?OutputKey==`WebhookApi`]' --output text | awk '{print $NF}'
