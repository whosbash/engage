#!/bin/bash

cwd="$(echo "$(pwd)")"

# Colors and styles
source "$cwd/styles/styles.sh"

# GLobal definitions
source "$cwd/definitions.sh"

# Utilitaries
source "$cwd/utils/utils.sh"

# Interface functions
source "$cwd/interface/interface.sh"

# Core functionalities
source "$cwd/core/core.sh"

###################################################################################################
###################################################################################################
#                                                                                                 #
# Main program                                                                                    #
#                                                                                                 #
###################################################################################################
###################################################################################################

InstallEssentialPackages
preparePackages
prepareSystemConfig $1
prepareGit

exit 1;
