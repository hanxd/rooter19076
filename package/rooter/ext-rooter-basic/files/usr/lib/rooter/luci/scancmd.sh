#!/bin/sh

ROOTER=/usr/lib/rooter

log() {
	logger -t "Scan Command" "$@"
}

fibdecode() {
	j=$1
	tdec=$2
	mod=$3
	length=${#j}
	jx=$j
	length=${#jx}

	str=""
	i=$((length-1))
	while [ $i -ge 0 ]
	do
		dgt="0x"${jx:$i:1}
		DecNum=`printf "%d" $dgt`
		Binary=
		Number=$DecNum
		while [ $DecNum -ne 0 ]
		do
			Bit=$(expr $DecNum % 2)
			Binary=$Bit$Binary
			DecNum=$(expr $DecNum / 2)
		done
		if [ -z $Binary ]; then
			Binary="0000"
		fi
		len=${#Binary}
		while [ $len -lt 4 ]
		do
			Binary="0"$Binary
			len=${#Binary}
		done
		revstr=""
		length=${#Binary}
		ii=$((length-1))
		while [ $ii -ge 0 ]
		do
			revstr=$revstr${Binary:$ii:1}
			ii=$((ii-1))
		done
		str=$str$revstr
		i=$((i-1))
	done
	len=${#str}
	ii=0
	lst=""
	sep=","
	hun=101
	if [ $mod = "1" ]; then
		sep=":"
		hun=1
	fi
	while [ $ii -lt $len ]
	do
		bnd=${str:$ii:1}
		if [ $bnd -eq 1 ]; then
			if [ $tdec -eq 1 ]; then
				jj=$((ii+hun))
			else
				if [ $ii -lt 9 ]; then
					jj=$((ii+501))
				else
					jj=$((ii+5001))
				fi
			fi
			if [ -z $lst ]; then
				lst=$jj
			else
				lst=$lst$sep$jj
			fi
		fi
		ii=$((ii+1))
	done
}

CURRMODEM=$(uci get modem.general.miscnum)
COMMPORT="/dev/ttyUSB"$(uci get modem.modem$CURRMODEM.commport)
uVid=$(uci get modem.modem$CURRMODEM.uVid)
uPid=$(uci get modem.modem$CURRMODEM.uPid)
model=$(uci get modem.modem$CURRMODEM.model)
ACTIVE=$(uci get modem.pinginfo$CURRMODEM.alive)
uci set modem.pinginfo$CURRMODEM.alive='0'
uci commit modem
L1=$(uci get modem.modem$CURRMODEM.L1)
length=${#L1}
L1="${L1:2:length-2}"
L1=$(echo $L1 | sed 's/^0*//')
L2=$(uci get modem.modem$CURRMODEM.L2)
L1X=$(uci get modem.modem$CURRMODEM.L1X)

case $uVid in
	"2c7c" )
		M2='AT+QENG="neighbourcell"'
		case $uPid in
			"0125" ) # EC25-A
				EC25=$(echo $model | grep "EC25-AF")
				if [ ! -z $EC25 ]; then
					MX='400000000000003818'
				else
					MX='81a'
				fi
				M4='AT+QCFG="band",0,'$MX',0'
			;;
			"0306" )
				M1='AT+GMR'
				OX=$($ROOTER/gcom/gcom-locked "$CPORT" "run-at.gcom" "$CURRMODEM" "$M1")
				EP06E=$(echo $OX | grep "EP06E")
				if [ ! -z $EP06E ]; then # EP06E
					M3='1a080800d5'
				else # EP06-A
					M3="2000001003300185A"
				fi
				M4='AT+QCFG="band",0,'$M3',0'
			;;
			"0512" ) # EM12-G
				M3="2000001E0BB1F39DF"
				M4='AT+QCFG="band",0,'$M3',0'
			;;
			"0620" ) # EM20-G
				EM20=$(echo $model | grep "EM20")
				if [ ! -z $EM20 ]; then
					M3="20000A7E03B0F38DF"
					M4='AT+QCFG="band",0,'$M3',0'
					
					fibdecode $M3 1 1
					log "Fake EM160 Set to All $lst"
					
				else
					mask="20000A7E0BB0F38DF"
					fibdecode $mask 1 1
					M4='AT+QNWPREFCFG="lte_band",'$lst
				fi
			;;
			* )
				M3="AT"
				M4='AT+QCFG="band",0,'$M3',0'
			;;
		esac
		
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$M4")
		log "$OX"
		sleep 5
	;;
	"1199" )
		M2='AT!LTEINFO?'
		case $uPid in

			"68c0"|"9041"|"901f" ) # MC7354 EM/MC7355
				M3="101101A"
				M3X="0"
			;;
			"9070"|"9071"|"9078"|"9079"|"907a"|"907b" ) # EM/MC7455
				M3="100030818DF"
				M3X="0"
			;;
			"9090"|"9091"|"90b1" ) # EM7565
				EM7565=$(echo "$model" | grep "7565")
				if [ ! -z $EM7565 ]; then
					M3="2100BA0E19DF"
					M3X="2"
				else
					EM7511=$(echo "$model" | grep "7511")
					if [ ! -z $EM7511 ]; then # EM7511
						M3="A300BA0E38DF"
						M3X="2"
					else
						M3="87000300385A"
						M3X="42"
					fi
				fi

			;;
			* )
				M3="AT"
			;;
		esac
		M1='AT!ENTERCND="A710"'
		M4='AT!BAND=1F,"Test",0,'$M3,$M3X
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$M1")
		log "$OX"
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$M4")
		log "$OX"
		M4='AT!BAND=00;!BAND=1F'
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$M4")
		log "$OX"
	;;
	* )
		rm -f /tmp/scanx
		echo "Scan for Neighbouring cells not supported" >> /tmp/scan
		uci set modem.pinginfo$CURRMODEM.alive=$ALIVE
		uci commit modem
		exit 0
	;;
