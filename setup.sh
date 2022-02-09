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

prepareSystemConfig $1
preparePackages
prepareGit

exit 1;
