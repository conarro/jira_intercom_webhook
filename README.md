# JIRA / Intercom Webhook

_A Ruby-based web service to connect JIRA tickets and Intercom conversations_

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

## How it works

1. Deploy this web service (Heroku is an easy platform)
2. Add the newly deployed web service as a webhook in your JIRA instance ([docs](https://developer.atlassian.com/jiradev/jira-apis/webhooks#Webhooks-jiraadmin))
3. Include any Intercom conversation URLs in your JIRA issue descriptions and a private note will be added on the Intercom side

This app works by:

* Listening for `jira:issue_created` and `jira:issue_updated` events
* Detecting Intercom links in the issue's description and in a comment body
* Looking up the linked Intercom conversation and checking if the issue link exists
* If not, adding a private note with a link to the JIRA issue
* If so, and a comment was created, adding a private note with the new comment

### Configuration

#### When creating the Heroku app:

* Set the following environment variables:

```
# API key for your Intercom account
INTERCOM_API_KEY

# notes added by the webhook will be attributed to this user in Intercom
INTERCOM_ADMIN_ID

# hostname for your JIRA instance e.g. companyxyz.atlassian.net
JIRA_HOSTNAME
```

* And the following environment variables will be set automatically to random strings of characters:

```
# username used for HTTP Basic Auth
APP_USERNAME

# password used for HTTP Basic Auth
APP_PASSWORD
```

#### After creating Heroku app
* Copy the auto-generated values for APP_USERNAME and APP_PASSWORD from within the Heroku app's settings (under 'Config Vars')
  https://devcenter.heroku.com/articles/config-vars#setting-up-config-vars-for-a-deployed-application

* In JIRA, set the webhook endpoint to `https://YOUR_APP_USERNAME:YOUR_APP_PASSWORD@your-app.herokuapp.com/jira_to_intercom`, where YOUR_APP_USERNAME is the value of the `APP_USERNAME` var, and YOUR_APP_PASSWORD is the value of the `APP_PASSWORD` var