esac

export TIMEOUT="10"
OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$M2")
OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$M2")
log "$OX"
ERR=$(echo "$OX" | grep "ERROR")
if [ ! -z $ERR ]; then
	OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$M2")
	OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$M2")
	log "$OX"
fi
if [ ! -z $ERR ]; then
	OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$M2")
	OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$M2")
	log "$OX"
fi
log "$OX"
echo "$OX" > /tmp/scanx
rm -f /tmp/scan
echo "Cell Scanner Start ..." > /tmp/scan
echo " " >> /tmp/scan
flg=0
while IFS= read -r line
do
	case $uVid in
	"2c7c" )
		qm=$(echo $line" " | grep "+QENG:" | tr -d '"' | tr " " ",")
		if [ "$qm" ]; then
			INT=$(echo $qm | cut -d, -f3)
			BND=$(echo $qm | cut -d, -f5)
			RSSI=$(echo $qm | cut -d, -f9)
			BAND=$(/usr/lib/rooter/chan2band.sh $BND)
			if [ "$INT" = "intra" ]; then
				echo "Band : $BAND    Signal : $RSSI (dBm) (current connected band)" >> /tmp/scan
			else
				echo "Band : $BAND    Signal : $RSSI (dBm)" >> /tmp/scan
			fi
			flg=1
		fi
	;;
	"1199" )
		qm=$(echo $line" " | grep "Serving:" | tr -d '"' | tr " " ",")
		if [ "$qm" ]; then
			read -r line
			qm=$(echo $line" " | tr -d '"' | tr " " ",")
			BND=$(echo $qm | cut -d, -f1)
			BAND=$(/usr/lib/rooter/chan2band.sh $BND)
			RSSI=$(echo $qm | cut -d, -f13)
			echo "Band : $BAND    Signal : $RSSI (dBm) (current connected band)" >> /tmp/scan
			flg=1
		else
			qm=$(echo $line" " | grep "InterFreq:" | tr -d '"' | tr " " ",")
			log "$line"
			if [ "$qm" ]; then
				while [ 1 = 1 ]
				do
					read -r line
					log "$line"
					qm=""
					qm=$(echo $line" " | grep ":" | tr -d '"' | tr " " ",")
					if [ "$qm" ]; then
						break
					fi
					qm=$(echo $line" " | grep "OK" | tr -d '"' | tr " " ",")
					if [ "$qm" ]; then
						break
					fi
					qm=$(echo $line" " | tr -d '"' | tr " " ",")
					if [ "$qm" = "," ]; then
						break
					fi
					BND=$(echo $qm | cut -d, -f1)
					BAND=$(/usr/lib/rooter/chan2band.sh $BND)
					RSSI=$(echo $qm | cut -d, -f8)
					echo "Band : $BAND    Signal : $RSSI (dBm)" >> /tmp/scan
					flg=1
				done
				break
			fi
		fi
	;;
	* )
	
	;;
	esac
done < /tmp/scanx

rm -f /tmp/scanx
if [ $flg -eq 0 ]; then
	echo "No Neighbouring cells were found" >> /tmp/scan
fi
echo " " >> /tmp/scan
echo "Done" >> /tmp/scan

case $uVid in
	"2c7c" )
		if [ $uPid = 0620 ]; then
			EM20=$(echo $model | grep "EM20")
			if [ ! -z $EM20 ]; then
				M2='AT+QCFG="band",0,'$L1',0'
				
				fibdecode $L1 1 1
				log "Fake EM160 Band Set "$lst
			else
				fibdecode $L1 1 1
				M2='AT+QNWPREFCFG="lte_band",'$lst
			fi
		else
			M4='AT+QCFG="band",0,'$L1',0'
		fi
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$M4")
		log "$OX"
	;;
	"1199" )
		M1='AT!ENTERCND="A710"'
		M4='AT!BAND=1F,"Test",0,'$L1X,$L2
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$M1")
		log "$OX"
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$M4")
		log "$OX"
		M4='AT!BAND=00;!BAND=1F'
		OX=$($ROOTER/gcom/gcom-locked "$COMMPORT" "run-at.gcom" "$CURRMODEM" "$M4")
		log "$OX"
	;;
esac
uci set modem.pinginfo$CURRMODEM.alive=$ACTIVE
uci commit modem

log "Finished Scan"