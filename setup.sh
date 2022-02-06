#!/bin/bash

###################################################################################################
###################################################################################################
#                                                                                             	  #
# Global variables                                                                                #
#                                                    	                                            #
###################################################################################################
###################################################################################################

# Menu max width
MENU_WIDTH=100

# Fence markers
# Take a look at: https://waylonwalker.com/drawing-ascii-boxes/
UPPER_HEADER_MARKER='━'
LOWER_HEADER_MARKER='━'

LEFT_HEADER_MARKER='┃'
RIGHT_HEADER_MARKER='┃'

UL_CORNER_MARKER='┏'
UR_CORNER_MARKER='┓'

BL_CORNER_MARKER='┗'
BR_CORNER_MARKER='┛'

LOWER_FOOTER_MARKER='━'
LEFT_FOOTER_CORNER='┗'
RIGHT_FOOTER_CORNER='┛'
SPACE_FILLER=' '

# SCM available
# Take note: lower case names separated by ", "
AVAILABLE_SCM='github, bucket, gitlab'

# Reset
Clear='\033[0m'       	  # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White


# Clear the color after that
clear='\033[0m'

###################################################################################################
###################################################################################################
#                                                    	                                            #
# Miscelaneous                                        	                                         #
#                                                    	                    	                    	  #
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
	for i in $range ; do echo -e -n "${str}"; done
}

