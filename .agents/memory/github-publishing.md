---
name: GitHub publishing through the connector
description: Connector behavior encountered while synchronizing this project with GitHub.
---

The GitHub connector can write ordinary repository files through the Contents API, but the connected proxy rejected Git database tree creation and `.github/workflows/*` writes during the foundation milestone. Keep local commits authoritative, verify the remote tree after each sync, and do not claim CI is published unless the workflow file is visible remotely.

**Why:** The repository was empty initially, and several Git Data API attempts returned `404`; the workflow path also returned an upstream `403` HTML response. Ordinary files uploaded successfully.

**How to apply:** Use the authenticated connector for regular source/docs synchronization, verify commit and root contents afterward, and surface the exact limitation if a workflow or atomic multi-file commit cannot be mirrored.

When a GitHub write is wrapped in a CodeExecution `"use impure"` function, pass file lists and file contents as function parameters instead of closing over durable-scope variables.

**Why:** The durable sandbox rejects captured outer bindings inside impure connector operations before the network request runs.

**How to apply:** Read files in the durable scope, then pass the serializable data into the impure function and verify the remote tree afterward.