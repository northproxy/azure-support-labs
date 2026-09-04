# Lab 04 — Phase 5C: Standard Public Load Balancer Build & Verification

## Status

**Completed**

The Standard Public Load Balancer control-plane configuration was built in Azure Portal and verified with Azure CLI.

Previous block:

[`LAB04_PHASE5B_BACKEND_SERVICE_PREPARATION.md`](LAB04_PHASE5B_BACKEND_SERVICE_PREPARATION.md)

Next block:

[`LAB04_PHASE5D_LOAD_BALANCER_BACKEND_CONNECTIVITY_TROUBLESHOOTING.md`](LAB04_PHASE5D_LOAD_BALANCER_BACKEND_CONNECTIVITY_TROUBLESHOOTING.md)

---

## Goal

Build the complete Load Balancer data-path configuration deliberately and verify each Azure object and reference before testing external HTTP connectivity.

## Load Balancer Build Checkpoint

The Standard Public Load Balancer topology has now been created in the Azure Portal.

Created temporary resources:

```text
pip-azsl-lb-01
  Type: Public IP address
  SKU: Standard
  Tier: Regional
  IP version: IPv4
  Assignment: Static
  Availability zone: Zone-redundant
  Routing preference: MicrosoftNetwork
  DDoS protection: Disabled

lb-azsl-01
  Type: Standard Public Load Balancer
  Tier: Regional
  Region: Austria East
```

Frontend configuration:

```text
fe-azsl-lb-01
└── Public IP reference → pip-azsl-lb-01
```

Backend pool:

```text
bp-azsl-lb-01
├── vm-azsl-lb-01VMNic
│   └── ipconfigvm-azsl-lb-01
└── vm-azsl-lb-02VMNic
    └── ipconfigvm-azsl-lb-02
```

The retained VM `vm-azsl-01` was intentionally left outside the backend pool.

Health probe:

```text
Name:          hp-azsl-lb-http
Protocol:      HTTP
Port:          80
Request path:  /
Interval:      5 seconds
numberOfProbes: 1
```

Load-balancing rule:

```text
Name:           lbr-azsl-http-80
Protocol:       TCP
Frontend:       fe-azsl-lb-01
Frontend port:  80
Backend pool:   bp-azsl-lb-01
Backend port:   80
Health probe:   hp-azsl-lb-http
```

Azure CLI verification confirmed:

```text
Load Balancer provisioning state: Succeeded
Frontend configuration:           fe-azsl-lb-01
Backend pool:                     bp-azsl-lb-01
Health probe:                     hp-azsl-lb-http
Load-balancing rule:              lbr-azsl-http-80
```

The Public IP resource was also confirmed to reference:

```text
/loadBalancers/lb-azsl-01/frontendIPConfigurations/fe-azsl-lb-01
```

---

---

## Control-Plane Verification Summary

```text
pip-azsl-lb-01
        |
        v
fe-azsl-lb-01
        |
        v
lbr-azsl-http-80
        |
        +--> hp-azsl-lb-http
        |
        v
bp-azsl-lb-01
   ├── vm-azsl-lb-01VMNic / ipconfigvm-azsl-lb-01
   └── vm-azsl-lb-02VMNic / ipconfigvm-azsl-lb-02
```

Azure CLI confirmed the Load Balancer provisioning state as `Succeeded` and all expected references existed.

The next step was external TCP/80 verification.
