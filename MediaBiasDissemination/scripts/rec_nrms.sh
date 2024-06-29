#!/bin/bash


rm -rf "${1}"
rm -rf "${10}"
mkdir -p "${10}"
cp -r "/home/qinruan/debias/files/observers" "${10}/"
cp -r "/home/qinruan/debias/files/hp_recommenders" "${10}/"

original_news_file_path="/home/qinruan/debias/files/data0319/03198_news.tsv"
original_user_file_path="/home/qinruan/debias/files/data0319/03198_user_groups.tsv"
nid2bias_path="/home/qinruan/debias/files/data0319/nid2bias_prob.pkl"
data_dir="/home/qinruan/debias/files/data0404"
nid2emb_str_path="/home/qinruan/debias/files/nid2emb_str_path.pkl"
load_ckpt_name_path="${9}"
simulation_dir="${10}/observers/"
model_code_dir="${10}/hp_recommenders/"

mkdir -p "${1}"

while read p; do

  cd "${simulation_dir}"
  if [[ ${12} == 'apply_none' ]]
  then
    echo "apply_none"
    python simulate_behaviors.py \
    --original_behaviors_path "${original_user_file_path}" \
    --original_news_path "${original_news_file_path}" \
    --nid2bias_path "${nid2bias_path}" \
    --write_dir "${1}" \
    --pseudo_step "${p}" \
    --candidate_news_mode "${2}" \
    --news_candidate_strategy "${3}"
  else
    python simulate_behaviors_debias.py \
    --original_behaviors_path "${original_user_file_path}" \
    --original_news_path "${original_news_file_path}" \
    --nid2bias_path "${nid2bias_path}" \
    --write_dir "${1}" \
    --pseudo_step "${p}" \
    --candidate_news_mode "${2}" \
    --news_candidate_strategy "${3}" \
    --apply_mode "${12}" \
    --apply_news_path="${13}"
  fi

  cd "${simulation_dir}"
  python simulate_behaviors_fmt3.py \
    --write_dir "${1}" \
    --pseudo_step "${p}" \
    --nid2emb_str_path "${nid2emb_str_path}"

  cd "${model_code_dir}"
  python run.py \
    --model_dir "${ckpt_dir}" \
    --enable_gpu True \
    --enable_ddp False \
    --eval_first True \
    --mode "infer" \
    --load_ckpt_name "${load_ckpt_name_path}" \
    --trainer "ORIGINALTrainer" \
    --model_name "NRMS" \
    --word_dict_path "${data_dir}/MINDlarge_utils/word_dict.pkl" \
    --embedding_matrix_path "${data_dir}/MINDlarge_utils/embedding.npy" \
    --news_file "${1}/news_pseudo${p}.tsv" \
    --test_news_file "${1}/news_pseudo${p}.tsv" \
    --train_behavior_file "${1}/behaviors_pseudo${p}.tsv" \
    --test_behavior_file "${1}/behaviors_pseudo${p}.tsv" \
    --epochs 5 \
    --test_news_batch_size 512 \
    --test_user_batch_size 512 \
    --batch_size 32 \
    --res_write_path "${1}/behaviors_pseudo${p}_predictions.pkl"

  cd "${simulation_dir}"
  if [[ ${3} == 'fixed' ]]
  then
    echo "fixed prediction"
    python simulate_fmt2_fixed_prediction.py \
      --top_k "${5}" \
      --pseudo_step "${p}" \
      --write_dir "${1}"
  else
    echo "dynamic prediction"
    python simulate_fmt2_dynamic_prediction.py \
      --top_k "${5}" \
      --pseudo_step "${p}" \
      --write_dir "${1}"
  fi

  cd "${simulation_dir}"
  python simulate_user_decision.py \
    --original_behaviors_path "${original_user_file_path}" \
    --pseudo_step "${p}" \
    --write_dir "${1}" \
    --nid2bias_path "${nid2bias_path}" \
    --original_behaviors_path "${original_user_file_path}" \
    --selected_n "${6}" \
    --strategy "${7}"

  rm -rf "${1}/news_pseudo${p}.tsv"
  rm -rf "${1}/behaviors_pseudo${p}.tsv"

done < "${8}"

# Due to limited storage space, try to delete intermediate and unnecessary result files
find "${1}" -type f ! -name 'top_nid_*' ! -name 'user_choice.pkl' -print0 | xargs -0 rm
path="${1}"
dir="${path%/*}/"
file="${path##*/}"
mv "${1}/user_choice.pkl" "${dir}${file}_user_choice.pkl"
mv "${1}" "${1}_top_nid"
tar -czvf "${dir}${file}_top_nid.tar" -C "${dir}" "${file}_top_nid"
rm -rf "${1}_top_nid"
rm -rf "${10}"