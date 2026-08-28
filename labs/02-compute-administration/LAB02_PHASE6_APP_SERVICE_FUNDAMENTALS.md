# Lab 02 — Phase 6: App Service Fundamentals

Status: **completed**

## Purpose

Understand Azure App Service as a PaaS compute option and compare its operating model with the IaaS virtual machine used earlier in Lab 02.

This phase focuses on the relationship between an App Service Plan and a Web App, runtime configuration, application deployment, basic scaling concepts, controlled startup failure diagnosis, recovery, and cleanup.

---

## Learning objectives

- Understand Azure App Service as a PaaS compute service.
- Distinguish an App Service Plan from a Web App.
- Understand the relationship between `Microsoft.Web/serverfarms` and `Microsoft.Web/sites`.
- Register and verify the `Microsoft.Web` Resource Provider.
- Deploy a low-cost Linux App Service Plan using the Free F1 tier.
- Configure a Python runtime.
- Deploy a minimal Flask application.
- Use App Service application settings as environment variables.
- Understand scale up/down versus scale out/in.
- Diagnose an App Service startup failure using logs.
- Restore service without redeploying application code.
- Delete all temporary App Service resources after validation.

---

## Starting baseline

The retained Lab 02 VM environment remained unchanged.

```text
Resource Group:       rg-azsl-01
VM:                   vm-azsl-01
VM size:              Standard_B2ats_v2
Provisioning state:   Succeeded
Power state:          VM deallocated
OS disk:              30 GiB StandardSSD_LRS
Data disks:           none
Microsoft.Web/*:      none
```

No App Service resources existed in the Resource Group before this phase.

---

# Phase 6A — Concepts / Prepare

Status: **completed**

The Resource Group was inspected for existing App Service-related resources:

```powershell
az resource list `
  --resource-group rg-azsl-01 `
  --query "[?starts_with(type, 'Microsoft.Web')].{Name:name, Type:type, Location:location}" `
  --output table
```

The result was empty.

The `Microsoft.Web` Resource Provider was then inspected:

```powershell
az provider show `
  --namespace Microsoft.Web `
  --query "{Namespace:namespace, RegistrationState:registrationState}" `
  --output table
```

Initial state:

```text
Microsoft.Web  NotRegistered
```

The provider was registered:

```powershell
az provider register `
  --namespace Microsoft.Web
```

Registration progressed through `Registering` and completed as:

```text
Microsoft.Web  Registered
```

The same state was also inspected in Azure Portal:

```text
Subscription
→ Resource providers
→ Microsoft.Web
```

Core resource types:

```text
Microsoft.Web/serverfarms  → App Service Plan
Microsoft.Web/sites        → Web App
```

---

# Phase 6B — First Controlled Deployment

Status: **completed**

Free-tier availability was checked:

```powershell
az appservice list-locations `
  --sku FREE `
  --output table
```

`Austria East` was available.

A Linux App Service Plan was created:

```powershell
az appservice plan create `
  --name asp-azsl-01 `
  --resource-group rg-azsl-01 `
  --location austriaeast `
  --sku F1 `
  --is-linux
```

Verified plan:

```text
Name:       asp-azsl-01
Location:   Austria East
Kind:       linux
SKU:        F1
Tier:       Free
Capacity:   1
```

A Python Web App was created:

```powershell
az webapp create `
  --resource-group rg-azsl-01 `
  --plan asp-azsl-01 `
  --name web-azsl-01 `
  --runtime "PYTHON:3.12"
```

The Web App was successfully created and reported as running.

---

# Phase 6C — App Service Plan vs Web App

Status: **completed**

The Web App dependency on the App Service Plan was verified through `serverFarmId`.

```text
Microsoft.Web/sites
└── web-azsl-01
    └── serverFarmId
        └── Microsoft.Web/serverfarms/asp-azsl-01
```

App Service Plan properties:

```text
Kind:      linux
Location:  Austria East
SKU:       F1
Tier:      Free
Capacity:  1
```

Web App runtime properties:

```text
LinuxFxVersion:  PYTHON|3.12
AlwaysOn:        False
Http20Enabled:   False
MinTlsVersion:   1.2
```

Key distinction:

```text
App Service Plan
→ compute capacity, region, OS family, SKU, tier

Web App
→ application runtime and application configuration
```

`Capacity = 1` on F1 was understood as a plan property on shared App Service infrastructure, not as a dedicated customer-managed VM.

---

# Phase 6D — Runtime & Application Deployment

Status: **completed**

A minimal Flask application was created locally:

```text
app-service-demo/
├── app.py
└── requirements.txt
```

`app.py`:

```python
# Script: app.py
#
# Purpose:
# Provide a minimal Flask application for Azure App Service deployment.
#
# Project:
# Azure Support Labs.
#
# Learning focus:
# Azure App Service, Python runtime, application deployment.
#
# Lifecycle:
# Temporary learning script.

from flask import Flask

app = Flask(__name__)


@app.route("/")
def home():
    return "Azure Support Labs - App Service is running!"
```

`requirements.txt`:

```text
Flask
gunicorn
```

Build automation was enabled:

```powershell
az webapp config appsettings set `
  --resource-group rg-azsl-01 `
  --name web-azsl-01 `
  --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true
