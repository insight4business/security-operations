#!/usr/bin/env bash
# Problem solved : Support staff need to recover the generated local admin password for a given Mac.
# What it does    : Reads the Mac serial via system_profiler and prints the cipher/base64 password used by the create-admin script.
# Requires        : macOS shell; must use same cipher as the create script
# Effect          : read-only
# Known issues    : Documents the weak password scheme; keep only as companion to the create script and warn in README. Cipher must be changed before production.
# Origin          : adapted from field work; replace every ENTRE_AQUI_COM_SEU_* marker with your own value

#set -x

############################################################################################
##
## Script to generate Admin Password from Serial Number
##
###########################################

## Copyright (c) 2020 Microsoft Corp. All rights reserved.
## Scripts are not supported under any Microsoft standard support program or service. The scripts are provided AS IS without warranty of any kind.
## Microsoft disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a
## particular purpose. The entire risk arising out of the use or performance of the scripts and documentation remains with you. In no event shall
## Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever
## (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary
## loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility
## of such damages.
## Feedback: ENTRE_AQUI_COM_SEU_EMAIL@example.com

##
## Notes
##
## This script is to support createAdminAccount.sh the cipher used in that script must match the cipher used here to generate the correct password
## i.e. ABCDEF000009 becomes S0xNTk9QNDQ0NDQzCg==
##
## WARNING: It is strongly recommended to change the cipher on line 45 before deploying into production

# echo -ne "Enter device serial number :"
# read serial
serial=`system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'`
password=`echo $serial | tr '[A-Z]' '[K-ZA-J]' | tr 0-9 4-90-3 | base64`
echo "Password: $password"