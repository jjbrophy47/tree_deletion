#!/bin/bash
#SBATCH --partition=long
#SBATCH --job-name=no_retrain
#SBATCH --output=jobs/logs/no_retrain/mfc20
#SBATCH --error=jobs/errors/no_retrain/mfc20
#SBATCH --time=1-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=3
#SBATCH --account=uoml
module load python3/3.7.5

dataset="mfc20"
step_size=25
n_estimators=100
max_depth=20
max_features=0.25
criterion="entropy"
model_type="forest"

data_dir="data/"
out_dir="output/no_retrain/"
rs_list=(1 2 3 4 5)


for i in ${!rs_list[@]}; do
    python3 experiments/scripts/no_retrain.py \
      --data_dir $data_dir \
      --out_dir $out_dir \
      --dataset $dataset \
      --step_size $step_size \
      --model_type $model_type \
      --n_estimators $n_estimators \
      --max_depth $max_depth \
      --max_features $max_features \
      --criterion $criterion \
      --rs ${rs_list[$i]}
done
