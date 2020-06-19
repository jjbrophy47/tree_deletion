#!/bin/bash
#SBATCH --partition=long
#SBATCH --job-name=performance
#SBATCH --output=jobs/logs/performance/higgs
#SBATCH --error=jobs/errors/performance/higgs
#SBATCH --time=3-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=9
#SBATCH --account=uoml
module load python3/3.7.5

model_type=$1
criterion=$2
tune_frac=$3

dataset="higgs"
scoring="roc_auc"
data_dir="data/"
out_dir="output/performance/"
verbose=2

python3 experiments/scripts/performance.py \
  --data_dir $data_dir \
  --out_dir $out_dir \
  --dataset $dataset \
  --tune_frac $tune_frac \
  --model_type $model_type \
  --scoring $scoring \
  --criterion $criterion \
  --verbose $verbose
