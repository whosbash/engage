#!/bin/bash

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "This command helps to install packages and setup SSH on SVC at certain moment."
   echo
   echo "Syntax: scriptTemplate [h|v|V]"
	   echo "options:"
   echo "s     Helps to config SSH key."
   echo "h     Print this Help."
   echo
}

MENU_WIDTH=100
UPPER_FENCE_MARKER='-'
LOWER_FENCE_MARKER='-'
LEFT_FENCE_MARKER='|'
RIGHT_FENCE_MARKER='|'
CORNER_MARKER='#'

installPackage(){
	#  Check to see if Xclip is installed if not install it
	if [ $2 -eq 1 ];
	then
	  echo "$4 package \"$1\" is already installed!"
	else
	  eval $3
	  echo "$4 \"$1\" was not installed. It is installed now!"
	fi
}

# Install useful utils from different package repositories
installPackages() {	
	local is_installed=0
	local install_command=''

	# apt-get
	for package in git python3-dev python3-pip python3-venv python3-apt virtualenv ipe xclip google-chrome-stable
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

wrapHeaderFooter () {
	printHeader $MENU_WIDTH $UPPER_FENCE_MARKER $RIGHT_FENCE_MARKER $LOWER_FENCE_MARKER $LEFT_FENCE_MARKER $CORNER_MARKER "$1"
	eval "$2"
	printFooter $MENU_WIDTH $LOWER_FENCE_MARKER $CORNER_MARKER	
}

# Update, upgrade and fix packages
updateAvailableRepositoryPackages() {
	wrapHeaderFooter 'Update and upgrade current packages.' "$1"
	wrapHeaderFooter 'Fix current packages.' "$2"
	wrapHeaderFooter 'Remove unnecessary packages.' "$3"
}

# Update, upgrade and fix packages
resolveAPTPackages() {
	updateAvailableRepositoryPackages 'apt -qq update && apt -qq upgrade -y && apt full-upgrade' \
									  'apt --fix-broken install' \
									  'apt autoremove -y'
}

resolveSnapPackages() {
	updateAvailableRepositoryPackages 'snap refresh' \
									  'echo Snap may require manual repare...' \
									  'snap list --all | \
									   while read snapname ver rev trk pub notes; \
									   do if [[ $notes = *disabled* ]]; then sudo snap remove "$snapname" --revision="$rev"; fi; \
									   done'
}

resolvePipPackages() {
	updateAvailableRepositoryPackages 'pip-review --raw | xargs -n1 pip install -U' \
   									  'echo pip may require manual maintainance...' \
									  'echo pip has no autoremove unused packages...' \
									  
}



resolvePackages () {
	resolveAPTPackages
	resolveSnapPackages
	resolvePipPackages
}

clearWarnings () {
	printHeader $MENU_WIDTH $UPPER_FENCE_MARKER $RIGHT_FENCE_MARKER $LOWER_FENCE_MARKER $LEFT_FENCE_MARKER $CORNER_MARKER "Clear warnings."

	chmod a+x aptsources-cleanup.pyz
	./aptsources-cleanup.pyz

	printFooter $MENU_WIDTH $LOWER_FENCE_MARKER $CORNER_MARKER
}

preparePackages() {
	printHeader $MENU_WIDTH $UPPER_FENCE_MARKER $RIGHT_FENCE_MARKER $LOWER_FENCE_MARKER $LEFT_FENCE_MARKER $CORNER_MARKER "Prepare packages"

	# Save tilde as home alias
	if grep -q "alias ~=/home/$1" /home/$1/.bashrc; 
	then
		echo "Home alias is already tilde ~."
	else
		echo "alias ~=/home/$1" >> /home/$1/.bashrc
	fi

	installPackages
	clearWarnings
	resolvePackages 
}

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

chooseSCM () {

	PS3="Enter the number of Source Code Management (SCM) toolkit: "
	select SCM in github bitbucket gitlab
	do
	    echo "Selected SCM: $SCM, number $REPLY"
	done

}

getInfo () {
	while [ true ];
	do
		read -p "Type your $1: " email
		read -p "Is your $1 $email ? [y/n/q]: " response

		if [ $response == "y" ]; then
			echo $email
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

generateSSHKey () {
	declare file_path="/$(whoami)/.ssh/$1_$2"
	declare full_file_path="$file_path.pub"
	
	declare file_folder=$(whoami)
	declare file_name=$1
	declare file_extension=$2 

	# Generate ssh key
	ssh-keygen -t $2 -C "$(getInfo 'e-mail')"
	
	# Agent
	eval "$(ssh-agent -s)"

	# Agent
	ssh-add $file_path

	xclip -sel clip < $full_file_path
	
	echo "The ssh key content is on clipboard!"
	echo "Go to your SCM tool (github, bitbucket, gitlab, ...) and setup it in proper place."	

}

testSSHConnection () {
	declare file_path="/$(whoami)/.ssh/$1_$2"
	declare full_file_path="$file_path.pub"

	if [ $(ssh -T git@github.com | grep -c "You've successfully authenticated") -eq 1 ];
	then
	  echo "$(ssh -T git@github.com)"
	else
	  echo "Your SSH key is not configured properly."
	  echo "Either setup your SCM tool with the content of file $full_file_path or ask your supervisor to do it."
	fi
}

resolveSSH () {
	task='configure ssh'
	requestApproval $task | read answer

	if [ "$answer" == "y" ]; then		
		generateSSHKey "id" "rsa"
		waitUser

		# Test connection
		testSSHConnection "id" "rsa"

		# Get git e-mail
		task='git e-mail'
		requestApproval $task | read answer

		if [ "$answer" == "y" ]; then 
			getInfo $task
		fi
		
		# Get git name
		task='git name'
		requestApproval $task | read answer

		if [ "$answer" == "y" ]; then 
			getInfo $task
			configGitMail $?
		fi
	fi
}

configSSH () {
	local command_='resolveSSH'
	wrapHeaderFooter "SSH key configuration" $command_
}

cloneRepository () {
	local repo_host=''
	
	if [[ $1='bitbucket' ]]; then
		repo_host='bitbucket.org'
	elif [[ $1='github' ]]; then
		repo_host='github.com'
	fi

	if [[ $repo_host='' ]]; then
		echo 'SVC $1 not currently supported!'
		exit 0;
	fi

	git clone "git@$repo_host:$2/$3.git"
	exit 1;
}

configGitUser () {
	git config --global user.email "$1"
}

configGitMail () {
	git config --global user.name "$1"
}

requestApproval () {
	local response='n'

	while [ true ];
	do
		read -p "Do you wish to $1? [y/n/q]: " response
		
		if [ $response == "y" ]; then
			local compose_particle='do'

		elif [ $response == "n" ]; then
			local compose_particle='do not'

		elif [ $response == "q" ]; then
			exit 1
		fi

		read -p "Are you sure you $compose_particle $1? [y/n/q]: " response
	
		if [ $response == "y" ]; then
			break
		fi
	done

	echo $response
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################
preparePackages $1
# resolveSSH

