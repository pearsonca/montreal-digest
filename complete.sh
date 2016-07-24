#!/bin/bash
# move files from local output to long term storage
rsync -R ./input/ /rlts/singer/cap10/montreal-input/./digest/raw/
rm X Y Z