#!/bin/bash

installAPTPackage(){
	#  Check to see if Xclip is installed if not install it
	if [ $(dpkg-query -W -f='${Status}' $1 | grep -c "ok installed") -eq 0 ];
	then
	  echo "\"$1\" is not installed .... installing now!"
	  apt install $1 -y;
	else
	  echo "\"$1\" installed!"
	fi
}

installSnapPackage () {
	if [ $(snap list | grep -c $1) -eq 0 ]
	then
	   echo "\"$1\" is not installed .... installing now!";
	   snap install $1 --classic
	else
	  echo "\"$1\" is installed!"
	fi
}

# Install useful utils from different package repositories
installPackages() {	
	# snap
	sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
	wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
	apt-get install google-chrome-stable
	
	# apt-get
	for package in git python3-dev python3-pip virtualenv ipe xclip 
	do
		installAPTPackage $package
	done
	
	# snap
	for package in slack sublime-text
	do
		installSnapPackage $package
	done

	# pip
	pip install numpy pandas matplotlib scipy scikit-learn notebook
}

# Update, upgrade and fix packages
updatePackages() {
	printHeader ""

	apt update
	apt-get upgrade -y
	apt --fix-broken install
    apt autoremove -y
    apt full-upgrade

}

preparePackages() {
	# Save tilde as home alias
	if grep -q "alias ~=/home/$1" /home/$1/.bashrc; 
	then
		echo "Home alias is already tilde ~."
	else
		echo "alias ~=/home/$1" >> /home/$1/.bashrc
	fi

	installPackages
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
	local end=${1:-80}
	local str="${2:-=}"
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
	declare -i line_length=$4
	
	# Upper and lower fences 
	local upper_command="print \"$1\" *" 
	local upper_fence="$(python -c "$upper_command $line_length")*"

	local lower_command="print \"$2\" *"
	local lower_fence="$(python -c "$lower_command $line_length")*"
	
	# Slice words by some character counter
	local regex_counter="s/(.{$line_length})/\1\n/g"
	local regex_trimmer='s/(^ | $)//g'

	# Complete line with dots and a pipe
	local res="$line_length - length"
	local dot_line="$(repeat $line_length "."; echo)"
	
	local arg_0='$0'
	local arg_1="substr(\"$dot_line\", 1, rest)"
	
	local fill_command="{rest=($res); printf \"%s%s$3\n\", $arg_0, $arg_1}"

	echo "$upper_fence"
	sed -r -e "$regex_counter" <<< $5 | sed -r "$regex_trimmer" | awk "$fill_command"
	echo "$lower_fence"
}

generateSSHKey () {
	declare file_path="/$(whoami)/.ssh/$1_$2"
	declare full_file_path="$file_path.pub"
	
	declare file_folder=$(whoami)
	declare file_name=$1
	declare file_extension=$2

	printHeader "-" "-" "|" 50 "Generate SSH key "

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

configSSH () {
	printHeader "#" "#" "|" 50 "SSH key configuration"
	generateSSHKey "id" "rsa"
	waitUser 
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

configSSH