removeSpaces (){
	echo "$(echo $1 | sed 's/ //g')"
}

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
		read -p "Type your $1: " info
		read -p "Is your $1 $info ? [y/n/q]: " response

		if [ $response == "y" ]; then
			echo -e $info
			return

		elif [ $response == "q" ]; then
			exit 1

		fi
	done
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

	local len_upper_marker=${#upper_marker}
	local len_right_marker=${#right_marker}
	local len_lower_marker=${#lower_marker}
	local len_left_marker=${#left_marker}

	# Print menu with number of characters equal to terminal charsize  
	if [[ $(tput cols) -lt $(($line_length+2+$len_left_marker+ $len_right_marker)) ]]; then
		line_length=$(($(tput cols)- 2 -$len_left_marker-$len_right_marker))
	fi

	# Upper fence
	local upper_fence="$ul_corner$(repeat $line_length $upper_marker)$ur_corner"
	
	# Upper indentation
	local upper_space="$left_marker $(repeat $(($line_length-1-$len_left_marker)) " ") $right_marker"
	
	# Lower fence
	local lower_fence="$bl_corner$(repeat $line_length $lower_marker)$br_corner"

	# Upper indentation
	local lower_space="$upper_space"

	# Slice words by some character counter
	local regex_counter="s/(.{$line_length})/\1\n/g"
	local regex_trimmer='s/(^ | $)//g'

	# Complete line with dots and a pipe
	local res="$line_length-length-1-$len_left_marker"
	local filler="$(repeat $line_length "$SPACE_FILLER"; echo -e)"
	
	local arg_0='$0'
	local arg_1="substr(\"$filler\", 1, rest)"
	
	local fill_command="{rest=($res); printf \"$right_marker %s%s $left_marker\n\", $arg_0, $arg_1}"

	echo -e "$upper_fence"
	echo -e "$upper_space" 
	sed -r -e "$regex_counter" <<< ${10} | sed -r "$regex_trimmer" | awk "$fill_command"
	echo -e "$lower_space"
	echo -e "$lower_fence"
}

printFooter () {
	echo -e "$LEFT_FOOTER_CORNER$(repeat $1 $2)$RIGHT_FOOTER_CORNER"
}

requestApproval () {
	local final_response='n'

	while [ true ];
	do
		local available_responses="[${BGreen}y${Clear}/${BRed}n${Clear}/q]"
		read -p "$(echo -e "Do you wish to ${BBlue}$1${Clear}? $available_responses:")" response
		
		final_response="$response"
		echo "$final_response"

		local confirmation_tokens="[${BGreen}y${Clear}/${BRed}n${Clear}]: "
		if [ $response == "y" ]; then
			local compose_phrase="do want to ${BBlue}$1${Clear}? $confirmation_tokens"

		elif [ $response == "n" ]; then
			local compose_phrase="do not want to ${BBlue}$1${Clear}? $confirmation_tokens: "

		elif [ $response == "q" ]; then
			local compose_phrase="want to quit ${BBlue}$1${Clear}? $confirmation_tokens: "
		fi

		local confirmation="Are you sure you $compose_phrase"
		read -p "$(echo -e "$confirmation")" confirmation_response

		if [ $confirmation_response == "y" ]; then
			break
		elif [ $confirmation_response == "n" ]; then
			continue
		else
			echo -e "The response ${BYellow}\"$confirmation_response\"${Clear} is not valid!" 
			echo -e "The valid responses are ${BGreen}\"y\"${Clear} or ${BRed}\"n\"${Clear}"
		fi
	done

	echo -e $final_response
}

requestApprovalAndEvaluate () {
	local task=$1

	echo
	local answer="$(echo -e "$(requestApproval "$task")")"
	echo -e 

	if [ "$answer" == "y" ]; then
		echo 
		eval $2
		echo 
	fi
}

decorateAskAndEval () {
	requestApprovalAndEvaluate "$2" "wrapHeaderFooter \"$1\" \"$3\""	
}

installPackage(){
	if [ $2 -eq 1 ];
	then
	  echo -e "${BGreen}$4 package \"$1\" is already installed!${Clear}"
	else
	  eval $3
	  echo -e "${BRed}$4 \"$1\" was not installed.${Clear} ${BGreen}It is installed now!${Clear}"
	fi
}

###################################################################################################
###################################################################################################
#                                                    	                                     	     #
# Necessary functions                                                                             #
#                                                    	                                     	     #
###################################################################################################
###################################################################################################

# Install useful utils from different package repositories
installPackages() {	
	local is_installed=0
	local install_command=''

	# apt-get
	for package in git python3-dev python3-pip python3-venv python3-apt \
				   	virtualenv ipe xclip google-chrome-stable texlive-xetex \
				   	texlive-fonts-recommended texlive-plain-generic
	do
		is_installed=$(dpkg-query -W -f='${Status}' $package | grep -c "ok installed")
		install_command="apt install --upgrade $package -y;"
		
		installPackage $package $is_installed "$install_command" 'apt'
	done
	
	# snap
	for package in slack sublime-text gimp
	do
		is_installed=$(("$(snap list | grep -c $package)" > "0"))
		install_command="snap install $package --classic"

		installPackage $package $is_installed "$install_command" 'snap'
	done

	# pip
	for package in numpy pandas matplotlib scipy scikit-learn notebook pip-review
	do
		is_installed=$(("$(pip freeze | grep -c $package)" > "0"))
		install_command="pip install $package"

		installPackage $package $is_installed "$install_command" 'pip'
	done
}

# Update, upgrade and fix packages
ManageRepositoryPackages () {
	local head="Repository ${BBlack}$1${Clear}:" 

	wrapHeaderFooter "$head Update and upgrade current packages." "$2"
	wrapHeaderFooter "$head Fix current packages." "$3"
	wrapHeaderFooter "$head Remove unnecessary packages." "$4"
}

clearWarnings () {
	chmod a+x aptsources-cleanup.pyz
	./aptsources-cleanup.pyz
}

generateSSHKey () {
	declare file_path="/$(whoami)/.ssh/$1_$2"
	declare full_file_path="$file_path.pub"
	
	declare file_folder=$(whoami)
	declare file_name=$1
	
	# Generate ssh key
	ssh-keygen -t $2 -C "$(getInfo 'e-mail')"
	
	# Agent
	eval "$(ssh-agent -s)"

	# Agent
	ssh-add $file_path

	xclip -sel clip < $full_file_path
}

testSSHConnection () {
	declare SCM_name="$1"
	declare SCM_host=''
	declare SSHConnection_approval_phrase=''

	if [[ $SCM_name == "github" ]]; then
	  SCM_host='github.com'
	  SSHConnection_approval_phrase='You''ve successfully authenticated'	  

	elif [[ $SCM_name=="bitbucket" ]]; then
	  SCM_host='bitbucket.org'
	  SSHConnection_approval_phrase='You can use git to connect to Bitbucket.'

	else
	  echo -e "SCM $1 not supported"
	  exit
	fi

	local ssh_msg="${BGreen}$(echo -e "$(ssh -q "git@$SCM_host")")${Clear}"
	if [ $(echo -e $ssh_msg | grep -c "$SSHConnection_approval_phrase" | wc -l) -eq 1 ]; then
	  echo -e $ssh_msg

	else
	  declare file_path="/$(whoami)/.ssh/$2_$3"
	  declare full_file_path="$file_path.pub"

	  echo -e "${BRed}Your SSH key is not configured properly.${Clear}"
	  echo -e "${BRed}Either setup your SCM tool with the content of file $full_file_path${Clear}" 
	  echo -e "${BRed}or ask your supervisor to do it.${Clear}"
	fi
}

requestGitSCM () {
	PS3="Enter the number of Source Code Management (SCM) toolkit: "
	select SCM in github bitbucket gitlab quit; do
		case $SCM in
		    github)
		      echo -e $SCM
		      break
		      ;;
		    bitbucket)
		      echo -e $SCM
		      break
		      ;;
		    gitlab)
		      echo -e $SCM
		      break
		      ;;
		    quit)
			  echo -e 'quit'
		      break
		      ;;
		    *)
		      echo -e "${BRed}Invalid option $REPLY.$Clear" 
		      echo -e "${BRed}Available options are [$AVAILABLE_SCM, quit]${Clear}"
		      ;;
		  esac
	done
}

