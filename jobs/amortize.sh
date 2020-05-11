#!/bin/bash
#SBATCH --partition=long
#SBATCH --job-name=amortize
#SBATCH --output=jobs/logs/amortize/gas_sensor
#SBATCH --error=jobs/errors/amortize/gas_sensor
#SBATCH --time=14-00:00:00       ### Wall clock time limit in Days-HH:MM:SS
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=9
#SBATCH --account=uoml
module load python3/3.7.5

data_dir="data/"
out_dir="output/amortize/"
dataset="gas_sensor"
lmbdas=(320 340 260 340 360)
n_estimators=100
max_depth=10
max_features=0.25
adversaries=("random" "root")
epsilons=(0.1 0.25 0.5 1.0)
rs_list=(1 2 3 4 5)
criterion="gini"


for i in ${!rs_list[@]}; do
    for adversary in ${adversaries[@]}; do
        python3 experiments/scripts/amortize.py --data_dir $data_dir --out_dir $out_dir \
          --dataset $dataset --naive --exact \
          --n_estimators $n_estimators --max_depth $max_depth \
          --max_features $max_features \
          --adversary $adversary --criterion $criterion --rs ${rs_list[$i]}

        for epsilon in ${epsilons[@]}; do
            python3 experiments/scripts/amortize.py --data_dir $data_dir --out_dir $out_dir \
              --dataset $dataset --cedar --lmbda ${lmbdas[$i]} --epsilon $epsilon \
              --n_estimators $n_estimators --max_depth $max_depth \
              --max_features $max_features \
              --adversary $adversary --criterion $criterion --rs ${rs_list[$i]}
        done
    done
done

