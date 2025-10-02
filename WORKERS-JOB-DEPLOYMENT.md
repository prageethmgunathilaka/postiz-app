# Workers Job Deployment Guide

This document explains the migration from Cloud Run Services to Cloud Run Jobs for the Postiz workers.

## Overview

The workers have been migrated from Cloud Run Services to Cloud Run Jobs to better handle long-running background processing tasks.

## Changes Made

### 1. Application Architecture
- **Before**: HTTP server + BullMQ microservice
- **After**: BullMQ microservice only (no HTTP server)

### 2. Deployment Method
- **Before**: `gcloud run deploy` (Cloud Run Service)
- **After**: `gcloud run jobs replace` (Cloud Run Job)

### 3. Resource Configuration
- **Parallelism**: 3 instances
- **Memory**: 512Mi
- **CPU**: 1000m
- **Restart Policy**: OnFailure

## Deployment Scripts

### Bash (Linux/macOS)
```bash
./deploy-workers-job.sh
```

### PowerShell (Windows)
```powershell
.\deploy-workers-job.ps1
```

## Job Configuration

The workers job is configured with:
- **Parallelism**: 3 (runs 3 instances simultaneously)
- **Completions**: null (runs indefinitely)
- **Backoff Limit**: 3 (retries failed jobs up to 3 times)

## Environment Variables

- `NODE_ENV=production`
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string for BullMQ
- `FRONTEND_URL`: Frontend application URL

## Monitoring

Monitor the job execution using:
```bash
# List job executions
gcloud run jobs executions list --job=postiz-workers --region=us-central1

# View job logs
gcloud run jobs executions logs --job=postiz-workers --region=us-central1

# Check job status
gcloud run jobs describe postiz-workers --region=us-central1
```

## Benefits of Cloud Run Jobs

1. **Better Resource Utilization**: Designed for long-running processes
2. **Proper Scaling**: Scales based on job queue depth, not HTTP traffic
3. **Cost Efficiency**: Pay only for actual processing time
4. **Reliability**: Built-in retry mechanisms and failure handling
5. **Monitoring**: Better observability for background processing

## Migration Notes

- The workers no longer expose HTTP endpoints
- Health checks are handled internally by the BullMQ microservice
- The job runs continuously to process Redis queue messages
- Multiple instances can run in parallel for better throughput
