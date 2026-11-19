# Entra Id

Scripts for the **entra-id** technology in this sub-process.

## Scripts adapted from field work

Each script solves one problem. They were adapted from real operations work: replace every `ENTRE_AQUI_COM_SEU_*` marker, review, and test in a non-production tenant first.

| Script | Problem it solves | What it does | Requires | Effect | Notes |
|---|---|---|---|---|---|
| `report-user-mfa-methods-msol.ps1` | We cannot tell which users have MFA enabled and with which method. | Uses MSOnline to list member users with MFA state, default method, phone number and aliases, to CSV. | MSOnline (retired); ExchangeOnlineManagement; Global Reader | read-only | Marked legacy; MSOnline is retired, replace with Graph authentication methods report. Hard-coded C:\Temp output; $sharedMailboxes fetched but only partly used. |
