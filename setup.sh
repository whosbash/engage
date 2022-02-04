#!/bin/bash

############################################################
############################################################
#                                                    	   #
# Global variables                                         #
#                                                    	   #
############################################################
############################################################

MENU_WIDTH=100
UPPER_FENCE_MARKER='-'
LOWER_FENCE_MARKER='-'
LEFT_FENCE_MARKER='|'
RIGHT_FENCE_MARKER='|'
CORNER_MARKER='#'
AVAILABLE_SCM='github, bucket'

############################################################
############################################################
#                                                    	   #
# Miscelaneous                                        	   #
#                                                    	   #
############################################################
############################################################

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
	for i in $range ; do echo -n "${str}"; done
}

############################################################
############################################################
#                                                    	   #
# Interface functions                                      #
#                                                    	   #
############################################################
############################################################

# Update, upgrade and fix packages
waitUser () {
   local init_timestamp=$(date)
   local timeout="${1:-5}"
   
   tput sc
   echo "Press any key to continue..."
	
	while [ true ]
	do
		# 3 [s] timeout
		read -t "$timeout" -n 1

		if [ $? = 0 ] ; then
			return;
		else
			tput rc
			echo "Waiting some key-press since $init_timestamp... it is $(date)"
		fi

	done
}

getInfo () {
	while [ true ];
	do
		read -p "Type your $1: " info
		read -p "Is your $1 $info ? [y/n/q]: " response

		if [ $response == "y" ]; then
			echo $info
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

	local len_upper_marker=${#upper_marker}
	local len_right_marker=${#right_marker}
	local len_lower_marker=${#lower_marker}
	local len_left_marker=${#left_marker}

	if [[ $(tput cols) -lt $(($line_length+2+$len_left_marker+ $len_right_marker)) ]]; then
		line_length=$(($(tput cols)- 2 -$len_left_marker-$len_right_marker))
	fi

	local corner_marker="$6"

	# Upper fence
	local upper_fence="$corner_marker$(repeat $line_length $upper_marker)$corner_marker"
	
	# Upper indentation
	local upper_space="$left_marker $(repeat $(($line_length-1-$len_left_marker)) " ") $right_marker"
	
	# Lower fence
	local lower_fence="$corner_marker$(repeat $line_length $lower_marker)$corner_marker"

	# Upper indentation
	local lower_space="$upper_space"

	# Slice words by some character counter
	local regex_counter="s/(.{$line_length})/\1\n/g"
	local regex_trimmer='s/(^ | $)//g'

	# Complete line with dots and a pipe
	local res="$line_length-length-1-$len_left_marker"
	local dot_line="$(repeat $line_length "."; echo)"
	
	local arg_0='$0'
	local arg_1="substr(\"$dot_line\", 1, rest)"
	
	local fill_command="{rest=($res); printf \"$right_marker %s%s $left_marker\n\", $arg_0, $arg_1}"

	echo "$upper_fence"
	echo "$upper_space" 
	sed -r -e "$regex_counter" <<< $7 | sed -r "$regex_trimmer" | awk "$fill_command"
	echo "$lower_space"
	echo "$lower_fence"
}

printFooter () {
	echo "$3$(repeat $1 $2)$3"
}

wrapHeaderFooter () {
	printHeader $MENU_WIDTH \
			 	$UPPER_FENCE_MARKER $RIGHT_FENCE_MARKER \
				 $LOWER_FENCE_MARKER $LEFT_FENCE_MARKER \
				 $CORNER_MARKER \
				 "$1"
	
	echo 
	eval "$2"
	echo

	printFooter $MENU_WIDTH $LOWER_FENCE_MARKER $CORNER_MARKER	
}

requestApproval () {
	local final_response='n'

	while [ true ];
	do
		read -p "Do you wish to $1? [y/n/q]: " response
		
		final_response="$response"
		
		if [ $response == "y" ]; then
			local compose_phrase="do want to $1? [y/n]: "

		elif [ $response == "n" ]; then
			local compose_phrase="do not want to $1? [y/n]: "

		elif [ $response == "q" ]; then
			local compose_phrase="want to quit? [y/n]: "
		fi

		local confirmation="Are you sure you $compose_phrase"
		read -p "$confirmation" confirmation_response

		if [ $confirmation_response == "y" ]; then
			break
		elif [ $confirmation_response == "n" ]; then
			continue
		else
			echo "The response \"$confirmation_response\" is not valid! THe valid responses are \"y\" or \"n\""
		fi
	done

	echo $final_response
}

requestApprovalAndEvaluate () {
	local task=$1

	echo 
	local answer="$(echo "$(requestApproval "$task")")"
	echo 

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
	  echo "$4 package \"$1\" is already installed!"
	else
	  eval $3
	  echo "$4 \"$1\" was not installed. It is installed now!"
	fi
}

############################################################
############################################################
#                                                    	   #
# Necessary functions                                      #
#                                                    	   #
############################################################
############################################################

# Install useful utils from different package repositories
installPackages() {	
	local is_installed=0
	local install_command=''

	# apt-get
	for package in git python3-dev python3-pip python3-venv python3-apt \
				   virtualenv ipe xclip google-chrome-stable
	do
		is_installed=$(dpkg-query -W -f='${Status}' $package | grep -c "ok installed")
		install_command="apt install $package -y;"
		
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
	wrapHeaderFooter "Repository $1: Update and upgrade current packages." "$2"
	wrapHeaderFooter "Repository $1: Fix current packages." "$3"
	wrapHeaderFooter "Repository $1: Remove unnecessary packages." "$4"
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
	  echo "SCM $1 not supported"
	  exit
	fi

	local ssh_msg="$(echo "$(ssh -q "git@$SCM_host")")"
	if [ $(echo $ssh_msg | grep -c "$SSHConnection_approval_phrase" | wc -l) -eq 1 ]; then
	  echo $ssh_msg

	else
	  declare file_path="/$(whoami)/.ssh/$2_$3"
	  declare full_file_path="$file_path.pub"

	  echo "Your SSH key is not configured properly."
	  echo "Either setup your SCM tool with the content of file $full_file_path or ask your supervisor to do it."
	fi
}

requestGitSCM () {
	PS3="Enter the number of Source Code Management (SCM) toolkit: "
	select SCM in github bitbucket quit; do
		case $SCM in
		    github)
		      echo $SCM
		      break
		      ;;
		    bitbucket)
		      echo $SCM
		      break
		      ;;
		    quit)
			  echo 'quit'
		      break
		      ;;
		    *) 
		      echo "Invalid option $REPLY. Available options are [$AVAILABLE_SCM, quit]"
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
	fi

	if [[ "$repo_host"='' ]]; then
		echo 'SCM $1 not currently supported!'
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
		
		local answer="$(echo "$(requestApproval "$task")")"

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

############################################################
############################################################
#                                                    	   #
# Resolve tasks                                        	   #
#                                                      	   #
############################################################
############################################################

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
							 'echo Package manager snap may require manual repare...' \
							 'snap list --all | \
							  while read snapname ver rev trk pub notes; \
							  do if [[ $notes = *disabled* ]]; \
							  then sudo snap remove "$snapname" --revision="$rev"; \
							  echo "Package $snapname is removed!"; fi; done; \
							  echo "All unnecesssary packages were removed."'
}

