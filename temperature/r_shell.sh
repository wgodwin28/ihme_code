#!/bin/sh
#$ -S /bin/sh

#/usr/local/R-current/bin/Rscript "$@"
/share/local/codem/public_use_anaconda/lib/R/bin/R <$1 --no-save $@
echo $@
#/share/local/codem/public_use_anaconda/lib/R/bin/Rscript "$@"
#/share/local/R-3.2.4/bin/R "$@"

# qsub -N "DHS_01" -pe multi_slot 75 -P proj_custom_models -o /share/scratch/users/rupdike/save_results -e /share/scratch/users/rupdike/save_results /home/j/temp/rupdike/R_shell.sh
# -l mem_free=40