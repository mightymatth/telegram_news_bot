#!/usr/bin/env bash

if [[ -z "$AWS_STACK_NAME" ]]; then
  echo "Variable \$AWS_STACK_NAME is mandatory. (e.g. 'telegram-news-bot')"
  exit 2
fi

if [[ -z "$S3_BUCKET_NAME" ]]; then
  echo "Variable \$S3_BUCKET_NAME is mandatory. Please provide name of bucket where \
packages will be stored (e.g. 'myname-lambda-packages')."
  exit 2
fi


echo 'Install dependency layer'
docker run -v `pwd`:`pwd` -w `pwd` -i -t lambci/lambda:build-ruby2.5 bundle install \
           --without development test --path vendor/bundle
mkdir -p dependencies/ruby/gems
cp -rf vendor/bundle/ruby/ dependencies/ruby/gems

echo 'Packaging...'
sam package --template-file template.yaml --output-template-file packaged.yaml --s3-bucket "$S3_BUCKET_NAME"

echo 'Deploying...'
sam deploy --template-file packaged.yaml --capabilities CAPABILITY_IAM --stack-name "$AWS_STACK_NAME"

echo 'API endpoint for Webhook'
aws cloudformation describe-stacks --stack-name "$AWS_STACK_NAME" \
                                   --query 'Stacks[].Outputs[?OutputKey==`WebhookApi`]' \
                                   --output text | awk '{print $NF}'
