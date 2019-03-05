# Telegram News Bot

### Deploy application to AWS

* set credentials ang region via `aws cli` ([guide](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/setup-credentials.html))
* in deployment script (`deploy.sh`), change `--s3-bucket` option of `sam package` to point to your own bucket
* from `template.example.yaml` create `template.yaml` and configure `Resources>TelegramNewsBotHandler>Properties>Environment>Variables` list with correct values 
* run deployment script:
```
./deploy.sh
```

### Attach Telegram Webhook
```
GET https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/setWebhook?url=<WEBHOOK_URL>
```

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
