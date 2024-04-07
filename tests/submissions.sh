#!/bin/sh

topicName="test-topic"
if ! gcloud pubsub topics create "$topicName"; then
    echo "Topic $topicName already exists"
fi

gcloud builds submit . --config cloudbuild.yaml --substitutions "_REPO_TO_CLONE=https://github.com/brianpipeline/test-cloudbuild.git,_REPLY_TOPIC=\"projects/cloud-build-pipeline-396819/topics/$topicName\"" --region=us-central1
