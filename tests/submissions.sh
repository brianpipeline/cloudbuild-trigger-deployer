#!/bin/bash

topicName="cloudbuild-trigger-deployer-test"
subscription_name="test-subscription"
if ! gcloud pubsub topics create "$topicName"; then
    echo "Topic $topicName already exists"
fi

if ! gcloud pubsub subscriptions create "$subscription_name" --topic "$topicName"; then
    echo "Subscription $subscription_name already exists"
fi

gcloud builds submit . --config cloudbuild.yaml --substitutions "_REPO_TO_CLONE=https://github.com/brianpipeline/test-cloudbuild.git,_REPO_NAME="test-cloudbuild",_REPLY_TOPIC=\"projects/cloud-build-pipeline-396819/topics/$topicName\"" --region=us-central1

message=$(gcloud pubsub subscriptions pull --auto-ack "$subscription_name" --format='value(message.data)' 2>/dev/null)
if [[ -n $message ]]; then
    echo "Received Message: $message"
    exit 0
else
    exit 1
fi
