# Problem solved : We cannot tell which mailboxes automatically forward e-mail, a common sign of compromise or data leakage.
# What it does    : Lists mailboxes where DeliverToMailboxAndForward is true with the forwarding address and exports to Excel.
# Requires        : ExchangeOnlineManagement module; Exchange Administrator; ImportExcel
# Effect          : read-only
# Known issues    : Misfiled under Distribution Lists; no Connect-ExchangeOnline line; only catches DeliverToMailboxAndForward=true (misses forwarding without keep-copy and inbox rules); hard-coded C:\Temp path.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

### Get all mailboxes and check if they are set to forward to another mailbox

$mailboxes = Get-Mailbox

$forwardingMailboxes = $mailboxes | Where-Object {$_.DeliverToMailboxAndForward -eq 'True'} | Select-Object UserPrincipalName,DisplayName,DelivertoMailboxAndForward,ForwardingSmtpAddress

$forwardingMailboxes | Export-Excel "C:\Temp\ForwardingMailboxes.xlsx"