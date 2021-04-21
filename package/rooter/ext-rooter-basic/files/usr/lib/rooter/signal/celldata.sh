#!/bin/sh

ROOTER=/usr/lib/rooter

CURRMODEM=$1
COMMPORT=$2

OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "cellinfo.gcom" "$CURRMODEM")

OX=$(echo $OX | tr 'a-z' 'A-Z')
OX=$(echo "${OX//[ \"]/}")

REGV=$(echo "$OX" | grep -o "+C5GREG:2,[0-9],[A-F0-9]\{2,6\},[A-F0-9]\{5,10\}")
if [ -n "$REGV" ]; then
	LAC=$(echo "$REGV" | cut -d, -f3)
	LAC=$(printf "%06X" 0x$LAC)
	CID=$(echo "$REGV" | cut -d, -f4)
	CID=$(printf "%010X" 0x$CID)
#	RNC=${CID:1:7}		;# gNBID will be variable length in 5G - where do we read length?
#	CID=${CID:8:2}		;# just show long cell ID for the time being
	RNC="-"
else
	REGV=$(echo "$OX" | grep -o "+CEREG:2,[0-9],[A-F0-9]\{2,4\},[A-F0-9]\{5,8\}")
	REGFMT="3GPP"
	if [ -z "$REGV" ]; then
		REGV=$(echo "$OX" | grep -o "+CEREG:2,[0-9],[A-F0-9]\{2,4\},[A-F0-9]\{1,3\},[A-F0-9]\{5,8\}")
		REGFMT="SW"
	fi
	if [ -n "$REGV" ]; then
		LAC=$(echo "$REGV" | cut -d, -f3)
		LAC=$(printf "%04X" 0x$LAC)
		if [ $REGFMT = "3GPP" ]; then
			CID=$(echo "$REGV" | cut -d, -f4)
		else
			CID=$(echo "$REGV" | cut -d, -f5)
		fi
		CID=$(printf "%08X" 0x$CID)
		RNC=${CID:1:5}
		CID=${CID:6:2}
	else
		REGV=$(echo "$OX" | grep -o "+CREG:2,[0-9],[A-F0-9]\{2,4\},[A-F0-9]\{2,8\}")
		if [ -n "$REGV" ]; then
			LAC=$(echo "$REGV" | cut -d, -f3)
			CID=$(echo "$REGV" | cut -d, -f4)
			if [ ${#CID} -gt 4 ]; then
				LAC=$(printf "%04X" 0x$LAC)
				CID=$(printf "%08X" 0x$CID)
				RNC=${CID:1:3}
				CID=${CID:4:4}
			else
				RNC="-"
			fi
		else
			LAC=""
		fi
	fi
fi
if [ -n "$LAC" ]; then
	LAC_NUM=$(printf "%d" 0x$LAC)
	LAC_NUM="  ("$LAC_NUM")"
	CID_NUM=$(printf "%d" 0x$CID)
	CID_NUM="  ("$CID_NUM")"
else
	LAC="-"
	LAC_NUM=""
	CID="-"
	RNC="-"
fi
if [ "$RNC" = "-" ]; then
	RNC_NUM=""
else
	RNC_NUM=$(printf "%d" 0x$RNC)
	RNC_NUM=" ($RNC_NUM)"
fi

echo 'LAC="'"$LAC"'"' > /tmp/cell$CURRMODEM.file
echo 'LAC_NUM="'"$LAC_NUM"'"' >> /tmp/cell$CURRMODEM.file
echo 'CID="'"$CID"'"' >> /tmp/cell$CURRMODEM.file
echo 'CID_NUM="'"$CID_NUM"'"' >> /tmp/cell$CURRMODEM.file
echo 'RNC="'"$RNC"'"' >> /tmp/cell$CURRMODEM.file
echo 'RNC_NUM="'"$RNC_NUM"'"' >> /tmp/cell$CURRMODEM.file
