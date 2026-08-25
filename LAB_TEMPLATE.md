# Lab XX — Name — Execution

## Before You Start

Review the lab contract in `README.md`.

Confirm:
- the learning objectives are understood;
- the lab scope and exclusions are clear;
- required Azure access is available;
- expected paid resources are known;
- temporary resources will be deleted when no longer needed.

## Prepare

Record the minimum context needed before deployment:

- active Azure subscription;
- target region;
- naming pattern;
- expected resources;
- expected resource lifecycle;
- cost-sensitive resources, if any.

Do not store credentials, secrets, billing data, or tenant-sensitive identifiers in the repository.

## Build

Create only the resources required by the lab contract.

For each important resource, understand:
- what problem it solves;
- what it depends on;
- what depends on it;
- whether it can incur cost while idle.

Avoid unexplained copy-paste and unnecessary resources.

## Inspect

Before introducing any failure, inspect the working environment.

Check:
- resource inventory;
- important properties;
- dependencies;
- networking;
- identity/access where relevant;
- current runtime state;
- Azure Activity Log or other control-plane evidence where relevant.

## Map

Describe the important resource relationships.

Use a concise text diagram when useful.

Example:

```text
Resource A
└── Resource B
    └── Resource C
```

The goal is to understand dependencies, not only recognize resource names.

## Observe

Verify the environment works before breaking it.

Collect only useful evidence:
- successful connectivity or application response;
- relevant resource state;
- representative CLI/PowerShell output;
- Activity Log, metrics, or logs when applicable.

## Break

Introduce one controlled failure.

Rules:
- change one relevant thing at a time;
- do not create multiple simultaneous root causes;
- record the intended change;
- avoid destructive changes that are difficult or expensive to reverse unless the lab specifically requires them.

## Diagnose

Investigate before changing anything else.

Record:

### Symptoms

- What stopped working?
- What still works?

### Hypotheses

- What are the most likely causes?

### Checks performed

- Which resources and dependencies were inspected?
- Which logs, metrics, configuration, or commands provided evidence?

### Root cause

Describe the root cause in your own words.

Do not fix the problem until the root cause is supported by evidence.

## Fix

Apply the smallest appropriate fix.

Avoid changing unrelated settings.

Record:
- what was changed;
- why that change addresses the root cause.

## Verify

Prove recovery.

Confirm:
- the original symptom is gone;
- the expected configuration is restored;
- dependent resources still behave correctly;
- relevant logs, metrics, or Activity Log evidence support the recovery where useful.

## Cleanup

Delete temporary resources according to the lab lifecycle.

Confirm:
- temporary paid resources are removed;
- resources intentionally retained for the next lab are documented;
- the Resource Group is deleted when full cleanup is intended;
- no unnecessary resources remain.

Check Cost Management when the lab created potentially chargeable resources.

## What I Learned

Complete after the lab:

- The main resource relationships are:
- The most useful evidence was:
- The root cause was:
- The smallest effective fix was:
- One thing I can now explain without notes is:

## Questions / Gaps

- 
- 

## Completion Check

- [ ] Lab objectives were reviewed
- [ ] Required resources were created or inspected
- [ ] Resource relationships were understood
- [ ] Working state was verified before failure injection
- [ ] A controlled failure was introduced
- [ ] Root cause was diagnosed before repair
- [ ] The smallest appropriate fix was applied
- [ ] Recovery was verified
- [ ] Important findings were documented
- [ ] Temporary resources were deleted or intentionally retained
- [ ] `ROADMAP.md` was updated when appropriate
- [ ] `AZURE_MAP.md` was updated only with topics actually studied or practiced
