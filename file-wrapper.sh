#!/bin/bash
## Begining Secure scripting header
PATH='/bin:/usr/bin:/sbin:/usr/sbin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin'
hash -r
umask 022
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

#if [ -z "${userName}" ]; then
#        echo -n 'Provide the username to connect to the iDRAC:  '
#        read -r userName
#fi
#if [ -z "${passWord}" ]; then
#        echo -n "Provide the password for the ${userName} account:  "
#        read -r passWord
#fi
#if [ -z "${PREFIX}" ]; then
#        echo -n 'Provide the IP prefix (first three octects to scan:  '
#        read -r PREFIX
#fi
#if [ -z "${START}" ]; then
#        echo -n 'Provide the starting IP address (fourth octet) to scan:  '
#        read -r START
#fi
#if [ -z "${FINISH}" ]; then
#        echo -n 'Provide the ending IP address (fourth octet) to scan:  '
#        read -r FINISH
#fi

#echo


## VARIABLES

#Test RACADM commands, set to 1 to enable testing
TEST=0
ECHO=''
[ ${TEST} -ne 0 ] && ECHO='/bin/echo'

DomainName='FQDN'
#userName=admin
#passWord='calvin'

## End of Variables

[ "${userName}" != 'admin' ] && userName="${userName}@${DOMAIN}"

## Start of scripting ##
IFS=, # set to seperator
[ ! -f ${filename} ] && { echo "${filename} file not found"; }
[ ! -s ${script} ] && { echo "${script} file not found"; }
        while read NAME IP
        do
        ${ECHO} ${script} -n ${NAME} -i ${IP} -u ${userName} -p ${passWord}
done < ${filename}

## End of scripting ##
exit 0
