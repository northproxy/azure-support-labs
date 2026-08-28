# Azure Output Sanitizer

Local browser-based helper for sanitizing Azure CLI and PowerShell output before sharing it with ChatGPT or saving it in project documentation.

## Files

```text
tools/
├── azure-output-sanitizer.html
├── azure-output-sanitizer.css
└── azure-output-sanitizer.js
```

Open `azure-output-sanitizer.html` in a browser. Paste raw Azure output into the left pane and copy the sanitized result from the right pane.

The tool runs locally in the browser and does not make network requests.

## Sanitized data

Current rules replace:

- GUIDs → `<GUID-N>`
- RFC1918 IPv4 addresses → `<PRIVATE-IP-N>`
- public IPv4 addresses → `<PUBLIC-IP-N>`
- special/reserved IPv4 addresses → `<SPECIAL-IP-N>`
- UPN / email addresses → `<UPN-N>`
- MAC addresses → `<MAC-N>`
- SSH public keys in `keyData` → `<SSH-PUBLIC-KEY-N>`

Repeated values receive the same placeholder within one sanitization run.

## Preserved data

The tool intentionally keeps useful troubleshooting context, including:

- Azure resource names
- Resource Group names
- provider/type paths
- regions
- VM sizes
- NSG rule names
- ports and protocols
- CIDR prefix lengths
- provisioning and power states
- `0.0.0.0/0`

## Limitations

This is a lightweight project helper, not a production DLP or secret-scanning tool.

It does not currently sanitize:

- IPv6 addresses
- tokens or passwords
- SAS tokens
- connection strings
- arbitrary filesystem usernames or paths

Always review sanitized output before publishing it.

## Project

Azure Support Labs

Learning cycle:

**Topic → Build → Observe → Break → Diagnose → Fix → Verify**
