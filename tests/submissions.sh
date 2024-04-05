#!/bin/sh

gcloud builds submit . --config cloudbuild.yaml --region=us-central1
