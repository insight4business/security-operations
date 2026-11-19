# Problem solved : I cannot tell local accounts from corporate accounts on devices during access review.
# What it does    : Lists local users (RID >= 1000) and renames them with a '(LOCAL) ' prefix.
# Requires        : Local administrator
# Effect          : changes-state (review and test before use)
# Known issues    : Renaming accounts may break scripts/services that reference the old name; prefix hard-coded.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

$add_to_name = "(LOCAL) "
$users = Get-LocalUser
Write-Output "SID --- ENABLED --- NAME --- DESCRIPTION"
foreach ($u in $users) {
    if (([string]$u.sid).StartsWith("S-1-5-21-")) {
        $id = [string]$u.sid
        $id = [int]$id.Split("-")[-1]

        if ($id -ge 1000) { 
            $new_name = "$add_to_name$($u.name)"
            Write-Output "$($u.sid) --- $($u.Enabled) --- $($u.name) --- $($u.Description)"
            if ($u.Name.StartsWith($add_to_name)) {} 
            else {
                Rename-LocalUser -SID $u.sid -NewName $new_name
                Write-Output "CHANGED '$($u.name)' TO '$new_name'" 
            }
        }
    }
}
#Write-Output $users