#!/bin/bash
# move files from long-term-storage into place for computation
rsync -R /rlts/singer/cap10/montreal-input/./digest/raw/* ./input/
rsync -R /rlts/singer/cap10/montreal-input/./digest/filter/* ./input/