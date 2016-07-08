cat <<EOF
#!/bin/bash
#SBATCH -r n
#SBATCH --job-name=$1
#SBATCH -o $1.o
#SBATCH -e $1.err
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=cap10@ufl.edu
#SBATCH -t 24:00:00
#SBATCH --cpus-per-task=1
#SBATCH -N1
#SBATCH --mem-per-cpu=16gb

module load gcc/5.2.0 R/3.2.2
cd /ufrc/singer/cap10/montreal-digest
tar=\$(printf 'input/digest/background/$2/agg/%03d.rds' $3)
make \$tar
EOF
