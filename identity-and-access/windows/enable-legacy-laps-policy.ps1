# Problem solved : Local admin passwords are identical across devices.
# What it does    : Sets AdmPwdEnabled=1 for legacy Microsoft LAPS.
# Requires        : Local administrator
# Effect          : changes-state (review and test before use)
# Known issues    : Legacy LAPS (AdmPwd); same 'only if key missing' logic flaw; prefer Windows LAPS policy.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

$fullpath = 'HKLM:\SOFTWARE\Policies\Microsoft Services\AdmPwd'

$values_to_create = @('AdmPwdEnabled')

if ($False -eq (Test-Path $fullpath)) {
    New-Item -Path $fullpath -Force

    foreach ($v in $values_to_create) {
        New-ItemProperty -Path $fullpath -Name $v -Value 1 -PropertyType DWORD -Force
    }
}
