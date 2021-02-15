#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset


inRBL=""
inIP=""
hook=""
addhook=""
delhook=""
storageDir=""

domainMode=""

function help() 
{
	echo -e "\t$0 -i ip-file -r rbl-file [-s storageDIR] [-h hookFile] [-a add-hookFile] [-d del-hookfile]]" 
	echo -e "\t$0 -x ip-addr -c RBL" 
	echo -e "\t$0 -f -i fqdn-file -r rbl-file [-s storageDIR] [-h hookFile] [-a add-hookFile] [-d del-hookfile]]" 
	echo -e "\t$0 -f -x fqdn -c RBL" 
	exit 1
}

IP=""
RBL=""

for i in "$@"
do
	if [[ "$i" == "--help" || "$i" == "help" ]]; then
		help 
		exit 1
	fi
done

while getopts i:r:h:a:d::x:c:s:f flag
do
case "${flag}" in
	i) inIP="${OPTARG}";;
	r) inRBL="${OPTARG}";;
	h) hook="${OPTARG}";;
	a) addhook="${OPTARG}";;
	d) delhook="${OPTARG}";;
	x) IP="${OPTARG}";;
	c) RBL="${OPTARG}";;
	s) storageDir="${OPTARG}";;
	f) domainMode=1;;
	?) help >> /dev/stderr;;
esac
done


#check if storage dir does not exist (if it is not empty) and return error
( [ ! -z "$storageDir" ] && [ ! -d "$storageDir" ] )  && ( echo "Direcory: $storageDir does not exist or it is not a directory" >> /dev/stderr; exit 1 )

#check if hook is executable (if it is not empty) otheriwse return error
( [ ! -z "$hook" ] && [ ! -x "$hook" ] ) && ( echo "File: $hook is not a executable or does not exist, check permissions" >> /dev/stderr; exit 1 )
( [ ! -z "$addhook" ] && [ ! -x "$addhook" ] ) && ( echo "File: $addhook is not a executable or does not exist, check permissions" >> /dev/stderr; exit 1 )
( [ ! -z "$delhook" ] && [ ! -x "$delhook" ] ) && ( echo "File: $delhook is not a executable or does not exist, check permissions" >> /dev/stderr; exit 1 )

uIPs=()
uRBLs=()

if [[ ! -z "$IP" || ! -z "$RBL" ]]; then
	#$IP not empty or $RBL not empty

	#check if $IP or $RBL is empty 
	[ -z "$RBL" ] && ( echo "when -x is set, -c must be set too" >> /dev/stderr; exit 1 )
	[ -z "$IP" ] && ( echo "when -c is set, -x must be set too" >> /dev/stderr; exit 1 )
	
	[ ! -z "$storageDir" ] && ( echo "when -x and -c is set, you cannot use -s" >> /dev/stderr; exit 1 )
	[ ! -z "$hook" ] && ( echo "when -x and -c is set, you cannot use -h" >> /dev/stderr; exit 1 )
	[ ! -z "$addhook" ] && ( echo "when -x and -c is set, you cannot use -a" >> /dev/stderr; exit 1 )
	[ ! -z "$delhook" ] && ( echo "when -x and -c is set, you cannot use -d" >> /dev/stderr; exit 1 )
	[ ! -z "$inIP" ] && ( echo "when -x and -c is set, you cannot use -i" >> /dev/stderr; exit 1 )
	[ ! -z "$inRBL" ] && ( echo "when -x and -c is set, you cannot use -r" >> /dev/stderr; exit 1 )

	uIPs[0]="$IP"
	uRBLs[0]="$RBL"

	hook=""
	storageDir=""
else
	( [ -z "$inRBL" ] || [ -z "$inIP" ] ) && ( help >>  /dev/stderr; exit 1)

	i=0
	while read ip; do
		uIPs[i]="$ip"
		i=$(($i+1))
	done <$inIP

	i=0
	while read rbl; do
		uRBLs[i]="$rbl"
		i=$(($i+1))
	done <$inRBL
fi



modifiedIPs=()
IPs=()
i=0
for ip in ${uIPs[*]}; do
	#if empty line continue
	[ -z "$ip" ] && continue
	
	
	#if not domain mode
	if [ -z "$domainMode" ]; then 
		#check if ip address is in vaild format
		(sipcalc "$ip" | grep -i ERR > /dev/null 2>&1 ) &&  (echo "$ip is not vaild ip address" >> /dev/stderr; exit 1)
		if [[ $ip =~ .*:.* ]]; then
			#ipv6
			modifiedIPs[i]="$(sipcalc "$ip" | grep -ih "Expanded Address" | cut -d' ' -f3 | tr -d ':'  | rev | sed -e 's/\(.\)/\1./g')"
 		else
			#ipv4
			modifiedIPs[i]="$(echo "$ip" | awk -F. '{print $4"."$3"." $2"."$1}')."
		fi  
	else
		modifiedIPs[i]="$ip."

	fi

	IPs[i]="$ip"
	i=$((i+1))
