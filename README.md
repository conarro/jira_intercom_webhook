# JIRA / Intercom Webhook

_A Ruby-based web service to connect JIRA tickets and Intercom conversations_

## How it works

1. Deploy this web service (Heroku is an easy platform)
2. Add the newly deployed web service as a webhook in your JIRA instance ([docs](https://developer.atlassian.com/jiradev/jira-apis/webhooks#Webhooks-jiraadmin))
3. Include any Intercom conversation URLs in your JIRA issue descriptions and a private note will be added on the Intercom side

Once configured, this webhook will add a private note to any Intercom conversation linked to in a JIRA issue description.

### Configuration

Set the following environment variables:

```
# ID of your application in Intercom
INTERCOM_APP_ID

# API key for your Intercom account
INTERCOM_API_KEY

# notes added by the webhook will be attributed to this user in Intercom
INTERCOM_ADMIN_ID

# hostname for your JIRA instance e.g. companyxyz.atlassian.net
JIRA_HOSTNAME
```

