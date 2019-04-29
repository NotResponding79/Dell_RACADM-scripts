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
##### UN/PW #####
userName='admin'
passWord='calvin'
#####END UN/PW #####
filename='path to input CSV'
output_file="${dir}/diskinfo.csv"

## End of Variables

[ "${userName}" != 'admin' ] && userName="${userName}@${DOMAIN}"

## Start of scripting ##
rm -Rf "$output_file"
# Writing column headings
echo "Host,IP,RAID Cntr Model,Slot,VD Name,VD Type,VD Name,VD Type,Bay FQDD,Bay Drive Protocol,Bay Drive Type,Bay Drive Size,Bay FQDD,Bay Drive Protocol,Bay Drive Type,Bay Drive Size,Bay FQDD,Bay Drive Protocol,Bay Drive Type,Bay Drive Size,Bay FQDD,Bay Drive Protocol,Bay Drive Type,Bay Drive Size,Bay FQDD,Bay Drive Protocol,Bay Drive Type,Bay Drive Size,Bay FQDD,Bay Drive Protocol,Bay Drive Type,Bay Drive Size,Bay FQDD," > "$output_file"
# End of Writing column headings

while read line; do
        IFS=',' read -r NAME IP<<< "$line"
        echo -e "Getting configurations for ${BRed}$NAME${NC}...."
        #FILE="${DIR}/${NAME}.out"
        RACADM="/opt/dell/srvadmin/bin/racadm --nocertwarn -r ${NAME} -u ${userName} -p ${passWord}"
        ## printing Hostname ##
        printf "%s, " "$NAME" >> "$output_file"
        printf "%s, " "$IP" >> "$output_file"
        ## setting file locations and info
        CONTR="${DIR}/${NAME}_CONTR.out"
        VSDKS="${DIR}/${NAME}_VSDKS.out"
        PSDKS="${DIR}/${NAME}_PSDKS.out"
        VDISKS="$(${RACADM} storage get vdisks -o > "${VSDKS}" 2>/dev/null)"
        PDISKS="$(${RACADM} storage get pdisks -o -p MediaType,BusProtocol,Size 2>/dev/null | egrep -A4 "Disk.Bay" > "${PSDKS}")"
        CONTRS="$(${RACADM} storage get controllers -o -p Name > "${CONTR}" 2>/dev/null)"
        
        ## Hack to clean up wierd add ^M and spaces in output files ##
        sed -i -e 's/\r//g' "$CONTR" # removes ^M
        sed -i -e 's/\r//g' "$VSDKS" # removes ^M
        sed -i -e 's/\r//g' "$PSDKS" # removes ^M
        sed -i -e 's/^[ \t]*//' "$CONTR" # removes spaces before
        sed -i -e 's/^[ \t]*//' "$VSDKS" # removes spaces before
        sed -i -e 's/^[ \t]*//' "$PSDKS" # removes spaces before
        ###
        PERC="$(grep "Name" "${CONTR}" | grep "PERC" | awk '{print $4}' )"
        SLOT="$(grep Disk.Bay.0 "${PSDKS}" | cut -f7 -d. )"
        DISKBAYS="$(grep ^Disk.Bay "${PSDKS}")"
                printf "%s, " "${PERC}" >> "$output_file"
                printf "%s, " "${SLOT}" >> "$output_file"
        ## Virtual Disks
        VD0="$(grep Disk.Virtual.0 "${VSDKS}")"
        VD0_T="$(grep -A 12 Disk.Virtual.0 "${VSDKS}" | grep MediaType | grep -o 'HDD\|SDD')"
        VD0_N="$(grep -A 12 Disk.Virtual.0 "${VSDKS}" | grep Name | cut -d\= -f2 | sed -e 's/^[ \t]*//' | sed -e 's/[[:space:]]*$//')"
        VD1="$(grep Disk.Virtual.1 "${VSDKS}")"
        VD1_T="$(grep -A 12 Disk.Virtual.1 "${VSDKS}" | grep MediaType | grep -o 'HDD\|SDD')"
        VD1_N="$(grep -A 12 Disk.Virtual.1 "${VSDKS}" | grep Name | cut -d\= -f2 | sed -e 's/^[ \t]*//' | sed -e 's/[[:space:]]*$//')"
                printf "%s, " "${VD0_N}" >> "$output_file"
                printf "%s, " "${VD0_T}" >> "$output_file"
                printf "%s, " "${VD1_N}" >> "$output_file"
                printf "%s, " "${VD1_T}" >> "$output_file"
        ## Physical Disks ##
        for DISKBAY in ${DISKBAYS}; do
                VDSKSm="$(grep -A3 "${DISKBAY}" "${PSDKS}" | grep MediaType | awk '{print $NF}')"
                VDSKSp="$(grep -A3 "${DISKBAY}" "${PSDKS}" | grep BusProtocol | awk '{print $NF}')"
                VDSKSs="$(grep -A3 "${DISKBAY}" "${PSDKS}" | grep Size | awk '{print $3 " " $4}')"
                        printf "%s, " "${DISKBAY}" >> "$output_file"
                        printf "%s, " "${VDSKSp}" >> "$output_file"
                        printf "%s, " "${VDSKSm}" >> "$output_file"
                        printf "%s, " "${VDSKSs}" >> "$output_file"
        done
        printf "\n" >> "$output_file"
done < "$filename"

sed -i -e 's/\r//g' "$output_file" ## Fix to remove all the weird ^M in the output file.
chmod 777 "$output_file"
## End of scripting ##
