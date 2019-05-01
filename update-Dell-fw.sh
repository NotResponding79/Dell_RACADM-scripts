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
while getops 'u:p:s:e:r:h' OPTION; do
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
DIR="${dir}/SoftwareInventory"
[ ! -d "${DIR}" ] && ${ECHO} mkdir -p "${DIR}"
##### UN/PW #####
#userName='admin'
#passWord='calvin'
#####END UN/PW #####
#filename='path to input CSV'
#output_file="${dir}/rpt_boot.csv"
RACADM="/opt/dell/srvadmin/bin/racadm --nocertwarn -r ${NAME} -u ${userName} -p ${passWord}"
FILE="${DIR}/${NAME}.out"
shortName=${NAME}
hostname=$(nslookup "${shortName}" | grep ^Name | awk '{print $2}')
if [ -z "${hostname}" ]; then
        echo "Can't find hostname ${shortName}"
        exit 1
fi
DOMAIN=$(echo "${hostname}" | cut -c1-3,16-)
if [[ "${HOSTNAME}" =~ 'cmf' ]]; then
        declare PXE='xxx.xxx.xxx.xxx'
else
        case ${DOMAIN} in
                r46*)
                        declare PXE='xxx.xxx.xxx.xxx' ;;
                r35*)
                        declare PXE='xxx.xxx.xxx.xxx' ;;
                cm*)
                        echo "${shortName} does not appear to be a physical iDRAC"
                        exit 1
                        ;;
        esac
fi


## End of Variables
        
[ "${userName}" != 'admin' ] && userName="${userName}@${DOMAIN}"
pingCheck=$(ping -w 1-c 1 "${hostname}" 2> /dev/null)
if [ $? -eq 0 ] ; then
        echo -e "Getting configurations for ${BRed}$NAME${NC}...."
        fwUpdate=0
## Start of scripting ##
declare -r baseBIOS='1.5.6'
declare -r baseINTEL='18.8.9'
declare -r baseiDRAC='3.15.17.15'
declare -r basePERC='25.5.3.0005'
declare -r baseQLOGIC='14.04.09'

SWINV=$(${RACADM} swinventory 2>/dev/null | egrep '^ElementName|Current Version' | uniq > "${FILE}" )
BIOS=$(grep -A1 '^ElementName = BIOS' "${FILE}" | grep ^Current | cut -d' ' -f4)
INTEL350=$(grep -A1 'I350' "${FILE}" | grep ^Current | uniq | cut -d' ' -f4)
INTEL710=$(grep -A1 '^ElementName = Intel(R) Etherent Converged Network Adapter X710' "${FILE}" | grep ^Current | uniq | cut -d' ' -f4)
iDRAC=$(grep -A1 '^ElementName = Lifecycle Controller' "${FILE}" | grep ^Current | cut -d' ' -f4)
PERC=$(grep -A1 'PERC H730P' "${FILE}" | grep ^Current | uniq | cut -d' ' -f4)
QLOGIC=$(grep -A1 '^ElementName = QLogic' "${FILE}" | grep ^Current | uniq | cud -d' ' -f4)
EMULEX=$(grep -A1 'Emulex LightPulse' "${FILE}" | grep ^Current | uniq | cut -d' ' -f4)
MELLANOX=$(grep -A1 'Mellanox ConnectX-3 Pro 40GbE QSFP+ Adapter' "${FILE}" | grep ^Current | uniq | cut -d' ' -f4)

if [ -z "${BIOS}" ]; then
        echo "Wrong username / password"
        exit 1
fi
if [ ${TEST} -ne 0 ]; then
        echo "Detected iDRAC firmware ${iDRAC}"
        echo "Detected BIOS ${BIOS}"
        echo "Detected Intel I350 ${INTEL350}"
        echo "Detected Intel X710 ${INTEL710}"
        [ -n "${PERC}" ]&& echo "Detected PERC H730 ${PERC}"
        [ -n "${QLOGIC}" ]&& echo "Detected QLogic ${QLOGIC}"
        [ -n "${EMULEX}" ]&& echo "Detected Emulex ${EMULEX}"
        [ -n "${MELLANOX}" ]&& echo "Detected Mellanox ${MELLANOX}"
