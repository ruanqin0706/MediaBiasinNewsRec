#!/bin/bash

rm -rf "${1}"
rm -rf "${10}"
rm -rf "${11}"
mkdir -p "${10}"
cp -r "{replace_with_your_own_folder}/simulation1" "${10}/"
cp -r "{replace_with_your_own_folder}/News-Recommendation" "${10}/"
mkdir -p "${11}"
mkdir -p "${11}/MIND"
cp -r {replace_with_your_own_folder}/data0404/* "${11}/MIND/"
cp -r {replace_with_your_own_folder}/PLM "${11}/"

original_news_file_path="{replace_with_your_own_folder}/mediabiasawaredataset/news.tsv"
original_user_file_path="{replace_with_your_own_folder}/mediabiasawaredataset/user_groups.tsv"
nid2bias_path="{replace_with_your_own_folder}/mediabiasawaredataset/nid2bias_prob.pkl"
simulation_dir="${10}/simulation1/"
model_training_dir="${10}/News-Recommendation/src/"
data_root="${11}"
model_path="${9}"

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

  cd "${model_training_dir}"
  rm -rf "${model_training_dir}/data"
  rm -rf "${data_root}/MIND/MINDlarge_test/behaviors.tsv"
  rm -rf "${data_root}/MIND/MINDlarge_test/news.tsv"
  cp "${1}/behaviors_pseudo${p}.tsv" "${data_root}/MIND/MINDlarge_test/behaviors.tsv"
  cp "${1}/news_pseudo${p}.tsv" "${data_root}/MIND/MINDlarge_test/news.tsv"
  wc -l "${data_root}/MIND/MINDlarge_test/behaviors.tsv"
  wc -l "${data_root}/MIND/MINDlarge_test/news.tsv"

  python -m main.twotower \
    --scale 'large' \
    --data-root "${data_root}" \
    --infer-dir "${1}" \
    --suffix "behaviors_pseudo${p}" \
    --checkpoint "${model_path}" \
    --batch-size 32 \
    --world-size 1 \
    --mode "test" \
    --news-encoder bert \
    --batch-size-eval 32 \
    --device "${4}"

  cd "${simulation_dir}"
  if [[ ${3} == 'fixed' ]]
  then
    echo "fixed prediction"
    python simulate_prediction_single_fixed.py \
    --top_k "${5}" \
    --pseudo_step "${p}" \
    --write_dir "${1}"
  else
    echo "dynamic prediction"
    python simulate_prediction_single_dynamic.py \
    --top_k "${5}" \
    --pseudo_step "${p}" \
    --write_dir "${1}"
  fi

  cd "${simulation_dir}"
  python simulate_feedback.py \
    --original_behaviors_path "${original_user_file_path}" \
    --pseudo_step "${p}" \
    --write_dir "${1}" \
    --nid2bias_path "${nid2bias_path}" \
    --original_behaviors_path "${original_user_file_path}" \
    --selected_n "${6}" \
    --strategy "${7}"

done < "${8}"

# Due to limited storage space, try to delete intermediate and unnecessary result files
find "${1}" -type f ! -name '*_news_emb.npy' ! -name '*_user_emb.npy' -print0 | xargs -0 rm
path="${1}"
dir="${path%/*}/"
file="${path##*/}"
tar -czvf "${dir}${file}_news_emb.tar" -C "${dir}" "${dir}${file}"/*_news_emb.npy
tar -czvf "${dir}${file}_user_emb.tar" -C "${dir}" "${dir}${file}"/*_user_emb.npy
rm -rf "${dir}${file}"
rm -rf "${10}"
rm -rf "${11}"
