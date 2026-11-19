# Entra Conditional Access

Scripts for the **entra-conditional-access** technology in this sub-process.

## Scripts adapted from field work

Each script solves one problem. They were adapted from real operations work: replace every `ENTRE_AQUI_COM_SEU_*` marker, review, and test in a non-production tenant first.

| Script | Problem it solves | What it does | Requires | Effect | Notes |
|---|---|---|---|---|---|
| `create-country-exception-policy.ps1` | Users who travel or work abroad are blocked by country-based CA and need a controlled, temporary exception. | Takes users, countries and exception type; creates named location, CA policy and exception-group membership. | AzureAD, Az.Accounts (managed identity); Conditional Access Administrator | changes-state | deprecated AzureAD module (retired); port to Microsoft.Graph (New-AzureADMSConditionalAccessPolicy); Portuguese comments; derived from vanvfields baseline script; exception group name and email domain client-specific; 'p |
| `export-conditional-access-policies-json.ps1` | CA policies change with no backup or baseline for rollback. | Exports every CA policy and named location to JSON files. | Microsoft.Graph.Identity.ConditionalAccess; Policy.Read.All | read-only |  |
| `generate-conditional-access-documentation.ps1` | Nobody can read or document the Conditional Access policy set. | Builds a human-readable Excel/CSV documentation of all CA policies resolving IDs to names. | Microsoft.Graph; Policy.Read.All, Application.Read.All, Group.Read.All, User.Read.All | read-only | Adapted from third-party nicolonsky/ConditionalAccessDocumentation (check licence/attribution); uses deprecated Select-MgProfile beta; both Windows and macOS $outputPath lines active (second overrides) |
