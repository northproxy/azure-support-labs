# Lab 04 — Phase 5D: Load Balancer Backend Connectivity Troubleshooting

## Status

**Completed**

The initial Standard Load Balancer connectivity failure was diagnosed and fixed, the controlled backend failure/recovery exercise was completed, and all temporary Phase 5 resources were deleted. The retained Azure networking baseline was verified after cleanup.

Previous block:

[`LAB04_PHASE5C_STANDARD_PUBLIC_LOAD_BALANCER_BUILD_AND_VERIFICATION.md`](LAB04_PHASE5C_STANDARD_PUBLIC_LOAD_BALANCER_BUILD_AND_VERIFICATION.md)

---

## Goal

Troubleshoot the Load Balancer data path using evidence from Azure control-plane configuration, backend guest state, and network security; then perform a controlled backend outage and recovery.

## Initial External Connectivity Failure

The first HTTP request to the Load Balancer frontend failed:

```text
curl http://<PUBLIC-IP>
→ connection timeout on TCP/80
```

No Load Balancer configuration was changed immediately.

The troubleshooting sequence followed:

```text
Observe symptom
↓
Verify frontend Public IP association
↓
Verify backend pool membership
↓
Verify health probe and load-balancing rule references
↓
Verify nginx on both guest VMs
↓
Inspect security path
↓
Change one thing
↓
Retest
```

### Frontend verification

The Public IP was correctly attached to the Load Balancer frontend and showed:

```text
ProvisioningState: Succeeded
IPConfiguration:   lb-azsl-01/frontendIPConfigurations/fe-azsl-lb-01
```

### Backend membership verification

Azure CLI confirmed that the backend pool contained exactly the two intended backend NIC IP configurations:

```text
vm-azsl-lb-01VMNic/ipConfigurations/ipconfigvm-azsl-lb-01
vm-azsl-lb-02VMNic/ipConfigurations/ipconfigvm-azsl-lb-02
```

### Guest service verification

`vm-azsl-lb-01`:

```text
nginx: active
listener: 0.0.0.0:80
listener: [::]:80
local HTTP: <h1>Backend: vm-azsl-lb-01</h1>
```

`vm-azsl-lb-02`:

```text
nginx: active
listener: 0.0.0.0:80
listener: [::]:80
local HTTP: <h1>Backend: vm-azsl-lb-02</h1>
```

This excluded nginx, guest listening state, backend pool membership, and frontend association as the cause of the timeout.

---

## Root Cause — Backend Security Path

At the time of the failure, both backend NICs had:

```text
NIC-level NSG:    none
Subnet-level NSG: none
```

The Standard Public Load Balancer frontend, rule, and backend pool were correctly configured, but the backend security path did not explicitly allow inbound HTTP traffic.

A dedicated temporary backend NSG was created instead of modifying the retained `nsg-azsl-01` or associating an NSG to the shared subnet.

Reason for choosing NIC-level association:

```text
subnet-azsl-01 also contains retained vm-azsl-01
↓
subnet-level NSG would affect the retained VM as well
↓
use a dedicated NSG on only the temporary backend NICs
```

Created NSG:

```text
nsg-azsl-lb-backend
```

Inbound rule:

```text
Priority:          100
Name:              allow-http-internet
Source:            Internet
Source port:       *
Destination:       Any
Destination port:  80
Protocol:          TCP
Action:            Allow
```

The default `AllowAzureLoadBalancerIn` rule remained available for Azure Load Balancer health probes.

NSG associations:

```text
nsg-azsl-lb-backend
├── vm-azsl-lb-01VMNic
└── vm-azsl-lb-02VMNic
```

Only the security path was changed.

The following were intentionally left unchanged during the fix:

```text
Load Balancer frontend
Backend pool
Health probe
Load-balancing rule
nginx configuration
VM private IP configuration
```

---

## Connectivity Recovery Verification

After associating `nsg-azsl-lb-backend` with both backend NICs, the same external request succeeded:

```text
curl http://<PUBLIC-IP>
→ <h1>Backend: vm-azsl-lb-01</h1>
```

Repeated requests were then sent to the same Load Balancer frontend.

Observed output:

