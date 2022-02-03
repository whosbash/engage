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
	for package in git python3-dev python3-pip  python3-venv virtualenv ipe xclip google-chrome-stable python3-apt
	do
		is_installed=$(dpkg-query -W -f='${Status}' $package | grep -c "ok installed")
		install_command="apt install $package -y;"
		
		installPackage $package $is_installed "$install_command" 'apt'
	done
	
	# snap
	for package in slack sublime-text
	do
		is_installed=$(("$(snap list | grep -c $package)" > "0"))
		install_command="snap install $package --classic"

		installPackage $package $is_installed "$install_command" 'snap'
	done

	# pip
	for package in numpy pandas matplotlib scipy scikit-learn notebook
	do
		is_installed=$(("$(pip freeze | grep -c $package)" > "0"))
		install_command="pip install $package"

		installPackage $package $is_installed "$install_command" 'pip'
	done

}

# Update, upgrade and fix packages
updatePackages() {
	
	printHeader $MENU_WIDTH $UPPER_FENCE_MARKER $RIGHT_FENCE_MARKER $LOWER_FENCE_MARKER $LEFT_FENCE_MARKER $CORNER_MARKER "Updating current packages..."
	apt -qq update
	printFooter $MENU_WIDTH $LOWER_FENCE_MARKER $CORNER_MARKER
	
	printHeader $MENU_WIDTH $UPPER_FENCE_MARKER $RIGHT_FENCE_MARKER $LOWER_FENCE_MARKER $LEFT_FENCE_MARKER $CORNER_MARKER "Upgrading current packages..."
	apt-get -qq upgrade -y
	printFooter $MENU_WIDTH $LOWER_FENCE_MARKER $CORNER_MARKER

	printHeader $MENU_WIDTH $UPPER_FENCE_MARKER $RIGHT_FENCE_MARKER $LOWER_FENCE_MARKER $LEFT_FENCE_MARKER $CORNER_MARKER "Fixing current packages..."
	apt --fix-broken install
	printFooter $MENU_WIDTH $LOWER_FENCE_MARKER $CORNER_MARKER

	printHeader $MENU_WIDTH $UPPER_FENCE_MARKER $RIGHT_FENCE_MARKER $LOWER_FENCE_MARKER $LEFT_FENCE_MARKER $CORNER_MARKER "Removing unnecessary packages..."
    apt autoremove -y
    printFooter $MENU_WIDTH $LOWER_FENCE_MARKER $CORNER_MARKER

    printHeader $MENU_WIDTH $UPPER_FENCE_MARKER $RIGHT_FENCE_MARKER $LOWER_FENCE_MARKER $LEFT_FENCE_MARKER $CORNER_MARKER "Removing unnecessary packages..."
    apt full-upgrade
    printFooter $MENU_WIDTH $LOWER_FENCE_MARKER $CORNER_MARKER
}

clearWarnings () {
	chmod a+x aptsources-cleanup.pyz
	./aptsources-cleanup.pyz
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
	updatePackages
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

	printHeader "-" "-" "|" $MENU_WIDTH "Generate SSH key "

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

configSSH () {
	task='configure ssh'
	requestApproval $task | read answer

	if [ "$answer" == "y" ]; then
		printHeader "#" "#" "|" 50 "SSH key configuration"
		generateSSHKey "id" "rsa"
		waitUser 

		testSSHConnection "id" "rsa"

		getInfo "git e-mail"
		configGitUser $?
		
		getInfo "git name"
		configGitMail $?
	fi
}

cloneRepositories () {
	git clone "git@github.com:$1/$2.git"
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

preparePackages $1
#configSSH
