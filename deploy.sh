#!/usr/bin/env bash

echo 'Install dependencies...'
docker run -v `pwd`:`pwd` -w `pwd` -i -t lambci/lambda:build-ruby2.5 bundle install --without development test --deployment
cp -rf .bundle/ app
cp -rf vendor app

echo 'Packaging...'
sam package --template-file template.yaml --output-template-file packaged.yaml --s3-bucket mpevec-lambda-pkgs

echo 'Deploying...'
sam deploy --template-file packaged.yaml --capabilities CAPABILITY_IAM --stack-name telegram-news-bot
