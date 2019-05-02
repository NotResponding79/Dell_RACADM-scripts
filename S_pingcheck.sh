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
while getopts 'u:p:i:n:h' OPTION; do
        case ${OPTION} in
                u) userName="${OPTARG}" ;;
                p) passWord="${OPTARG}" ;;
                i) IP="${OPTARG}" ;;
                n) NAME="${OPTARG}" ;;
                h) echo ''
                   echo "USAGE: $0 [-u username] [-p password] [-i IP] [-n Hostname]"
                   echo ''
                exit 0;;
        esac
done

if [ -z "${userName}" ]; then
        echo -n 'Provide the username to connect to the iDRAC:  '
        read -r userName
fi
if [ -z "${passWord}" ]; then
        echo -n "Provide the password for the ${userName} account:  "
        read -r passWord
fi
if [ -z "${IP}" ]; then
        echo -n 'Provide the IP of the server iDRAC:  '
        read -r IP
fi
if [ -z "${NAME}" ]; then
        echo -n 'Provide the Hostname of the server iDRAC:  '
        read -r NAME
fi

echo
## End of get options(input info)

echo ''
echo '==========================='
echo ''

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
RACADM="/opt/dell/srvadmin/bin/racadm --nocertwarn -r ${NAME} -u ${userName} -p ${passWord}"
not_pingable=$Sdir/not_pingable"
pingable="$dir/pingable"

## End of Variables

## Start of scripting ##
echo -e "Checking server ${BRed}$NAME${NC}...."
pingCheck=$(ping -w 1 -c 1 ${NAME} 2> /dev/null)
if [ $? -eq 0 ]; then
        echo "${NAME}" >> ${pingable}
else
        echo "${NAME}" >> ${not_pingable}
fi
exit 0

## End of scripting ##
