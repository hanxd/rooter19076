#!/bin/sh

. /lib/functions.sh
 
ROOTER=/usr/lib/rooter
ROOTER_LINK="/tmp/links"

log() {
logger -t "Custom Ping Test " "$@"
}

CURRMODEM=1
CPORT=$(uci -q get modem.modem$CURRMODEM.commport)
DELAY=$(uci get ping.ping.delay)

RETURN_CODE_1=$(curl -m 10 -s -o /dev/null -w "%{http_code}" http://www.google.com/)
RETURN_CODE_2=$(curl -m 10 -s -o /dev/null -w "%{http_code}" http://www.example.org/)
RETURN_CODE_3=$(curl -m 10 -s -o /dev/null -w "%{http_code}" https://github.com)

if [[ "$RETURN_CODE_1" != "200" &&  "$RETURN_CODE_2" != "200" &&  "$RETURN_CODE_3" != "200" ]]; then
	log "Bad Ping Test"
	ATCMDD="AT+CFUN=1,1"
	$ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD"
	sleep $DELAY
	tries=0
	while [ $tries -lt 9 ]
	do
		CONN=$(uci -q get modem.modem$CURRMODEM.connected)
		if [ $CONN = "1" ]; then
			RETURN_CODE_1=$(curl -m 10 -s -o /dev/null -w "%{http_code}" http://www.google.com/)
			RETURN_CODE_2=$(curl -m 10 -s -o /dev/null -w "%{http_code}" http://www.example.org/)
			RETURN_CODE_3=$(curl -m 10 -s -o /dev/null -w "%{http_code}" https://github.com)
			if [[ "$RETURN_CODE_1" != "200" &&  "$RETURN_CODE_2" != "200" &&  "$RETURN_CODE_3" != "200" ]]; then
				reboot -f
			fi
			log "Second Ping Test Good"
			exit 0
		else
			sleep 20
			tries=$((tries+1))
		fi
	done
	reboot -f
fi
exit 0
