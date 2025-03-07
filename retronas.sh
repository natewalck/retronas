#!/bin/bash

_CONFIG=/opt/retronas/config/retronas.cfg
source $_CONFIG
source ${LIBDIR}/common.sh

DISABLE_GITOPS=0
CF="$ANCFG"

#
# CHECK we are running as ROOT
#
CHECK_ROOT

_usage() {
  echo "Usage $0" 
  echo "-h this help"
  echo "-d show disclaimer"
  echo "-g disable git operations"
  echo "-l show license"
  echo "-t terminal choice (current|vterm)"
  exit 0
}

OPTSTRING="hdgt:"
while getopts $OPTSTRING ARG
do
  case $ARG in
    h)
      _usage
      ;;
    g)
      DISABLE_GITOPS=1
      ;;
    t)
      TCHOICE=${"":-OPTARG}
      ;;
    d)
      # redisplay agreement
      [ -f $AGREEMENT ] && rm -f $AGREEMENT
      ;;
    l)
      # display license
      cat $RNDIR/LICENSE
      ;;
  esac
done

#### DO NOT TOUCH THE SYSTEM UNTIL USER AGREES TO DISCLAIMER
bash $DIDIR/disclaimer.sh
[ $? -ne 0 ] && echo "User did not accept terms of use, exiting" && EXIT_CANCEL


### ANSIBLE_VARS
cd $RNDIR
if [ -f "${ANCFG}" ]
then
  echo "Config file exists, not creating it"
else
  echo "Config file missing, creating it"
  cp "${ANCFG}.default" "${ANCFG}"
fi

# check if apt was updated in the last 24 hours
if find /var/cache/apt -maxdepth 1 -type f -mtime -1 -exec false {} +
then
  echo "APT repositories are old, syncing..."
  apt update
fi

#
# DEPENDENCIES
#
# jq, kept here to handle migration to new menu system
if [ ! -f /usr/bin/jq ] 
then
  apt-get -y install jq
  [ $? -ne 0 ] && PAUSE && EXIT_CANCEL
fi

### source the config to update vars on first run
source $_CONFIG

### LANG UTF-8 patch (this probably needs more testing)
export LANG=$(echo $LANG | sed -r 's/(\.| )UTF(-?)8//gi')

### check default user exists
id $OLDRNUSER &>/dev/null
if [ $? -ne 0 ]
then
  echo -e "User $OLDRNUSER does not exist on this system\n opening the user config dialog"
  cd $DIDIR
  bash d_input.sh update-user
fi

### Manage install through git
if [ $DISABLE_GITOPS -eq 0 ] && [ ! -f ${USER_CONFIG}/disable_gitops ]
then
  echo "Fetching latest RetroNAS scripts..."
  git config pull.rebase false
  git reset --hard HEAD
  git pull
else
  echo "Skipping script updates, git operations were disabled"
fi

### Make sure log dir exists
[ ! -d $LOGDIR ] && mkdir $LOGDIR && chmod 755 $LOGDIR

### Set term emulation,
if [ -z $TCHOICE ]
then
  clear
  echo
  echo "Please choose your terminal encoding:"
  echo
  echo "1) Current - ${TERM} [DEFAULT]"
  echo "2) vt100 (best for telnet and retro computers)"
  echo
  read TCHOICE
else
  echo "We already know your TERM so moving on"
fi

case "${TCHOICE}" in
  VT100|vt100|2*)
    echo "Setting TERM to vt100"
    export TERM=vt100
    ;;
  *)
    echo "Leaving TERM as ${TERM}"
    ;;
esac

### Checking for new startup, old installs wont have it
if [ ! -x /usr/local/bin/retronas ]
then
    clear
    #installing a simple starup script
    cp /opt/retronas/dist/retronas /usr/local/bin/retronas
    chmod a+x /usr/local/bin/retronas
    echo -e "We have upgraded your RetroNAS, you can now run the RetroNAS config tool with the following command:\n\nretronas\n\nThis message will appear only once\n"
    echo "Press enter to continue"
    read -s
fi

### Start RetroNAS
echo "Running RetroNAS..."
cd $DIDIR
bash d_menu.sh main
