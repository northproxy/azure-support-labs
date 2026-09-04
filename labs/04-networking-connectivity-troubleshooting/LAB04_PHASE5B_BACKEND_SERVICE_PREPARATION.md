# Lab 04 — Phase 5B: Backend Service Preparation

## Status

**Completed**

Both temporary backend VMs were prepared with nginx and independently verified before the Load Balancer was introduced.

Previous block:

[`LAB04_PHASE5A_LOAD_BALANCER_PREPARATION_AND_QUOTA_TROUBLESHOOTING.md`](LAB04_PHASE5A_LOAD_BALANCER_PREPARATION_AND_QUOTA_TROUBLESHOOTING.md)

Next block:

[`LAB04_PHASE5C_STANDARD_PUBLIC_LOAD_BALANCER_BUILD_AND_VERIFICATION.md`](LAB04_PHASE5C_STANDARD_PUBLIC_LOAD_BALANCER_BUILD_AND_VERIFICATION.md)

---

## Goal

Establish a known-good guest/application baseline so that later Load Balancer failures can be separated from nginx or guest configuration problems.

## HTTP Backend Service Baseline

Both temporary backend VMs now have nginx installed and verified before the Load Balancer is introduced.

### `vm-azsl-lb-01`

Configuration method:

```text
Azure CLI → az vm run-command invoke
```

The first attempt used a multi-line PowerShell variable for the script. Azure Run Command reported provisioning success, but only `apt-get update` was observed in the output and nginx remained inactive.

Observed symptom:

```text
systemctl is-active nginx
→ inactive
```

The command was retried as a single shell command string so that execution order was explicit.

Successful installation evidence included:

```text
The following NEW packages will be installed:
  nginx nginx-common

Setting up nginx ...
```

A backend-specific page was written:

```html
<h1>Backend: vm-azsl-lb-01</h1>
```

Verification:

```text
nginx state: active
HTTP response: <h1>Backend: vm-azsl-lb-01</h1>
```

### `vm-azsl-lb-02`

Configuration method:

```text
Azure Portal
→ Virtual machines
→ vm-azsl-lb-02
→ Operations
→ Run command
→ RunShellScript
```

A backend-specific page was written:

```html
<h1>Backend: vm-azsl-lb-02</h1>
```

Verification through Portal Run Command:

```text
HTTP response: <h1>Backend: vm-azsl-lb-02</h1>
nginx state: active
```

### Backend service checkpoint

```text
vm-azsl-lb-01
├── VM running
├── private IP only
├── no Public IP
├── no NIC-level NSG
├── nginx active
└── HTTP/80 responds locally with backend 01 identity

vm-azsl-lb-02
├── VM running
├── private IP only
├── no Public IP
├── no NIC-level NSG
├── nginx active
└── HTTP/80 responds locally with backend 02 identity
```

This establishes a known-good backend application baseline before the Load Balancer is added.

If external HTTP access later fails after the Load Balancer is created, nginx itself has already been verified as working on both backend VMs.

### Run Command troubleshooting lesson

A successful Azure Run Command provisioning state does not by itself prove that every intended shell command produced the expected guest-level result.

Useful verification sequence:

```text
Run Command provisioning succeeded
↓
Check actual stdout/stderr
↓
Verify service state
↓
Verify local application response
```

The guest workload must still be verified independently.

---

---

## Completion Checkpoint

```text
vm-azsl-lb-01
├── nginx active
├── listens on TCP/80
└── local response: Backend: vm-azsl-lb-01

vm-azsl-lb-02
├── nginx active
├── listens on TCP/80
└── local response: Backend: vm-azsl-lb-02
```

At this checkpoint the Load Balancer had not yet been created.