fi
${ECHO} "${RACADM}" jobqueue delete --all 2>/dev/null
if [[ ! "${BIOS}" =~ ${baseBIOS} ]]; then
        ((fwUpdate++))
        echo "Applying BIOS ${baseBIOS}"
        echo ''
# BEGIN To address potential issue with BIOS updates with BIOS less than 1.3.7
        ${ECHO} "${RACADM}" jobqueue delete --all 2>/dev/null
        ${ECHO} "${RACADM}" serveraction powerdown
        ${ECHO} sleep 5
        ${ECHO} "${RACADM}" serveraction powerup
        ${ECHO} sleep 5
        ${ECHO} "${RACADM}" serveraction powercycle
# END To address potential issue with BIOS updates with BIOS less than 1.3.7
        ${ECHO} "${RACADM}" update -f BIOS_5KNGY_WN64_1.5.6.EXE -l ${PXE}:/global01/products/Dell/BIOS/R740/1.5.6 2>/dev/null
        ${ECHO} "${RACADM}" jobqueue view 2>/dev/null
        echo ''
fi
if [[ ! "${INTEL350}" =~ ${baseINTEL} ]]; then
        ((fwUpdate++))
        echo "Applying Intel I350 firmware ${baseINTEL}"
        echo ''
        ${ECHO} "${RACADM}" update -f Network_Firmware_3W5Y5_WN64_18.8.9_A00_01.EXE -l ${PXE}:/global01/products/Dell/Intel_NICs/18.8.9 2>/dev/null
        echo ''
fi
if [[ ! "${INTEL710}" =~ ${baseINTEL} ]]; then
        ((fwUpdate++))
        echo "Applying Intel X710 firmware ${baseINTEL}"
        echo ''
        ${ECHO} "${RACADM}" update -f Network_Firmware_3W5Y5_WN64_18.8.9_A00_01.EXE -l ${PXE}:/global01/products/Dell/Intel_NICs/18.8.9 2>/dev/null
        echo ''
fi
if [[ ! "${PERC}" =~ ${basePERC} ]]; then
        ((fwUpdate++))
        echo "Applying Applying PERC H730 firmware ${baseINTEL}"
        echo ''
        ${ECHO} "${RACADM}" update -f SAS-RAID_Firmware_C58TW_WN64_25.5.3.0005_All.EXE -l ${PXE}:/global01/products/Dell/PERC/25.5.3.0005 2>/dev/null
        echo ''
fi
if [[ ! "${iDRAC}" =~ ${baseiDRAC} ]]; then
        ((fwUpdate++))
        echo "Applying iDRAC firmware ${baseiDRAC}"
        echo ''
        ${ECHO} "${RACADM}" update -f iDRAC-with-Lifecycle-Controller_Firmware_3NCPY_WN64_3.15.17.15_A00.EXE -l ${PXE}:/global01/products/Dell/iDRAC/3.15.17.15 2>/dev/null
        ${ECHO} sleep 10
        ${ECHO} "${RACADM}" racreset
        ${ECHO} "${RACADM}" jobqueue view 2>/dev/null
        # 138 seconds to upload and reboot iDRAC
        # 51 seconds to begin responding again
        # 81 seconds to accepting logins
        # 270 seconds total, round up to 300
        echo 'Sleeping for 5 minutes for the iDRAC to return to service...'
        ${ECHO} sleep 300
        ${ECHO} "${RACADM}" jobqueue view 2>/dev/null
        echo ''
fi
if [ ${fwUpdate} -ne 0 ]; then
        echo "Rebooting ${NAME} to apply firmware updates."
        ${ECHO} "${RACADM}" serveraction powercycle 2>/dev/null
fi
        echo '======================='
        echo ''
fi
        
## End of scripting ##
exit 0
