#!/usr/bin/env sh

# Set stop on error / enable debug
set -euo pipefail
#set -vx

############################################################################
# INSTALL LUCIDITI CONFIG
############################################################################

##{{{#######################################################################
############################################################################
# FUNCTIONS
############################################################################

# Clean Upon Exit
cleanup() {
  # Exit safely for private config
  exit 0
}
if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
  trap cleanup EXIT
fi

# Print a string line wrapped in "===" headers
printline() {
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =
  printf "%s\n" "$1"
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' =
}

#  Logging functions
readonly LOG_FILE="/tmp/$(basename "$0").log"
info()    { echo "[INFO]    $*" | tee -a "$LOG_FILE" >&2 ; }
warning() { echo "[WARNING] $*" | tee -a "$LOG_FILE" >&2 ; }
error()   { echo "[ERROR]   $*" | tee -a "$LOG_FILE" >&2 ; }
fatal()   { echo "[FATAL]   $*" | tee -a "$LOG_FILE" >&2 ; exit 1 ; }

# Accept Message & Error Code
quit() {
  if [[ -z $1 ]]; then MESSAGE="An error has occurred"; else MESSAGE=$1; fi
  if [[ -z $2 ]]; then ERROR_CODE=1; else ERROR_CODE=$2; fi
  echo "$MESSAGE" 1>&2; exit "$ERROR_CODE";
}

# Retrieve an Ansible var in playbook.
ansible_var() {
  if [[ ! -z "$1" ]]; then
    VAR="$1"
    echo $(ansible-playbook main.yml -i inventory --tags "get-var" --extra-vars "var_name=$VAR" | grep "$VAR" | sed -e 's/[[:space:]]*"\([^"]*\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\2/g' | sed -e "s/\"$VAR\": null//g" | sed -e "s/VARIABLE IS NOT DEFINED!//g" )
  fi
}

############################################################################
# VARS
############################################################################
# Output colors.
C_HIL="\033[36m"
C_WAR="\033[33m"
C_SUC="\033[32m"
C_ERR="\033[31m"
C_RES="\033[0m"

ANSIBLE_TAGS=""
SCRIPTS_DIRECTORY="$(dirname $0)"

##}}}#######################################################################

#/ Usage: $SCRIPT [CONFIG_URL]
#/
#/   <CONFIG_URL>: An HTTP URL containing a config.yml to use.
#/ Examples:
#/ Options:
#/   --help: Display this help message
SCRIPT=$(basename "$0")
usage() { grep '^#/' "$0" | cut -c4- | sed -e 's/\$SCRIPT/'"$SCRIPT"'/g' ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && usage

############################################################################
# MAIN
############################################################################

# Add Ansible requirements...
if [[ -f "requirements.yml" ]]; then
  echo ""
  echo "${C_HIL}Installing Luciditi Requirements...${C_RES}"
  ansible-galaxy install -r requirements.yml
fi


# Start Ansible playbook
if [[ -f "main.yml" ]]; then
  echo ""
  echo "${C_HIL}Installing Luciditi config...${C_RES}"
  ansible-playbook main.yml -i inventory -K --tags "$ANSIBLE_TAGS"
fi

exit 0
