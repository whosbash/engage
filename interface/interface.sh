#!/bin/bash

###################################################################################################
###################################################################################################
#                                                    	                                            #
# Interface functions                                                                             #
#                                                    	                                            #
###################################################################################################
###################################################################################################

# Update, upgrade and fix packages
waitUser () {
   local init_timestamp=$(date)
   local timeout="${1:-5}"
   
   tput sc
   echo -e "Press ${URed}any key${Clear} to continue..."
	
	while [ true ]
	do
		# 3 [s] timeout
		read -t "$timeout" -n 1

		if [ $? = 0 ] ; then
			return;
		else
			tput rc
			echo -e "Waiting ${URed}some key-press${Clear} since $init_timestamp... it is $(date)"
		fi

	done
}

getInfo () {
	while [ true ];
	do
		read -p "Type your ${BBlue}$1${Clear}: " info
		read -p "Is your ${IBlue}$1${Clear} ${BBlue}$info${Clear} ? [y/n/q]: " response

		if [ $response == "y" ]; then
			echo -e $info
			return

		elif [ $response == "q" ]; then
			exit 1

		fi
	done
}

printHeader () {
	declare -i line_length=$1
	
	local upper_marker="$2" 
	local right_marker="$3"
	local lower_marker="$4"
	local left_marker="$5"

	local ul_corner="$6" 
	local ur_corner="$7"
	local bl_corner="$8"
	local br_corner="$9"
	
	local box_title=${10}

	# Lengths
	local len_upper_marker=${#upper_marker}
	local len_right_marker=${#right_marker}
	local len_lower_marker=${#lower_marker}
	local len_left_marker=${#left_marker}

	upper_marker="$(embraceColor "$upper_marker" "$HEADER_COLOR")" 
	right_marker="$(embraceColor "$right_marker" "$HEADER_COLOR")"
	lower_marker="$(embraceColor "$lower_marker" "$HEADER_COLOR")"
	left_marker="$(embraceColor "$left_marker" "$HEADER_COLOR")"
	
	ul_corner="$(embraceColor "$ul_corner" "$HEADER_COLOR")" 
	ur_corner="$(embraceColor "$ur_corner" "$HEADER_COLOR")"
	bl_corner="$(embraceColor "$bl_corner" "$HEADER_COLOR")"
	br_corner="$(embraceColor "$br_corner" "$HEADER_COLOR")"
	
	# Print menu with number of characters equal to terminal charsize 
	local n_cols="$(tput cols)" 
	if [[ $n_cols -lt $(($line_length+2+$len_left_marker+ $len_right_marker)) ]]; then
		line_length=$(($(tput cols)- 2 -$len_left_marker-$len_right_marker))
	fi

	# Upper fence
	local upper_fence="$ul_corner$(repeat $line_length $upper_marker)$ur_corner"
	
	# Upper indentation
	local repeat_space=$(($line_length-1-$len_left_marker))
	local upper_space="$left_marker $(repeat $repeat_space " ") $right_marker"
	
	# Lower fence
	local lower_fence="$bl_corner$(repeat $line_length $lower_marker)$br_corner"

	# Upper indentation
	local lower_space="$upper_space"

	# Slice words by some character counter
	local regex_counter="s/(.{$line_length})/\1\n/g"
	local regex_trimmer='s/(^ | $)//g'

	# Complete line with dots and a pipe
	local res="$line_length-length-1-$len_left_marker"
	local filler="$(repeat $line_length "$SPACE_FILLER"; echo)"
	
	local arg_0='$0'
	local arg_1="substr(\"$filler\", 1, rest)"
	local fill_command="{rest=($res); printf \"$right_marker %s%s $left_marker\n\", $arg_0, $arg_1}"

	local uncolored_title="$(echo $(removeColors "$box_title"))"
	
	local uncolored_row="$(echo -e "$uncolored_title" | \
					   	     sed -r "$regex_counter" | \
					   	     sed -r "$regex_trimmer" | \
					   	     awk "$fill_command")"
	
	local colored_title="$(printf %b\\n "$(sed "s/$uncolored_title/$box_title/g" <<< "$uncolored_row")")"

	echo -e "$upper_fence"
	echo -e "$upper_space" 
	echo -e "$colored_title"
	echo -e "$lower_space"
	echo -e "$lower_fence"
}

printFooter () {
	local line_length="$1"
	local l_corner="$3"
	local r_corner="$4"
	local m_marker=$2

	local len_l_marker=${#l_corner}
	local len_r_marker=${#r_corner}

	declare colored_l_corner="$(embraceColor "$l_corner" "$FOOTER_COLOR")"
	declare colored_r_corner="$(embraceColor "$r_corner" "$FOOTER_COLOR")"

	local n_cols="$(tput cols)"
	# Print menu with number of characters equal to terminal char-size  
	if [[ $n_cols -lt $(($line_length+2+$len_l_marker+$len_r_marker)) ]]; then
		line_length=$(($n_cols-2-$len_l_marker-$len_r_marker))
	fi

	declare m_line="$(repeat $line_length $m_marker)"
	colored_m_line="$(embraceColor "$m_line" "$FOOTER_COLOR")"

	echo -e "$colored_l_corner$colored_m_line$colored_r_corner"
}

wrapHeaderFooter () {
	printHeader $MENU_WIDTH \
			 		$UPPER_HEADER_MARKER $RIGHT_HEADER_MARKER \
				 	$LOWER_HEADER_MARKER $LEFT_HEADER_MARKER \
				 	$UL_CORNER_MARKER $UR_CORNER_MARKER \
				 	$BL_CORNER_MARKER $BR_CORNER_MARKER \
				 	"$1"
	echo 
	eval "$2"
	echo 

	printFooter $MENU_WIDTH $LOWER_FOOTER_MARKER $LEFT_FOOTER_CORNER $RIGHT_FOOTER_CORNER	
}

requestApproval () {
	local final_response="n"

	local yes="y"
	local no="n"
	local quit="q"

	while [ true ];
	do
		local available_responses="[${BGreen}y${Clear}/${BRed}n${Clear}/q]"
		read -p "$(echo -e "Do you wish to $TASK_COLOR$1${Clear}? $available_responses:")" response 

		final_response="$response"

		local confirmation_tokens="[${BGreen}y${Clear}/${BRed}n${Clear}]: "
		if [ $response = "$no" ]; then
			local compose_phrase="do not want to"

		elif [ "$response" = "$yes" ]; then
			local compose_phrase="do want to"

		elif [ "$response" = "$quit" ]; then
			local compose_phrase="want to quit"
		
		else
			echo -e "The response ${BYellow}\"$response\"${Clear} is not valid! The valid responses are:" 
			echo -e " 1) ${BGreen}\"y\"${Clear}: yes;"
			echo -e " 2) ${BRed}\"n\"${Clear}: no;"
			echo -e " 3) \"q\"": quit
			echo 

			continue;			

		fi

		compose_phrase="$compose_phrase $TASK_COLOR$1${Clear}? $confirmation_tokens: "

		local confirmation="Are you sure you $compose_phrase"
		read -p "$(echo -e "$confirmation")" confirmation_response

		if [ "$confirmation_response" = "$yes" ]; then
			break

		elif [ "$confirmation_response" = "$no" ]; then
			continue;

		else
			echo -e "The response ${BYellow}\"$confirmation_response\"${Clear} is not valid!" 
			echo -e "The valid responses are ${BGreen}\"y\"${Clear} or ${BRed}\"n\"${Clear}"
		
		fi
	done

	echo $final_response
}

requestApprovalAndEvaluate () {
	local task=$1
	local yes="y"

	local answer="$(echo "$(requestApproval "$task")")"

	if [ "$answer" = "$yes" ]; then
		echo 
		eval $2
		echo 
	fi
}

decorateAskAndEval () {
	requestApprovalAndEvaluate "$2" "wrapHeaderFooter \"$1\" \"$3\""	
}