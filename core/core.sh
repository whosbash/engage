#!/bin/bash

cwd="$(echo "$(pwd)")"
source "$cwd/core/utils.sh"

###################################################################################################
###################################################################################################
#                                                    	                                         #
# Resolve tasks                                        	                                         #
#                                                      	                                         #
###################################################################################################
###################################################################################################

# Repositories
addExternalRepositories () {
	# Repository 1
	local repo_cmd_1='add-apt-repository ppa:xtradeb/apps'
	
	local tmp_path="/usr/share/keyrings/brave-browser-archive-keyring.gpg" 
	local route_="https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"

	local repo_subcmd1_2="curl -fsSLo $tmp_path $route_"

	local tmp_path="/usr/share/keyrings/brave-browser-archive-keyring.gpg"
	local route_="https://brave-browser-apt-release.s3.brave.com/"
	local repo_subcmd2p1_2="echo \"deb [signed-by=$tmp_path arch=amd64] $route_ stable main\""
	local repo_subcmd2p2_2='tee /etc/apt/sources.list.d/brave-browser-release.list'
	local repo_cmd_2="$repo_subcmd1_2 && $repo_subcmd2p1_2 | $repo_subcmd2p2_2"
	
	local import_repo_cmds="$repo_cmd_1 && $repo_cmd_2"
	
	wrapHeaderFooter "Import external repositories" "$import_repo_cmds"
}

manageDuplicates () {
	wrapHeaderFooter "Remove package duplicates" "removeDuplicates"
}

resolveRepositories () {
	resolveAPTRepository
	resolveSnapRepository
	resolvePipRepository
}

# Install useful utils from different package repositories
managePackages() {		
	wrapHeaderFooter "Install repositories packages" \
					 "managePipPackages && echo && \
					  manageSnapPackages && echo && \
					  manageAptPackages && echo"
}

resolvePackages () { 
	addExternalRepositories
	managePackages
	resolveRepositories
	manageDuplicates
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
	local ssh_path="/$(whoami)/$filename _$file_suffix.pub"
	echo
	echo -e "In case you generated the SSH, it is available on $ssh_path"
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
#                                                    	                                         #
# Prepare tasks                                        	                                         #
#                                                      	                                         #
###################################################################################################
###################################################################################################

prepareSystemConfig () {
	local command_="resolveSystemConfig $1"
	local task='configure system minors (currently: change home to alias ~)'
	local title="Minor system configurations"
	
	decorateAskAndEval "$title" "$task" "$command_" 
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