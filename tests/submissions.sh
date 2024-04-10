#!/bin/bash
# Submission should should complete and pubsub message should arrive.
buildId=$(echo $RANDOM | md5sum | head -c 8)
topicName="topic_$buildId"
subscriptionName="subscription-$buildId"
if ! gcloud pubsub topics create "$topicName"; then
    echo "Topic $topicName already exists"
fi

if ! gcloud pubsub subscriptions create "$subscriptionName" --topic "$topicName"; then
    echo "Subscription $subscriptionName already exists"
fi

gcloud builds submit . --config cloudbuild.yaml --substitutions "_REPO_TO_CLONE=https://github.com/brianpipeline/test-cloudbuild.git,_REPO_NAME="test-cloudbuild",_REPLY_TOPIC=\"projects/cloud-build-pipeline-396819/topics/$topicName\"" --region=us-central1

message=$(gcloud pubsub subscriptions pull --auto-ack "$subscriptionName" --format='value(message.data)' 2>/dev/null)
gcloud pubsub topics delete "$topicName"
gcloud pubsub subscriptions delete "$subscriptionName"
if [[ $message == "Pipeline succeeded." ]]; then
    echo "Received Message: $message"
else
    exit 1
fi

# Submission should fail and pubsub message should say "pipeline failed".
buildId=$(echo $RANDOM | md5sum | head -c 8)
topicName="topic_$buildId"
subscriptionName="subscription-$buildId"
if ! gcloud pubsub topics create "$topicName"; then
    echo "Topic $topicName already exists"
fi

if ! gcloud pubsub subscriptions create "$subscriptionName" --topic "$topicName"; then
    echo "Subscription $subscriptionName already exists"
fi
gcloud builds submit . --config cloudbuild.yaml --substitutions "_REPO_TO_CLONE=https://github.com/brianpipeline/test-cloudbuild-failure.git,_REPO_NAME="test-cloudbuild-failure",_REPLY_TOPIC=\"projects/cloud-build-pipeline-396819/topics/$topicName\"" --region=us-central1

message=$(gcloud pubsub subscriptions pull --auto-ack "$subscriptionName" --format='value(message.data)' 2>/dev/null)
gcloud pubsub topics delete "$topicName"
gcloud pubsub subscriptions delete "$subscriptionName"
if [[ $message == "Pipeline failed." ]]; then
    echo "Received Message: $message"
else
    exit 1
fi
