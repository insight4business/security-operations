# Exchange Online

Scripts for the **exchange-online** technology in this sub-process.

## Scripts adapted from field work

Each script solves one problem. They were adapted from real operations work: replace every `ENTRE_AQUI_COM_SEU_*` marker, review, and test in a non-production tenant first.

| Script | Problem it solves | What it does | Requires | Effect | Notes |
|---|---|---|---|---|---|
| `list-mailboxes-with-forwarding-enabled.ps1` | We cannot tell which mailboxes automatically forward e-mail, a common sign of compromise or data leakage. | Lists mailboxes where DeliverToMailboxAndForward is true with the forwarding address and exports to Excel. | ExchangeOnlineManagement module; Exchange Administrator; ImportExcel | read-only | Misfiled under Distribution Lists; no Connect-ExchangeOnline line; only catches DeliverToMailboxAndForward=true (misses forwarding without keep-copy and inbox rules); hard-coded C:\Temp path. |
| `purge-emails-via-compliance-search.ps1` | A phishing or misdirected e-mail must be removed from user mailboxes. | Connects to Security & Compliance and runs a HardDelete purge action on an existing Compliance search. | ExchangeOnlineManagement (Connect-IPPSSession); eDiscovery Manager + Search And Purge role | destructive | HardDelete is irreversible; search name contains personal names ('ENTRE_AQUI_COM_SEU_NOME email to ENTRE_AQUI_COM_SEU_NOME') that must be removed; add a preview step. |
