# A5 Analytics Submission

Product: A5
Provider: Analytics
Consumers: IoT Ingestion / Camera Stream / Core Business / Access Gate

Files included:
- contracts/a5-analytics.openapi.yaml
- mock-data/analytics-event-valid.json
- postman/collections/FIT4110_lab04_A5_analytics.postman_collection.json

Quick checks you can run locally:

Validate OpenAPI (PowerShell may block `npx` on Windows; see note):

```powershell
# If PowerShell blocks scripts, run from an elevated PowerShell and set execution policy temporarily:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
npx @apidevtools/swagger-cli validate contracts/a5-analytics.openapi.yaml
```

If you prefer Docker:

```bash
docker run --rm -v "%cd%":/work -w /work node:20-slim npx @apidevtools/swagger-cli validate contracts/a5-analytics.openapi.yaml
```

Send test event via curl:

```bash
curl -X POST http://localhost:8000/analytics/events \
  -H "Content-Type: application/json" \
  -d @mock-data/analytics-event-valid.json
```

Postman: import `postman/collections/FIT4110_lab04_A5_analytics.postman_collection.json` and run the "Publish Analytics Event" request.

Notes:
- The environment here prevented running `npx` due to PowerShell execution policy; please run the validator on your machine if required for submission.
