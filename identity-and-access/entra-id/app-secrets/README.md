# Entra App Secrets

Scripts for the **entra-app-secrets** technology in this sub-process.

## Scripts adapted from field work

Each script solves one problem. They were adapted from real operations work: replace every `ENTRE_AQUI_COM_SEU_*` marker, review, and test in a non-production tenant first.

| Script | Problem it solves | What it does | Requires | Effect | Notes |
|---|---|---|---|---|---|
| `list-app-registrations-and-owners.ps1` | App registrations have no owner and nobody maintains their secrets. | Exports applications with owners, audience and credential dates. | AzureAD | read-only | deprecated AzureAD module (retired); port to Microsoft.Graph; no MgGraph equivalent in slice |
| `list-app-secrets-expiring.ps1` | App secrets expire unnoticed and break integrations, or old secrets linger. | Exports every app registration key/secret with expiry date, owners and creator to Excel. | Microsoft.Graph.Applications, ImportExcel; Application.Read.All | read-only |  |
