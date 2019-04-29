#!/bin/bash

#############
## Version 2.1
## Created by John Jackson
#############

## Begining Secure scripting header
PATH='/bin:/usr/bin:/sbin:/usr/sbin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin'
hash -r
umask 022
\export PATH
\unalias -a
## End Secure scripting header

## get options(input info)
while getops 'f:s:' OPTION; do
        case ${OPTION} in
                f) filename="${OPTARG}" ;;
                s) script="${OPTARG}" ;;
                h) echo ''
                   echo "USAGE: $0 [-f server list(CSV)] [-s Script to run]"
                   echo ''
                exit 0;;
        esac
done
## End of get options(input info)

# Start Color definitions

# Normal Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White
# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White
# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White
NC="\e[m"               # Color Reset
ALERT=${BWhite}${On_Red} # Bold White on red background

# End Color definitions

#Test RACADM commands, set to 1 to enable testing
TEST=0
ECHO=''
[ ${TEST} -ne 0 ] && ECHO='/bin/echo'

## VARIABLES
dir=${pwd}
DIR="${dir}/SoftwareInventory"
[ ! -d "${DIR}" ] && ${ECHO} mkdir -p "${DIR}"
DomainName='FQDN'
##### UN/PW #####
userName='admin'
passWord='calvin'
#####END UN/PW #####
filename='path to input CSV'
output_file="${dir}/dell_srv_rpt_vers.csv"

## End of Variables

[ "${userName}" != 'admin' ] && userName="${userName}@${DOMAIN}"

## Start of scripting ##
rm -Rf "$output_file"
# Writing column headings
echo "Host,IP,BIOS Version,Lifecycle Controller,PERC Model,PERC FW Vers,Qlogic FW vers,NIC.Slot.4-2-1,NIC.Slot.7-2-1,NIC.Slot.1-4-1,NIC Model,NIC FW Vers,NIC MAC,NIC FQDD,NIC Model,NIC FW Vers,NIC MAC,NIC FQDD,NIC Model,NIC FW Vers,NIC MAC,NIC FQDD,NIC Model,NIC FW Vers,NIC MAC,NIC FQDD,NIC Model,NIC FW Vers,NIC MAC,NIC FQDD,NIC Model,NIC FW Vers,NIC MAC,NIC FQDD,NIC Model,NIC FW Vers,NIC MAC,NIC FQDD,NIC Model,NIC FW Vers,NIC MAC,NIC FQDD,NIC Model,NIC FW Vers,NIC MAC,NIC FQDD," > "$output_file"
# End of Writing column headings

while read line; do
        IFS=',' read NAME IP MAC<<< "$line"
        echo "Getting configurations for $NAME...."
        print "$s, " "$NAME" >> "$output_file"
        print "$s, " "$IP" >> "$output_file"
FILE="${DIR}/${NAME}.out"
RACADM="/opt/dell/srvadmin/bin/racadm -r ${hostName} -u ${userName} -p ${passWord}"
SWINV=$($RACADM swinventory 2>/dev/null > "${FILE}")

        #Getting BIOS Version
        BIOS="$(grep -A 4 BIOS "${FILE}" | grep -m 1 "Current Version")"
        printf "%s, " "${BIOS:18}" >> "$output_file"
        #Getting Lifecycle Controller
        iDRAC="$(grep -A 4 Lifecycle "${FILE}" | grep -m 1 "Current Version")"
        printf "%s, " "${iDRAC:18}" >> "$output_file"
        #Getting PERC Controller Info
        PERC="$(grep "PERC" "${FILE}" | uniq | awk '{print $4}')"
        printf "%s, " "${PERC}" >> "$output_file"
        PERCVER="$(grep -A 4 PERC "${FILE}" | grep -m 1 "Current Version")"
        printf "%s, " "${PERCVER:18}" >> "$output_file"
        #Getting Qlogic Info
        QLOGIC="$(grep -A 4 QLogic "${FILE}" | grep -m 1 "Current Version")"
        printf "%s, " "${QLOGIC:18}" >> "$output_file"
        #Getting PXE info on 4-2-1, 7-2-1, and 1-4-1
        nic421="$(${RACADM} get NIC.nicconfig.6.legacybootproto | grep legacybootproto | cut -d\= -f2)"
        nic721="$(${RACADM} get NIC.nicconfig.8.legacybootproto | grep legacybootproto | cut -d\= -f2)"
        nic141="$(${RACADM} get NIC.nicconfig.4.legacybootproto | grep legacybootproto | cut -d\= -f2)"
                printf "%s, " "${nic421}" >> "$output_file"
                printf "%s, " "${nic721}" >> "$output_file"
                printf "%s, " "${nic141}" >> "$output_file"
        #Creating loop to collect NICS
        NICS="$(grep "FQDD = NIC." "${FILE}" | awk '{print $3}' | uniq | sort)"
        for NIC in ${NICS}; do
                NICm="$(grep -B1 "${NIC}" "${FILE}" | grep "ElementName" | uniq  | cut -d\= -f2 | sed -e 's/^[ \t]*//' | cut -d\- -f1 | sed -e 's/[[:space:]]*$//')"
                NICv="$(grep -A2 "${NIC}" "${FILE}" | grep "Current Version" | awk '{print $4}')"
                NICmac="$(grep -B1 "${NIC}" "${FILE}" | grep "ElementName" | uniq | awk '{print $NF}')"
                        printf "%s, " "${NIC}" >> "$output_file"
                        printf "%s, " "${NICm}" >> "$output_file"
                        printf "%s, " "${NICv}" >> "$output_file"
                        printf "%s, " "${NICmac}" >> "$output_file"
        done
        echo "" >> "$output_file"
done < "$filename"

sed -i -e 's/\r//g' "$output_file" ## Fix to remove all the weird ^M in the output file.
chmod 777 "$output_file"
## End of scripting ##