cloneGitRepository () {
	local repo_host=''
	
	if [[ "$1"="bitbucket" ]]; then
		repo_host='bitbucket.org'
	elif [[ "$1"="github" ]]; then
		repo_host='github.com'
	elif [[ "$1"="gitlab" ]]; then
		repo_host='gitlab.com'
	fi

	if [[ "$repo_host"='' ]]; then
		echo -e "${BRed}SCM $1 not currently supported!${Clear}"
		exit 0;
	fi

	git clone "git@$repo_host:$2/$3.git"
	exit 1;
}

requestGitInfoAndCloneGitRepository () {
	declare SCM_name=""
	declare organization_name=""
	declare repository_name=""

	SCM_name="$(getInfo 'SCM [github/bitbucket]')"
	organization_name="$(getInfo 'organization name ($organizationname/$repositoryname)')"
	repository_name="$(getInfo 'repository name ($organizationname/$repositoryname)')"
	
	cloneGitRepository $SCM_name $organization_name $repository_name
}

cloneGitRepositories () {
	local task='clone one more repository'

	while [ true ];
	do
		requestGitInfoAndCloneGitRepository
		
		local answer="$(echo -e "$(requestApproval "$task")")"

		if [ "$answer" == "y" ]; then 
			continue;
		elif [ "$answer" == "n" ] || [ "$answer" == "q" ] ; then 
			break;
		fi
	done
}

configGlobalGitUsername () {
	git config --global user.name "$1"
}

configGlobalGitEMail () {
	git config --global user.email "$1"
}

###################################################################################################
###################################################################################################
#                                                    	                                            #
# Resolve tasks                                        	                                         #
#                                                      	                                         #
###################################################################################################
###################################################################################################

# Update, upgrade and fix packages
resolveAPTPackages() {
	ManageRepositoryPackages 'apt' \
							 'apt -qq update && apt -qq upgrade -y && apt full-upgrade' \
							 'apt --fix-broken install' \
							 'apt autoremove -y'
}

