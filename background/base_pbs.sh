cat <<EOF
#!/bin/bash
#SBATCH --job-name=$1
#SBATCH -o $1.o-%a
#SBATCH -e $1.err-%a
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=cap10@ufl.edu
#SBATCH -t 4:00:00
#SBATCH --cpus-per-task=1
#SBATCH -N2
#SBATCH --mem-per-cpu=2gb
#SBATCH --array=1-$3

module load gcc/5.2.0 R/3.2.2
cd /ufrc/singer/cap10/montreal-digest
tar=\$(printf 'input/digest/background/$2/base/%03d.rds' \$SLURM_ARRAY_TASK_ID)
make \$tar
EOF
