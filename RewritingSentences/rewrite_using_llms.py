import argparse

import openai
import json


def rewrite_news_headlines(news_path, write_path, model_name):
    """
    Rewrite biased news headlines to eliminate any elements of media bias without altering the original meaning.
    :param news_path: The path to the file containing original news headlines.
    :param write_path: The path to the file where the rewritten headlines generated by LLMs will be saved.
    :param model_name: The name of the model to use for rewriting,
    either gpt-3.5-turbo-1106 or gpt-4-1106-preview in my experiments.
    :return: None
    """
    num_bias = 0

    # Ensure that the OpenAI API key is provided in your environment
    if not openai.api_key:
        raise ValueError("OpenAI API key not found. Please set the OPENAI_API_KEY environment variable.")

    with open(news_path, "r") as f_read, open(write_path, "a") as f_write:
        for idx, line in enumerate(f_read):
            line_split = line.split("\n").split("\t")

            news_id = line_split[0]
            news_headline = line_split[3]
            is_bias = line_split[-1]
            if is_bias == 'True':
                num_bias += 1
                if num_bias % 100 == 0:
                    print(f"process {num_bias} biased news headlines")

                    prompt_input = f"The news headline: {news_headline} \
            The objective is to rewrite the above news headline to eliminate any elements of media bias without altering the original meaning. \
            The output: the rewritten sentence. Do not explain the reason or include any other words. "

                    completion = openai.ChatCompletion.create(
                        model=model_name,
                        messages=[
                            {'role': 'user', 'content': prompt_input}
                        ]
                    )
                    output_string = completion["choices"][0]["message"]["content"]
                    result_dict = dict()
                    result_dict["nid"] = news_id
                    result_dict["rewritten"] = output_string
                    result_dict["original"] = news_headline
                    json.dump(result_dict, f_write)
                    f_write.write('\n')


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--news_path", type=str, )
    parser.add_argument("--write_path", type=str, )
    parser.add_argument("--model_name", type=str, )
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()
    rewrite_news_headlines(news_path=args.news_path,
                           write_path=args.write_path,
                           model_name=args.model_name)
