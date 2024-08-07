import argparse
import heapq
import os

import pickle
import numpy as np


def generate_prediction_res(
        top_n,
        pseudo_step,
        write_dir):
    with open(os.path.join(write_dir, f"behaviors_pseudo{pseudo_step}_predictions.pkl"), "rb") as f:
        res_list = pickle.load(f)
    with open(os.path.join(write_dir, f"candidate_nids_pseudo{pseudo_step}.pkl"), "rb") as f:
        candidate_nid_list = pickle.load(f)
    with open(os.path.join(write_dir, f"candidate2biasprob_pseudo{pseudo_step}.pkl"), "rb") as f:
        nid2bias = pickle.load(f)
    assert len(res_list) == len(candidate_nid_list)

    top_pred_arr = []
    top_nid_arr = []
    top_bias_arr = []
    for res, candidate_nid_set in zip(res_list, candidate_nid_list):
        assert len(res) == len(candidate_nid_set)

        aa = np.asarray(res)
        ind = heapq.nlargest(top_n, range(len(aa)), aa.take)

        top_pred_arr.append([aa[idx] for idx in ind])

        top_nid_arr.append([candidate_nid_set[idx] for idx in ind])
        top_bias_arr.append([nid2bias[candidate_nid_set[idx]] for idx in ind])

    top_bias_arr = np.asarray(top_bias_arr)
    top_pred_arr = np.asarray(top_pred_arr)
    top_nid_arr = np.asarray(top_nid_arr)
    with open(os.path.join(write_dir, f"top_bias_{pseudo_step}.pkl"), "wb") as f:
        pickle.dump(top_bias_arr, f)

    with open(os.path.join(write_dir, f"top_pred_{pseudo_step}.pkl"), "wb") as f:
        pickle.dump(top_pred_arr, f)

    with open(os.path.join(write_dir, f"top_nid_{pseudo_step}.pkl"), "wb") as f:
        pickle.dump(top_nid_arr, f)

    print(f"{pseudo_step}:behaviors prediction finished.")


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--top_k", type=int, default=20)
    parser.add_argument("--pseudo_step", type=str, default="2017-06-26")
    parser.add_argument("--write_dir", type=str, )
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    generate_prediction_res(
        top_n=args.top_k,
        pseudo_step=args.pseudo_step,
        write_dir=args.write_dir)