done 

if [ ${#modifiedIPs[@]} -eq 0 ]; then
	echo "no ip addresses inside $inIP file" >> /dev/stderr
	exit 1
fi

RBLs=()
i=0
for rbl in ${uRBLs[*]}; do
	#empty line continue	
	[ -z "$rbl" ] && continue

	RBLs[i]="$rbl"
	i=$((i+1))
done

if [ ${#RBLs[@]} -eq 0 ]; then
	echo "no RBLs inside $inRBL file" >> /dev/stderr
	exit 1
fi



listedIP=()
listedRBL=()
i=0
for rbl in ${RBLs[*]}; do
	for i in ${!modifiedIPs[*]}; do
		query="${modifiedIPs[$i]}$rbl"
		ip="${IPs[$i]}"
		echo -e "IP: $ip RBL: $rbl\n\tQUERY: $query"

		out="$(dig "$query" +noall +answer A)"
		if [[ $out ]]; then
			echo -e "\tResult: LISTED"
			echo -e  "\tOutput:"
			while IFS= read -r line; do
				    echo -e "\t\t$line"
			done <<< "$out"

			listedIP[i]="$ip"
			listedRBL[i]="$rbl"
			i=$((i+1))
		else
			echo -e "\tResult: Not Listed"
		fi
	
	done
done  


echo -e "\nSummary:"
if [[ ${!listedIP[*]} ]]; then
	for i in ${!listedIP[*]}; do
			ip="${listedIP[$i]}"
			rbl="${listedRBL[$i]}"
			echo -e "\t$ip listed on $rbl"
	done
else
	echo -e "\tNone of these addresses are listed"

fi

if [ ! -z "$storageDir" ]; then
	file="$storageDir/$(date +\%Y\%m\%d\%H\%M\%N).result"
	last="$storageDir/last"
	touch "$file"

	for i in ${!listedIP[*]}; do
			ip="${listedIP[$i]}"
			rbl="${listedRBL[$i]}"
			echo  "$ip $rbl" >> $file
	done

	if [ ! -f "$last" ]; then
		#$last  does exits
		touch "$last"
	fi

	set +o errexit
	out=$(diff <(cat "$last" | sort) <(cat "$file" | sort))
	code=$?
	set -o errexit

	echo 
	echo -e "Changes:"

	if [ $code -ne 0 ];then
		out="$(echo "$out" | grep '^[<|>]')"
	
		hookin=()
		addhookin=()
		delhookin=()

		while read line; do
			l="$(echo "$line" | tr -d '<>' | awk '{$1=$1};1')"
			if [[ ${line:0:1} == "<" ]];then
				echo -e "\t- $l"
				hookin[${#hookin[*]}]="- $l"
				delhookin[${#delhookin[*]}]="$l"
			else
				echo -e "\t+ $l"
				hookin[${#hookin[*]}]="+ $l"
				addhookin[${#addhookin[*]}]="$l"
			fi
		done <<< $(echo "$out")

		hin=""
		for i in ${!hookin[*]}; do
			hin="$hin${hookin[$i]}"
			if [ $i -ne $(( ${#hookin[*]} - 1 )) ]; then
				hin="$hin|"
			fi
    		done

		ahin=""
		for i in ${!addhookin[*]}; do
			ahin="$ahin${addhookin[$i]}"
			if [ $i -ne $(( ${#addhookin[*]} - 1 )) ]; then
				ahin="$ahin|"
			fi
    		done

		dhin=""
		for i in ${!delhookin[*]}; do
			dhin="$dhin${delhookin[$i]}"
			if [ $i -ne $(( ${#delhookin[*]} - 1 )) ]; then
				dhin="$dhin|"
			fi
    		done

		[ ! -z "$hook" ] && in="$hin" bash $hook 
		[ ! -z "$addhook" ] && in="$ahin" bash $addhook 
		[ ! -z "$delhook" ] && in="$dhin" bash $delhook 

	else
		echo -e  "\tNo changes"
	fi

	ln -f "$file" "$last"
	rm "$file"
fi

