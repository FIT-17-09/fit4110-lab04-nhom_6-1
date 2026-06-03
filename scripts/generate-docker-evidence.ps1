param(
    [string]$ImageName = "fit4110/iot-ingestion:lab04",
    [string]$ContainerName = "fit4110-iot-lab04",
    [int]$Port = 8000,
    [int]$HealthTimeoutSec = 60
)

Set-Location -Path (Split-Path -Parent $MyInvocation.MyCommand.Definition)
New-Item -ItemType Directory -Path "..\reports" -Force | Out-Null
$reports = Resolve-Path "..\reports"

# Build image
Write-Host "Building image $ImageName..."
docker build -t $ImageName . 2>&1 | Tee-Object -FilePath "$($reports)\docker-build.log"

# Run container detached
Write-Host "Running container $ContainerName..."
docker run -d --rm --name $ContainerName -p $Port:8000 --env-file .env.example $ImageName | Out-Null

# Wait for health
$healthUrl = "http://localhost:$Port/health"
$end = (Get-Date).AddSeconds($HealthTimeoutSec)
$ok = $false
while ((Get-Date) -lt $end) {
    try {
        $resp = Invoke-RestMethod -Uri $healthUrl -Method Get -ErrorAction Stop
        $resp | ConvertTo-Json -Depth 5 | Out-File -FilePath "$($reports)\health.json" -Encoding utf8
        Write-Host "Health check passed: $($resp | ConvertTo-Json -Depth 5)"
        $ok = $true
        break
    } catch {
        Start-Sleep -Seconds 2
    }
}

if (-not $ok) {
    Write-Host "Health check failed after $HealthTimeoutSec seconds. Collecting container logs."
    docker logs $ContainerName 2>&1 | Tee-Object -FilePath "$($reports)\container.log"
    Write-Host "Stopping container..."
    docker stop $ContainerName | Out-Null
    exit 1
}

# Run Newman tests
Write-Host "Running Newman tests against local container..."
npm run test:local 2>&1 | Tee-Object -FilePath "$($reports)\newman-local.log"

# Collect additional logs
docker logs $ContainerName 2>&1 | Tee-Object -FilePath "$($reports)\container.log"

# Stop container
Write-Host "Stopping container..."
docker stop $ContainerName | Out-Null

# Generate a simple evidence markdown
$evidence = @"
# Docker Evidence (generated)

- Image: $ImageName
- Container: $ContainerName

## Build log
reports/docker-build.log

## Health check
reports/health.json

## Newman reports
reports/newman-lab04-local.html
reports/newman-lab04-local.xml

## Container logs
reports/container.log

"@
$evidence | Out-File -FilePath "$($reports)\docker-evidence.md" -Encoding utf8

Write-Host "Evidence written to $($reports)\docker-evidence.md"