resolveSnapPackages() {
	ManageRepositoryPackages 'snap' \
							 'snap refresh' \
							 'echo -e Package manager snap may require manual repare...' \
							 'snap list --all | \
							  while read snapname ver rev trk pub notes; \
							  do if [[ $notes = *disabled* ]]; \
							  then sudo snap remove "$snapname" --revision="$rev"; \
							  echo -e "Package $snapname is removed!"; fi; done; \
							  echo -e "All unnecesssary packages were removed."'
}

resolvePipPackages() {
	ManageRepositoryPackages 'pip' \
							 'pip-review --raw | xargs -n1 pip install -U' \
							 'echo -e Package manager pip may require manual maintainance...' \
							 'echo -e Package manager pip has no autoremove unused packages...'
}

resolveRepositories () {
	resolveAPTPackages
	resolveSnapPackages
	resolvePipPackages
}

resolvePackages () {
	installPackages
	clearWarnings
	resolveRepositories
}

resolveSystemConfig () {
	# Save tilde as home alias
	if grep -q "alias ~=/home/$1" /home/$1/.bashrc; 
	then
		echo -e "Home alias is already tilde ~."
	else
		echo -e "alias ~=/home/$1" >> /home/$1/.bashrc
	fi
}

resolveGitSSH () {
	local filename="id" 
	local file_suffix="rsa"

	local SCM_name="$1"

	echo -e "The git SSH configuration allows you to"
	echo -e "  : generate an SSH key;"
	echo -e "  : test SSH connection;"
	echo -e "  : set git global e-mail and name properties."

	# Generate SSH key
	requestApprovalAndEvaluate 'generate SSH key' "generateSSHKey $filename $suffix"
	
	# Wait user configure the SSH on its SCM platform
	echo
	echo -e "In case you generated the SSH, it is available on /$(whoami)/$filename _$file_suffix.pub"
	echo -e "Its content is on your clipboard (Ctrl+V on some text field to see it)!"
	echo
	echo -e "Then, go to your SCM platform (github, bitbucket, gitlab, ...) \
				and setup it in proper place."
	echo -e "Otherwise, in case you do not have an available Git SSH key "
	echo -e "or it is not set on your user SCM $SCM_name account,"
	echo -e "the next step will fail."
	echo 

	waitUser

	# Test connection
	requestApprovalAndEvaluate 'test SSH connection' \
										"testSSHConnection $SCM_name $filename $file_suffix"

	# Get git e-mail
	requestApprovalAndEvaluate 'set global git e-mail' \
										'configGlobalGitEMail `echo -e $(getInfo "git email")`'
	
	# Get git name
	requestApprovalAndEvaluate 'set global git name' \
										'configGlobalGitUsername `echo -e $(getInfo "git name")`'
}

resolveGit () {
	local SCM=$(echo -e $(requestGitSCM))
	requestApprovalAndEvaluate 'resolve Git SSH connection' "resolveGitSSH $SCM"
}

###################################################################################################
###################################################################################################
#                                                    	                                            #
# Prepare tasks                                        	                                         #
#                                                      	                                         #
###################################################################################################
###################################################################################################

prepareSystemConfig () {
	local command_="resolveSystemConfig $1"
	local task='configure system minors (currently: change home to alias ~)'
	local title="Minor system configurations"
	
	decorateAskAndEval "$title" "$task"  "$command_" 
}

preparePackages() {
	local command_="resolvePackages"
	local task='install packages and manage repositories'
	local title="Repositories"
	
	decorateAskAndEval "$title" "$task"  "$command_" 
}

prepareGit () {
	local command_='resolveGit'
	local task='setup some global git configuration'
	local title="Git setup"

	decorateAskAndEval "$title" "$task" "$command_"
}

###################################################################################################
###################################################################################################
#                                                                                                 #
# Main program                                                                                    #
#                                                                                                 #
###################################################################################################
###################################################################################################

# prepareSystemConfig $1
# preparePackages
# prepareGit 

wrapHeaderFooter 'Test title' 'echo Hello World'

exit 1;
