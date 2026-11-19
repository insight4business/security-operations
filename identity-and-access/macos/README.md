# Macos

Scripts for the **macos** technology in this sub-process.

## Scripts adapted from field work

Each script solves one problem. They were adapted from real operations work: replace every `ENTRE_AQUI_COM_SEU_*` marker, review, and test in a non-production tenant first.

| Script | Problem it solves | What it does | Requires | Effect | Notes |
|---|---|---|---|---|---|
| `create-macos-local-admin-account.sh` | IT has no controlled local admin account on managed Macs for support work. | Intune shell script that waits for Setup Assistant, then creates a local admin account whose password is derived from the device serial (simple cipher + base64). | Intune shell script deployment (runs as root) on macOS | changes-state | Password is a reversible function of the serial number: weak by design; the script itself says to change the cipher before production. Feedback placeholder ENTRE_AQUI_COM_SEU_EMAIL. Default account name 'localadmin'. Rec |
| `derive-macos-admin-password-from-serial.sh` | Support staff need to recover the generated local admin password for a given Mac. | Reads the Mac serial via system_profiler and prints the cipher/base64 password used by the create-admin script. | macOS shell; must use same cipher as the create script | read-only | Documents the weak password scheme; keep only as companion to the create script and warn in README. Cipher must be changed before production. |
| `downgrade-macos-admins-to-standard.sh` | Users hold local administrator rights on Macs and we cannot enforce least privilege. | Intune shell script that demotes existing local admins to standard users (optionally only if ABM-managed), skipping the designated IT admin account. | Intune shell script deployment (root) on macOS | changes-state | Script warns it can leave a Mac with no admin account; adminaccountname exclusion must match the IT account. |
| `remove-macos-local-admin-account.sh` | The temporary local admin account is left behind on Macs after support work. | Intune shell script that removes the named local admin account and logs the result. | Intune shell script deployment (root) on macOS | destructive | Account name 'localadmin' hard-coded as variable; Microsoft-style sample header. |