resolvePipPackages() {
	ManageRepositoryPackages 'pip' \
							 'pip-review --raw | xargs -n1 pip install -U' \
							 'echo Package manager pip may require manual maintainance...' \
							 'echo Package manager pip has no autoremove unused packages...'
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
		echo "Home alias is already tilde ~."
	else
		echo "alias ~=/home/$1" >> /home/$1/.bashrc
	fi
}

resolveGitSSH () {
	local filename="id" 
	local file_suffix="rsa"

	local SCM_name="$1"

	echo "The git SSH configuration allows you to"
	echo "  : generate an SSH key;"
	echo "  : test SSH connection;"
	echo "  : set git global e-mail and name properties."

	# Generate SSH key
	requestApprovalAndEvaluate 'generate SSH key' "generateSSHKey $filename $suffix"
	
	# Wait user configure the SSH on its SCM platform
	echo 
	echo "In case you generated the SSH, it is available on /$(whoami)/$filename _$file_suffix.pub"
	echo "Its content is on your clipboard (Ctrl+V on some text field to see it)!"
	echo 
	echo "Then, go to your SCM platform (github, bitbucket, gitlab, ...) and setup it in proper place."
	echo "Otherwise, in case you do not have an available Git SSH key or it is not set on your user SCM $SCM_name account,"
	echo "the next step will fail."
	echo 

	waitUser

	# Test connection
	requestApprovalAndEvaluate 'test SSH connection' "testSSHConnection $SCM_name $filename $file_suffix"

	# Get git e-mail
	requestApprovalAndEvaluate 'set global git e-mail' 'configGlobalGitEMail `echo $(getInfo "git email")`'
	
	# Get git name
	requestApprovalAndEvaluate 'set global git name' 'configGlobalGitUsername `echo $(getInfo "git name")`'
}

resolveGit () {
	local SCM=$(echo $(requestGitSCM))
	requestApprovalAndEvaluate 'resolve Git SSH connection' "resolveGitSSH $SCM"
}

############################################################
############################################################
#                                                    	   #
# Prepare tasks                                        	   #
#                                                      	   #
############################################################
############################################################

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

############################################################
############################################################
#                                                      	   #
# Main program                                             #
#                                                      	   #
############################################################
############################################################

prepareSystemConfig $1
preparePackages
prepareGit 

exit 1;