```

Verified:

```text
SCM_DO_BUILD_DURING_DEPLOYMENT  true
```

The ZIP archive contained:

```text
requirements.txt
app.py
```

Deployment:

```powershell
az webapp deploy `
  --resource-group rg-azsl-01 `
  --name web-azsl-01 `
  --src-path .\app-service-demo.zip `
  --type zip
```

Deployment result:

```text
status:                       RuntimeSuccessful
numberOfInstancesSuccessful:  1
numberOfInstancesFailed:      0
errors:                       null
```

The public HTTPS endpoint returned:

```text
Azure Support Labs - App Service is running!
```

---

# Phase 6E — Runtime & Application Configuration

Status: **completed**

The application was modified to read an environment variable:

```python
import os
from flask import Flask

app = Flask(__name__)


@app.route("/")
def home():
    message = os.getenv(
        "APP_MESSAGE",
        "Azure Support Labs - App Service is running!"
    )
    return message
```

An App Service setting was created:

```powershell
az webapp config appsettings set `
  --resource-group rg-azsl-01 `
  --name web-azsl-01 `
  --settings APP_MESSAGE="Azure Support Labs - configuration updated!"
```

Verified:

```text
APP_MESSAGE  Azure Support Labs - configuration updated!
```

The Web App returned:

```text
Azure Support Labs - configuration updated!
```

This confirmed that application behavior could be changed through external configuration without changing source code.

---

# Phase 6F — Scaling Fundamentals

Status: **completed**

Scale baseline:

```text
SKU:       F1
Tier:      Free
Capacity:  1
```

Scaling distinction:

```text
Scale up / down
→ change App Service Plan SKU / capabilities

Scale out / in
→ change the number of application instances
```

No paid scaling operation was performed.

---

# Phase 6G — Controlled Failure / Troubleshooting

Status: **completed**

A controlled startup failure was introduced:

```powershell
az webapp config set `
  --resource-group rg-azsl-01 `
  --name web-azsl-01 `
  --startup-file "gunicorn missingmodule:app"
```

Observed symptom:

```text
HTTP 503
```

Logs identified:

```text
ModuleNotFoundError: No module named 'missingmodule'
Worker exited with code 3
Reason: Worker failed to boot.
ContainerStartupFailure
Site startup probe failed
```

The previous deployment itself remained successful:

```text
Build Summary:
Errors (0)
Warnings (0)

Deployment successful.
```

Key troubleshooting conclusion:

```text
Deployment successful
≠
Application runtime healthy
```

Failure chain:

```text
Invalid startup command
    ↓
Python cannot import missingmodule
    ↓
Gunicorn worker fails
    ↓
Container startup fails
    ↓
Startup probe fails
    ↓
HTTP 503
```

The invalid startup command was removed through Azure Portal.

CLI verification after rollback:

```text
LinuxFxVersion    StartupCommand
----------------  --------------
PYTHON|3.12
```

The application recovered successfully and again returned:

```text
Azure Support Labs - configuration updated!
```

---

# Cleanup

Status: **completed**

The temporary Web App was deleted:

```powershell
az webapp delete `
  --resource-group rg-azsl-01 `
  --name web-azsl-01
```

The temporary App Service Plan was deleted:

```powershell
az appservice plan delete `
  --resource-group rg-azsl-01 `
  --name asp-azsl-01 `
  --yes
```

Final verification:

```text
Microsoft.Web/*: none
```

The retained VM baseline remained unchanged:

```text
VM:                  vm-azsl-01
VM size:             Standard_B2ats_v2
Provisioning state:  Succeeded
Power state:         VM deallocated
OS disk:             30 GiB StandardSSD_LRS
Data disks:           none
```

---

## Key findings

### App Service as PaaS

```text
Virtual Machine
→ manage VM lifecycle, guest OS, runtime, disks, and application

Azure App Service
→ manage application, runtime configuration, deployment, and service settings
```

### App Service Plan vs Web App

```text
App Service Plan
→ compute and pricing boundary

Web App
→ application and runtime configuration
```

The dependency is represented through:

```text
serverFarmId
```

### Configuration is separate from code

App settings were exposed to the Python application as environment variables.

Changing `APP_MESSAGE` changed application behavior without changing source code.

### Deployment health and runtime health are different

```text
Deployment: successful
Runtime:    failed
HTTP:       503
```

Startup logs were required to identify the actual cause.

### Cost safety

The Free F1 App Service Plan was sufficient for this learning phase.

No paid scaling operation was required.

All temporary App Service resources were deleted after validation.

---

## Phase completion

```text
[✓] Phase 6A — Concepts / Prepare
[✓] Phase 6B — First Controlled Deployment
[✓] Phase 6C — App Service Plan vs Web App
[✓] Phase 6D — Runtime & Application Deployment
[✓] Phase 6E — Runtime & Application Configuration
[✓] Phase 6F — Scaling Fundamentals
[✓] Phase 6G — Controlled Failure / Troubleshooting
[✓] Cleanup
```

Phase 6 learning cycle:

```text
Build
→ Inspect
→ Configure
→ Deploy
→ Break
→ Diagnose
→ Fix
→ Verify
→ Delete
```