```text
Backend: vm-azsl-lb-02
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-02
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-02
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-02
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-02
Backend: vm-azsl-lb-01
```

This verifies that:

```text
Public frontend reachability: working
TCP/80 load-balancing rule:  working
Backend pool membership:     working
Health probe path:            working
Backend 01:                   receiving traffic
Backend 02:                   receiving traffic
Traffic distribution:         observed across both backends
```

Current working topology:

```text
Internet
   |
   v
pip-azsl-lb-01
   |
   v
fe-azsl-lb-01
   |
   v
lbr-azsl-http-80
   |
   +---- hp-azsl-lb-http
   |
   v
bp-azsl-lb-01
   ├── vm-azsl-lb-01VMNic
   │   └── nginx :80
   └── vm-azsl-lb-02VMNic
       └── nginx :80

Security:

nsg-azsl-lb-backend
├── allow-http-internet → TCP/80
├── attached to vm-azsl-lb-01VMNic
└── attached to vm-azsl-lb-02VMNic
```

---

## Resource Tagging / Portal Filtering

As the temporary topology grew, Phase 5 resources were tagged so they can be filtered in Azure Portal and distinguished from retained baseline resources.

Tag scheme used:

```text
Project   = AzureSupportLabs
Lab       = Lab04
Phase     = Phase5
Lifecycle = Temporary
```

Current filtered Phase 5 resource set includes:

```text
lb-azsl-01
pip-azsl-lb-01
vm-azsl-lb-01
vm-azsl-lb-01VMNic
vm-azsl-lb-02
vm-azsl-lb-02VMNic
nsg-azsl-lb-backend
```

This will make the final Phase 5 cleanup safer and easier to verify.

---

## Troubleshooting Lessons Added in This Checkpoint

### 1. Control-plane success does not prove data-plane reachability

Azure reported the Load Balancer as successfully provisioned and all referenced components existed, but external TCP/80 still timed out.

Useful distinction:

```text
Provisioning succeeded
≠
Application traffic succeeds
```

### 2. Verify each layer before changing configuration

The successful diagnosis was possible because the following were verified independently:

```text
Public IP association
Frontend configuration
Backend pool membership
Health probe configuration
Load-balancing rule
Guest service state
Guest listener binding
Local HTTP response
Network security path
```

### 3. Change one layer at a time

No changes were made to nginx, the Load Balancer rule, backend pool, or probe while investigating the timeout.

The only remediation was the dedicated backend NSG and TCP/80 allow rule.

The immediate recovery after that change confirmed the security path as the root cause.

### 4. Keep temporary topology isolated from retained resources

A subnet-level NSG was avoided because the same subnet also contains the retained `vm-azsl-01`.

Using a dedicated NIC-level NSG kept the Phase 5 change isolated to the two temporary backend VMs.

---

---

## Controlled Backend Failure and Recovery

A controlled application-layer failure was introduced on exactly one backend VM to verify how the Load Balancer reacts when a backend service becomes unhealthy while the VM itself remains running.

### Break — Stop nginx on `vm-azsl-lb-02`

`nginx` was stopped on the second backend VM using Azure Run Command.

Observed result:

```text
Run Command provisioning: Succeeded
nginx state:              inactive
```

No Azure networking configuration was changed during this step.

The following remained unchanged:

```text
vm-azsl-lb-02 power state
NIC configuration
Backend pool membership
NSG association and rules
Load Balancer frontend
Health probe configuration
Load-balancing rule
```

This isolated the failure to the guest/application layer.

### Observe — Load Balancer Removes the Unhealthy Backend

After the health probe converged on the failed backend, ten HTTP requests were sent to the same Load Balancer frontend.

Observed output:

```text
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-01
```

`vm-azsl-lb-02` no longer received new requests.

This showed that the Load Balancer kept the frontend available and continued sending new traffic only to the healthy backend.

### Diagnose — Verify the Failure Inside the Guest

The failed backend was inspected independently through Azure Run Command.

Observed evidence:

```text
nginx: inactive
TCP/80 listener: absent
local curl to 127.0.0.1:80: failed
```

The local HTTP test returned:

```text
curl: (7) Failed to connect to 127.0.0.1 port 80: Couldn't connect to server
```

