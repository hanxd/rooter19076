#!/bin/sh

ROOTER=/usr/lib/rooter

log() {
	logger -t "BandMasking" "$@"
}

#
# remove for band locking
#
if [ ! -e /etc/bandlock ]; then
	exit 0
fi

reverse() {
	LX=$1
	length=${#LX}
	jx="${LX:2:length-2}"
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
	revstr=$str"0000000000000000000000000000000000000000000000000000000000000000000000"
}

rm -f /tmp/bmask
CURRMODEM=$(uci get modem.general.miscnum)
CPORT="/dev/ttyUSB"$(uci get modem.modem$CURRMODEM.commport)
uVid=$(uci get modem.modem$CURRMODEM.uVid)
uPid=$(uci get modem.modem$CURRMODEM.uPid)
ATCMDD="AT+CGMM"
model=$($ROOTER/gcom/gcom-locked "/dev/ttyUSB$CPORT" "run-at.gcom" "$CURRMODEM" "$ATCMDD")
L1=$(uci -q get modem.modem$CURRMODEM.L1)
L5=$(uci -q get modem.modem$CURRMODEM.L5)

if [ ! $L1 ]; then
	exit 0
fi

CA3=""
M5="x"
M6="x"
case $uVid in
	"2c7c" )
		case $uPid in
			"0125" ) # EC25-A
				CA=""
				M1='ATI'
				OX=$($ROOTER/gcom/gcom-locked "$CPORT" "run-at.gcom" "$CURRMODEM" "$M1")
				REV=$(echo $OX" " | grep -o "Revision: .\+ OK " | tr " " ",")
				MODL=$(echo $REV | cut -d, -f2)
				EC25AF=$(echo $MODL | grep "EC25AFFAR")
				if [ ! -z $EC25AF ]; then
					M2='01011000000111000000000000000000000000000000000000000000000000000100001'
				else
					M2='0101100000011'
				fi
			;;
			"0306" ) # EP06-A
				M1='AT+GMR'
				OX=$($ROOTER/gcom/gcom-locked "$CPORT" "run-at.gcom" "$CURRMODEM" "$M1")
				EP06E=$(echo $OX | grep "EP06E")
				if [ ! -z $EP06E ]; then # EP06E
					M2='101010110000000000010000000100010000010110'
					CA="ep06e-bands"
				else # EP06A
					M2='010110100001100010000000110011000000000010000000000000000000000001'
					CA="ep06a-bands"
				fi
			;;
			"0512" ) # EM12-G
				M2='111110111001110011111000110111010000011110000000000000000000000001'
				CA="em12-2xbands"
				CA3="em12-3xbands"
			;;
			"0620" ) # EM20-G
				EM20=$(echo $model | grep "EM20")
				if [ ! -z $EM20 ]; then
					M2='111110110001110011110000110111000000011111100101000000000000000001'
					CA="em20-2xbands"
					CA3="em20-3xbands"
					CA4="em20-4xbands"
				else
					M2='111110110001110011110000110111010000011111100101000000000000000001'
					CA="em20-2xbands"
					CA3="em20-3xbands"
					CA4="em20-4xbands"
				fi
			;;
		esac
	;;
	"1199" )
		case $uPid in

			"68c0"|"9041"|"901f" ) # MC7354 EM/MC7355
				M2='0101100000001000100000001'
				CA=""
			;;
			"9070"|"9071"|"9078"|"9079"|"907a"|"907b" ) # EM/MC7455
				M2='11111011000110000001000011000000000000001'
				CA="mc7455-bands"
			;;
			"9090"|"9091"|"90b1" )
				EM7565=$(echo "$model" | grep "7565")
				if [ ! -z $EM7565 ]; then # EM7565
					M2='111110111001100001110000010111010000000011100101000000000000000001'
					CA="em7565-2xbands"
					CA3="em7565-3xbands"
				else
					EM7511=$(echo "$model" | grep "7511")
					if [ ! -z $EM7511 ]; then # EM7511
						M2='1111101100011100011100000101110100000000110001010000000000000000010'
						CA="em7511-2xbands"
						CA3="em7511-3xbands"
					else # EM7411
						M2='0101101000011100000000001100000000000000111000010000000000000000010000100'
						CA="em7411-2xbands"
						CA3="em7411-3xbands"
					fi
				fi
			;;
		esac
	;;
	"8087" )
		M2='111110110011100011111000010111000000011110000000000000000000000001'
		CA="l850-2xbands"
		CA3="l850-3xbands"
		
# fake FM150 - L850 5G	
		M2='01011000000100001000000010001100000000000000000000000000000000000100001'
		M5='00001000000100000000000000000000000000001000000000000000000000000100001'
		CA=""
		CA3=""

	;;
	"2cb7" )
		FM150=$(echo "$model" | grep "FM150")
		if [ -z $FM150 ]; then
			M2='111110110011100011111000010111000000011110000000000000000000000001'
			CA="l850-2xbands"
			CA3="l850-3xbands"
		else
			M2='01011000000100000000000010001100000000000000000000000000000000000100001'
			M5='00001000000100000000000000000000000000001000000000000000000000000100001'
			CA=""
			CA3=""
		fi
	;;
	* )
		exit 0
	;;
esac

reverse $L1
echo $revstr > /tmp/bmask
if [ ! -z $L5 ]; then
	reverse $L5
else
	revstr="x"
fi
echo $revstr >> /tmp/bmask
echo $M2 >> /tmp/bmask
echo $M5 >> /tmp/bmask
if [ $CA ]; then
	echo $CA >> /tmp/bmask
	if [ $CA3 ]; then
		echo $CA3 >> /tmp/bmask
		if [ $CA4 ]; then
			echo $CA4 >> /tmp/bmask
		fi
	fi
fi

