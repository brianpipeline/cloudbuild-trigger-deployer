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

gcloud builds submit . --config cloudbuild.yaml --substitutions "_GIT_CLONE_URL=https://github.com/brianpipeline/test-cloudbuild.git,_GIT_REPOSITORY_NAME="test-cloudbuild",_GIT_REF="refs/heads/main",_GIT_HEAD_SHA="d4828ea0e1bca17e8f6a4cc387d5bbaf33714566",_REPLY_TOPIC=\"projects/cloud-build-pipeline-396819/topics/$topicName\"" --region=us-central1

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
gcloud builds submit . --config cloudbuild.yaml --substitutions "_GIT_CLONE_URL=https://github.com/brianpipeline/test-cloudbuild-failure.git,_GIT_REPOSITORY_NAME="test-cloudbuild-failure",_GIT_REF="refs/heads/main",_GIT_HEAD_SHA="b3fa043e677500882e689fc1a978d96056d6702d",_REPLY_TOPIC=\"projects/cloud-build-pipeline-396819/topics/$topicName\"" --region=us-central1

message=$(gcloud pubsub subscriptions pull --auto-ack "$subscriptionName" --format='value(message.data)' 2>/dev/null)
gcloud pubsub topics delete "$topicName"
gcloud pubsub subscriptions delete "$subscriptionName"
if [[ $message == "Pipeline failed." ]]; then
    echo "Received Message: $message"
else
    exit 1
fi