This established the failure chain:

```text
nginx stopped
↓
TCP/80 listener disappears
↓
local HTTP fails
↓
HTTP health probe fails
↓
vm-azsl-lb-02 becomes unhealthy
↓
Load Balancer excludes it from new-flow distribution
↓
traffic continues through vm-azsl-lb-01
```

The diagnosis therefore remained at the guest/application layer. There was no evidence that the NSG, NIC, backend pool, frontend, or load-balancing rule had failed.

### Fix — Start nginx on `vm-azsl-lb-02`

`nginx` was started again on the failed backend.

Local HTTP verification succeeded:

```html
<h1>Backend: vm-azsl-lb-02</h1>
```

This confirmed application recovery inside the guest before testing Load Balancer recovery.

### Verify — Backend Returns to Rotation

After the health probe detected the recovered backend, ten requests were sent again to the Load Balancer frontend.

Observed output:

```text
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-02
Backend: vm-azsl-lb-02
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-02
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-02
Backend: vm-azsl-lb-01
Backend: vm-azsl-lb-02
Backend: vm-azsl-lb-01
```

Both backends were therefore healthy and receiving traffic again.

Recovery path:

```text
nginx started
↓
TCP/80 listener returns
↓
local HTTP succeeds
↓
health probe succeeds
↓
vm-azsl-lb-02 returns to healthy state
↓
Load Balancer resumes distributing new traffic across both backends
```

### Controlled Failure Lesson

The exercise demonstrated an important distinction:

```text
VM running
≠
application healthy
```

Azure Load Balancer does not treat a backend as healthy merely because the VM is powered on. The configured health probe determines whether the backend is eligible to receive new load-balanced flows.

The scenario also demonstrated graceful service degradation: with one backend application unavailable, the frontend remained reachable because the remaining healthy backend continued serving requests.

## Updated Phase 5 Checkpoint

```text
Backend VM 1:              deleted after verification
Backend VM 2:              deleted after verification
nginx backend 01:          verified before cleanup
nginx backend 02:          verified before cleanup
Standard Public IP:        deleted
Load Balancer:             deleted
Frontend configuration:    removed with Load Balancer
Backend pool:              removed with Load Balancer
Health probe:              removed with Load Balancer
Load-balancing rule:       removed with Load Balancer
Backend NSG:               deleted
Initial HTTP timeout:      diagnosed
Root cause:                backend security path / missing explicit HTTP allow
Fix:                       dedicated backend NIC NSG with TCP/80 allow
Traffic distribution:      verified across both backends
Controlled backend failure: completed
Recovery exercise:         completed
Final cleanup:             completed
```

---

## Final Cleanup

All temporary Phase 5 resources were deleted after verification.

Deleted temporary resources included:

```text
lb-azsl-01
pip-azsl-lb-01
vm-azsl-lb-01
vm-azsl-lb-02
vm-azsl-lb-01VMNic
vm-azsl-lb-02VMNic
nsg-azsl-lb-backend
temporary backend OS disks
vm-azsl-lb-01-key
vm-azsl-lb-02-key
```

Azure CLI verification after cleanup showed only the retained baseline resources:

```text
vm-azsl-01-key
nsg-azsl-01
vm-azsl-01-ip
vnet-azsl-01
vm-azsl-01284
vm-azsl-01
vm-azsl-01_OsDisk_1_...
```

This confirms that the temporary Load Balancer topology was removed without deleting the retained Lab environment.

## Completion Checkpoint

Phase 5D is complete.

The complete Phase 5 learning cycle was achieved:

```text
Build
↓
Observe
↓
Break
↓
Diagnose
↓
Fix
↓
Verify
↓
Delete
```

Key practical outcomes:

- built and verified a Standard Public Load Balancer;
- diagnosed a real frontend-to-backend connectivity failure;
- isolated the problem to the backend security path;
- restored HTTP reachability with a dedicated backend NIC-level NSG;
- verified load distribution across two backends;
- reproduced a backend application failure by stopping nginx;
- verified health-probe-based backend removal;
- restored nginx and observed backend recovery;
- deleted all temporary Phase 5 resources;
- verified that the retained Azure baseline remained intact.
