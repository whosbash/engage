#!/bin/bash

###################################################################################################
###################################################################################################
#                                                    	                                          #
# Utilitaries                                         	                                          #
#                                                    	                    	                  #
###################################################################################################
###################################################################################################

mod() {
	return $(($1%$2));
}

divide() {
	return $(($1/$2))
}

floor() {
	return $(($1/$2))
}

# Repeat given char N times using shell function
repeat(){
	local start=1
	local end=${1:-$1}
	local str="${2:-$2}"
	local range=$(seq $start $end)
	
	for i in $range ; do 
		echo -e -n "${str}"; 
	done
}

embrace () {
	echo "$2$1$3"
}

embraceColor () {
	embrace "$1" "$2" ${Clear}
}


nLetters () {
	echo "${1::$2}"
}

firstUpperCase () {
	echo ${1^}
}

slice () {
	echo "${1:$2:$3}"	
}

lowerSlice () {
	lowerCase "$(slice "$1" "$2" "$3")"
}

firstLetters () {
	slice "$1" 0 "$2"
}

lowerCase () {
	echo "$1" | awk '{print tolower($0)}'
}

upperCase () {
	echo ${1^^}
}

toNum () {
	echo "$1+0" | bc
}

removeSpaces (){
	echo "$(echo $1 | sed 's/ //g')"
}

removeColors (){
	echo "$(printf "$1" | ansi2txt | col -b)"
}