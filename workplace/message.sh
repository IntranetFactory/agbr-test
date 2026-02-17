#!/bin/bash
# Message script
# Sends a message to Discord webhook via Slack compatibility
if [ -z "$1" ]; then
    echo "Usage: $0 <message>"
    exit 1
fi

MESSAGE="$1"
HOSTNAME=$(uname -n)
WEBHOOK_URL="https://discord.com/api/webhooks/1473425995670229099/XbovgO2T-GYC_RcuBRcXXMG5yroKNJo6pLtzrAVXTGl6OWex04q1vDCJBX04u6GjB4I5/slack"

# Send message to Discord webhook using Slack-compatible format
curl -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"text\": \"[$HOSTNAME] $MESSAGE\"}" \
    --silent --show-error

if [ $? -eq 0 ]; then
    echo "Message sent successfully"
else
    echo "Failed to send message"
    exit 1
fi
