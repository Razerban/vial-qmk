#!/bin/bash

echo "############################################"
echo "#### Updating submodules                ####"
echo -e "############################################\n"
make git-submodule >/dev/null 2>&1

echo "############################################"
echo "#### Building Andromeda firmware        ####"
echo "############################################"
make clean >/dev/null 2>&1
echo "#    Building default firmware             #"
if ! make razerban/andromeda:default 1>/dev/null;
then
  exit 1
fi
make clean >/dev/null 2>&1
echo "#    Building VIAL firmware                #"
if ! make razerban/andromeda:vial 1>/dev/null;
then
  exit 1
fi
echo -e "############################################\n"

make clean >/dev/null 2>&1
