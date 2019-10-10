# Telegram News Bot

### Deploy application to AWS

* install `aws cli` and `sam` cli,
* set credentials and region via `aws cli` ([guide](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html)),
* create `.env` file from `.env.example` file and modify it for your needs.

#### Import parameters

Run task for importing parameters from `.env` file to SSM Parameter Store.

`rake reimport_params NAMESPACE=<stack-name>`

* NAMESPACE - string that matches stack name provided in deploy script ($AWS_STACK_NAME, see below).

#### Deployment

* run deployment script:
```
AWS_STACK_NAME=<stack-name> S3_BUCKET_NAME=<bucket-name> ./deploy.sh
```

* AWS_STACK_NAME - string (kebab-case); value that matches namespace from SSM Parameter Store,
* S3_BUCKET_NAME - string (kebab-case); previously created S3 bucket name that will hold artifacts.

#### Attach Telegram Webhook

After deployment, you will get `WEBHOOK_URL`. Go to Telegram, message [**BotFather**](https://t.me/BotFather) to get `TELEGRAM_BOT_TOKEN`. Change the URL provided below to fit the parameters and paste it in your browser.

```
GET https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/setWebhook?url=<WEBHOOK_URL>
```


### Serverless setup locally

* install ngrok (`npm install -g ngrok`), create an account and login
* create ngrok tunnel to port 3000
    * `ngrok http 3000`
    * copy tunnel link (e.g. `https://b26b43ce.ngrok.io`) as it will be your `WEBHOOK_URL`
* attach Telegram webhook to your bot as described above
* run script to try serverless setup locally `./test_local.sh`


### Local development

For local development we don't need to use serverless stack.

* delete Telegram Webhook:

```
GET https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/deleteWebhook
```

* run script:
```
ruby polling_dev.rb
```

* for stopping the script, press `CMD/CTRL + Z` to suspend and run:
```
ps -A | grep polling_dev.rb | awk '{print $1}' | xargs kill -KILL 
```
