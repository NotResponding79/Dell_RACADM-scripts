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
output_file="${dir}/rpt_boot.csv"

## End of Variables
        
[ "${userName}" != 'admin' ] && userName="${userName}@${DOMAIN}"

## Start of scripting ##
rm -Rf "$output_file"
# Writing column headings
echo "Host,IP,FQDD1,FQDD2,FQDD3,FQDD4" > "$output_file"
# End of Writing column headings

while read line; do
        IFS=',' read -r NAME IP<<< "$line"
        echo -e "Getting configurations for ${BRed}$NAME${NC}...."
        RACADM="/opt/dell/srvadmin/bin/racadm --nocertwarn -r ${NAME} -u ${userName} -p ${passWord}"
        ## printing Hostname ##
        printf "%s, " "$NAME" >> "$output_file"
        printf "%s, " "$IP" >> "$output_file"
        FILE="${DIR}/${NAME}_boot.out"
        boot=$($RACADM get BIOS.biosbootsettings.BootSeq | grep ^BootSeq= | cut -d\= -f2 )
                printf "%s ""${boot}" >> "$output_file"
                printf "\n" >> "$output_file"

done < "$filename"
echo "" >> "$output_file"
sed -i -e 's/\r//g' "$output_file" ## Fix to remove all the weird ^M in the output file.
chmod 777 "$output_file"
## End of scripting ##
