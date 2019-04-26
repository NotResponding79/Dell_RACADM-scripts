#!/bin/bash
## Begining Secure scripting header
PATH='/bin:/usr/bin:/sbin:/usr/sbin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin'
hash -r
umask 022
## End Secure scripting header

## get options(input info)
while getops 'u:p:s:e:r:h' OPTION; do
        case ${OPTION} in
                u) userName="${OPTARG}" ;;
                p) passWord="${OPTARG}" ;;
                r) PREFIX="${OPTARG}" ;;
                s) START="${OPTARG}" ;;
                e) FINISH="${OPTARG}" ;;
                h) echo ''
                   echo "USAGE: $0 [-u username] [-p password] [-r IP Prefix] [-s Starting IP] [-e Last IP]"
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
if [ -z "${PREFIX}" ]; then
        echo -n 'Provide the IP prefix (first three octects to scan:  '
        read -r PREFIX
fi
if [ -z "${START}" ]; then
        echo -n 'Provide the starting IP address (fourth octet) to scan:  '
        read -r START
fi
if [ -z "${FINISH}" ]; then
        echo -n 'Provide the ending IP address (fourth octet) to scan:  '
        read -r FINISH
fi

echo
## End of get options(input info)

## VARIABLES
OUTFILEA='/tmp/WWPN-FabicA.csv'
OUTFILEB='/tmp/WWPN-FabicB.csv'
DOMAIN='s70.vmis.nro.ic.gov'
## End of Variables

[ "${userName}" != 'admin' ] && userName="${userName}@${DOMAIN}"

## Start of scripting ##
[ -f ${OUTFILEA} ] && rm ${OUTFILEA}
[ -f ${OUTFILEB} ] && rm ${OUTFILEB}
date > ${OUTFILEA}
date > ${OUTFILEB}

for (( i=${START}; i<=${FINISH}; i++ )); do
        ipAddr="${PREFIX} .${i}"
        hostName=$(dig +short -x ${ipAddr} | cut -d\. -f1-5 )
        shortName=$(dig +short -x ${ipAddr} | cut -d\. -f1 )
        RACADM="/opt/dell/srvadmin/bin/racadm -r ${hostName} -u ${userName} -p ${passWord}"
        
        pingCheck=$(ping -w 1 -c 1 ${ipAddr} 2> /dev/null)
        if [ $? -eq 0 ] ; then
        echo "Collecting WWPN from ${hostName}"
        echo "# ${hostName}" >> ${OUTFILEA}
        ${RACADM} hwinventory FC.Slot.5-1 2>/dev/null | grep ^WWPN | sed "s/^WWPN:[[:space]]*/${shortName},/" | sed 's/micp/svcp/g' | sed 's/svr/esx/g' | tr "[:upper:] [:lower:] >> ${OUTFILEA}"
        [ $? -ne 0 ] && exit 1
        ${RACADM} hwinventory FC.Slot.5-2 2>/dev/null | grep ^WWPN | sed "s/^WWPN:[[:space]]*/${shortName},/" | sed 's/micp/svcp/g' | sed 's/svr/esx/g' | tr "[:upper:] [:lower:] >> ${OUTFILEB}"
        fi
done

date >> ${OUTFILEA}
date >> ${OUTFILEB}

exit 0

## End of scripting ##
