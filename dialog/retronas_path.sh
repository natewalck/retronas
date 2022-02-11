#!/bin/bash

_CONFIG=/opt/retronas/dialog/retronas.cfg
source $_CONFIG
source ${DIDIR}/common.sh
cd ${DIDIR}

rn_retronas_path() {
  DLG_DSELECT "Please type in the RetroNAS top level directory" "${OLDRNPATH}"
}

# Show the ugly path chooser
rn_retronas_path
case $CHOICE in
  0)
    NEWRNPATH=$CHOICE
    unset ${CHOICE}
    # Confirm the input because the path chooser sucks
    rn_retronas_path_confirm "${NEWRNPATH}"
    ;;
  *)
    exit ${CHOICE}
    ;;
esac

rn_retronas_path_confirm() {
  local NEWRNPATH="${1}"

  local MENU_BLURB="\nDo you want to save this setting? \
  \nNewRetroNAS top level directory: \"${NEWRNPATH}\""

  DLG_YN "Confirm" "${MENU_BLURB}"
}

case ${CHOICE} in
  0)
    # Yes, change the value
    # Delete the old value
    sed -i '/retronas_path:/d' "${ANCFG}"
    # Add the new value and re-source
    echo "retronas_path: \"${NEWRNPATH}\"" >> "${ANCFG}"
    source $_CONFIG
    exit 0
    ;;
  *)
    # No, the path chooser sucks probably, so just bail
    exit ${CHOICE}
    ;;
esac
