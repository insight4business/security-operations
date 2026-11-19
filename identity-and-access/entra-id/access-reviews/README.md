# Entra Access Reviews

Scripts for the **entra-access-reviews** technology in this sub-process.

## Scripts adapted from field work

Each script solves one problem. They were adapted from real operations work: replace every `ENTRE_AQUI_COM_SEU_*` marker, review, and test in a non-production tenant first.

| Script | Problem it solves | What it does | Requires | Effect | Notes |
|---|---|---|---|---|---|
| `access-review-progress-report.ps1` | Reviewers have not completed reviews and nobody tracks progress. | Collects review instances, decisions and reviewers (with managers) into Excel. | Microsoft.Graph.Identity.Governance, ImportExcel; AccessReview.Read.All, User.Read.All | read-only |  |
| `create-default-access-reviews-from-csv.ps1` | Group memberships are never re-certified by users and managers. | Creates two-stage (user, manager) recurring access reviews for each group in a CSV. | Microsoft.Graph.Identity.Governance, Groups; AccessReview.ReadWrite.All, Group.Read.All | changes-state | CSV path placeholder; review CSV delimiter ';' |
| `create-executive-access-reviews-from-csv.ps1` | Access of C-level users is not reviewed by an appropriate reviewer. | Creates recurring access reviews (stage 1 CISO) per group from a CSV, skipping existing ones. | Microsoft.Graph.Identity.Governance, Groups; AccessReview.ReadWrite.All, Group.Read.All | changes-state | BROKEN: line 22 has typo parameter '-AllanceAccessReviewDefinition' on Get-MgIdentityGovernanceAccessReviewDefinition; CEO/CISO assumptions; path placeholder |
| `list-access-review-definitions.ps1` | Cannot see how each access review is configured and which group it covers. | Lists access review definitions with settings and the reviewed group. | Microsoft.Graph.Identity.Governance, Groups; AccessReview.Read.All | read-only | Header comment copied from creation script (wrong); requests ReadWrite scope though read-only |


# Access Review

Use every quarter, and before an audit.

| File | Use |
|---|---|
| access-review-procedure.md | Quarterly three-stage review: user, manager, owner |
| access-review-tracker.csv | One row per entitlement, with decisions per stage |
| evidence-template.md | Evidence pack for auditors |

For privileged roles see ../privileged-access-pim.
