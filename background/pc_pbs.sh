cat <<EOF
#!/bin/bash
#PBS -r n
#PBS -N $1
#PBS -o $1.o
#PBS -e $1.err
#PBS -m a
#PBS -M cap10@ufl.edu
#PBS -l walltime=72:00:00
#PBS -l nodes=1:ppn=8
#PBS -l pmem=4gb
#PBS -t 1-$3

module load gcc/5.2.0 R/3.2.2
cd /scratch/lfs/cap10/montreal-digest
tar=\$(printf 'input/digest/background/$2/pc/%03d.rds' \$PBS_ARRAYID)
make \$tar
EOF
