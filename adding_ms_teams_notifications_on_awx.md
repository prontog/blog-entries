At the point of writing this post,[AWX](https://github.com/ansible/awx) does not support MS Teams notifications out of the box. You need to add a custom *webhook* notification.

Up until the mid of 2024, the way to create a *webhook* in MS Teams was by adding a connector. Then Microsoft [announced](https://devblogs.microsoft.com/microsoft365dev/retirement-of-office-365-connectors-within-microsoft-teams/) the replacement of *Connectors* with the new *Workflows*. From the viewpoint of AWX, the change is simple, instead of using a `MessageCard` we need to use an `AdaptiveCard`...

In the following sections we will create an MS Teams Webhook and configure AWX to post notifications to it. As a bonus, we will configure the Webhook so that it can post to any channel you want. This can be very handy if you have a separate channel for each of your environments.

## Create a Microsoft Teams Webhook for AWX

1. Create a new flow in MS Teams:
  - Log in to MS Teams using a dedicated account. You can use your personal account but transferring of the Workflow ownership might not be possible from your plan. Note that you can be logged in using multiple accounts on Teams and then switch to the one you want to use.
  - From the apps on the left, select **Workflows**.
  - Click on **+ New flow**.
  - Select the **Post to a channel when a webhook request is received** template.
  - Name your flow (e.g., **"AWX Webhook"**) and click **Next**.
  - Choose a Teams and Channel. This is not important because later on we will override this with and dynamic param. Click on **Create flow**.
  - Click **Done**. No need to copy the webghook yet. We will do it from *Power Automate*.
  - If you did not use your personal account, add yourself as a co-owner of the flow by selecting the flow and then clicking on **Share**.
2. Copy the webhook URL:
  - Go to [Power Automate](https://make.microsoft.com/).
  - The new flow will be in either the **Cloud flows** or the **Shared with me** tab. Select it.
  - Click **Edit** on the top left. This will show the actual steps of the flow.
  - After selecting **When a Teams webhook request is received**, you'll see **HTTP URL"** field, copy the URL. This is the actual webhook URL.
  - AWX will use this webhook to POST notifications such as:
    ```json
    {
      "teamID": "12345",
      "channel": "12345.tacv2",
      "text": "Job Status: Success",
      "color": "good",
      "url": "https://awx-hostname/jobid"
    }
    ```
    More on these values later.
3. Delete the **Send each adaptive card** step.
4. Add "Parse JSON" Action:
  - After the trigger (the first step), click **+**, and search for **"Parse JSON"**.
  - Select **"Parse JSON"** from the actions list.
  - For the **Content** field, use the dynamic content from the **Teams Webhook to Adaptive Card** trigger (use **`Body`** from the trigger).
  - In the **Schema** field, **click on "Use sample payload to generate schema"**, and paste the following sample JSON:
    ```json
    {
      "type": "object",
      "properties": {
          "teamId": {
            "type": "string"
          },
          "channelId": {
            "type": "string"
          },
          "text": {
            "type": "string"
          },
          "color": {
            "type": "string"
          },
          "url": {
            "type": "string"
          }
      }
    }
    ```
5. Post Adaptive Card in a Chat or Channel:
  - After parsing the JSON, click **+** to add the action *"Post card in a chat or channel"*.
  - In the *"Post as"* field, enter *"User"*.
  - In the *"Post in"* field, enter *"Channel"*.
  - In the *"Team"* field, enter `@{triggerBody()?['teamId']}`.
  - In the *"Channel"* field, enter `@{body('Parse_JSON')?['channelId']}`.
  - In the *"Adaptive Card"* field, create the Adaptive Card JSON. Here’s an example of what the Adaptive Card could look like:
    ```json
    {
      "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
      "type": "AdaptiveCard",
      "version": "1.2",
      "body": [
        {
          "type": "TextBlock",
          "text": "@{triggerBody()?['text']}",
          "wrap": true,
          "color": "@{triggerBody()?['color']}"
        }
      ],
      "actions": [
        {
          "type": "Action.OpenUrl",
          "title": "View on AWX",
          "url": "@{triggerBody()?['url']}",
          "role": "button"
        }
      ]
    }
    ```
6. Save the flow

## Configure AWX to use the new Webhook

You probably have noticed the `teamId`, `channelId` in the JSON schema. These are important if we want to reuse the same *webhook* and send to different *MS Teams* channels. In the following steps you will need to replace:
  - `THE_TEAM_ID` with the ID of the team. You can get it from the link to the team. Look for the groupId param.
  - `THE_CHANNEL_ID` with the ID of the channel you just created. You can get it from the link to the channel. Look for part ending with "tacv2".

Let's configure AWX:
1. Add a new notification, fill out the name, description and organization. Then for the rest of the fields:
  - *Notification Type*: Webhook
  - *Target URL*: the webhook URL from step 2 of the previous section
  - *HTTP Method*: POST
  - *HTTP Headers*: `{"content-type":"application/json"}`
  - Enable “Customize messages…”
  - *Start message body*:
    ```json
    {
      "teamId": "THE_TEAM_ID",
      "channelId": "THE_CHANNEL_ID",
      "text": "{{ job.status }} {{ job_friendly_name }} #{{ job.id }} '{{ job.name }}'",
      "color": "default",
      "url": "{{ url }}"
    }
    ```
  - *Success message body*:
    ```json
    {
      "teamId": "THE_TEAM_ID",
      "channelId": "THE_CHANNEL_ID",
      "text": "{{ job.status }} {{ job_friendly_name }} #{{ job.id }} '{{ job.name }}'",
      "color": "good",
      "url": "{{ url }}"
    }
    ```
  - *Error message body*:
    ```json
    {
      "teamId": "THE_TEAM_ID",
      "channelId": "THE_CHANNEL_ID",
      "text": "{{ job.status }} {{ job_friendly_name }} #{{ job.id }} '{{ job.name }}'",
      "color": "attention",
      "url": "{{ url }}"
    }
    ```
2. Test the new notification by clicking the bell...

## Troubleshooting your workflow

If the new notification does not work:
  - Go to [Power Automate](https://make.microsoft.com/).
  - Select *My flows*.
  - The flow will be in either the **Cloud flows** or the **Shared with me** tab. Select it.
  - Scroll down to see the *run history*.
  - Select the latest entry with *Status* failed.
  - Click on the failed action.
  - Good luck examining what went wrong... :)

## Useful links

- [Microsoft Teams Webhook](https://learn.microsoft.com/en-us/connectors/teams/?tabs=text1%2Cdotnet#microsoft-teams-webhook)
- [MS Teams Adaptive Card](https://adaptivecards.io/explorer/AdaptiveCard.html)
- [Create incoming webhooks with Workflows for Microsoft Teams](https://support.microsoft.com/en-us/office/create-incoming-webhooks-with-workflows-for-microsoft-teams-8ae491c7-0394-4861-ba59-055e33f75498)
