'''
Make a YAML input file to run the limit of detection pipeline
'''

import yaml
import click
import pandas
import logging
import os
import numpy
import sys

def check_file_readok(filepath):
    logging.info("Checking if can read file {}.".format(os.path.basename(filepath)))
    try:
        fp = open(filepath)
    except PermissionError:
        logging.info("Could NOT open file {}.".format(filepath))
        raise
    else:
        logging.info("Reading file {} is OK.".format(os.path.basename(filepath)))
        fp.close()
        return True

def create_fqSeqs(row, number, reps, seeds):
    out = {}
    out['forward'] = {}
    out['forward']['class'] = 'File'
    out['forward']['path'] = row.READ1

    out['reverse'] = {}
    out['reverse']['class'] = 'File'
    out['reverse']['path'] = row.READ2

    out['seqid'] = row.SAMPLE

    out['number'] = number

    out["rep"] = reps

    out['seed'] = [int(seed) for seed in seeds]

    return out

def generate_seeds(n_samples, n_runs, seed):
    RS = numpy.random.mtrand.RandomState()
    RS.seed(seed)
    seeds = RS.randint(low = 10, high = 10**8, size = (n_samples, n_runs))
    return seeds

@click.command()
@click.argument("input_file")
@click.option("--n_reps", "-n",
    help="Number of replicates per sample per number of reads",
    default = 5, show_default = True)
@click.option("--minsize", "-m",
    help="Minimum number of reads to keep",
    default = 10000, show_default = True)
@click.option("--maxsize", "-x",
    help="Maximum number of reads to keep",
    default = 100000, show_default = True)
@click.option("--stepsize", '-z',
    help="Step size between min and max sizes",
    default = 10000, show_default = True)
@click.option("--steps", "-s",
    help="Comma separated list of number of reads to keep --- \
    will override minsize, maxsize, and stepstze",
    default = None, show_default = True)
@click.option("--seed",
    help="Overall seed used to calculate all seeds",
    default = 42, show_default = True)
@click.option("--split", is_flag = True,
    help="Split over multiple inputs?")
def make_input(input_file, n_reps, minsize, maxsize, stepsize, steps, seed, split):

    # read input file
    input_table = pandas.read_csv(input_file, sep = None, header = None,
        names = ['SAMPLE', 'READ1', 'READ2'], engine="python")
    n_samples = input_table.shape[0]
    logging.debug("Found {} samples.".format(n_samples))

    logging.info("Checking I can read FASTQ files...")
    for row in input_table.itertuples():
        check_file_readok(row.READ1)
        check_file_readok(row.READ2)

    logging.info("All FASTQs were found!")

    # sorting out numbers expect the output to be List[Int, Int, ..., Int]
    if steps == None:
        logging.info("Steps were not specified, using min, max, and step size.")
        numbers = list(range(minsize, maxsize+1, stepsize))

    else:
        logging.info("Actual steps were specified.")
        numbers = steps.split(',')
        numbers = [int(nb) for nb in numbers]

    total_steps = len(numbers)
    logging.info("Total number of steps per sample per replicate is {}".format(total_steps))

    # creating a list of rep number for indexing
    # the list has to be replicated exctly total_steps
    reps = list(range(1, n_reps +1, 1))
    reps = reps * total_steps
    logging.info("Total number of reps per step: {}.".format(n_reps))

    # figuring out total number of runs per sample
    total_runs = total_steps * n_reps
    logging.info("Total number of runs per sample: {}.".format(total_runs))

    # job size
    total_size = total_runs * n_samples
    logging.info("Total job size: {}.".format(total_size))

    # unfolding the numbers to that there are exactly n_reps for number of reads
    # kept
    numbers = [[nb]*n_reps for nb in numbers]
    numbers = [nb for sublist in numbers for nb in sublist]

    # generating some seeds
    logging.info("Generating seeds... ")
    seeds = generate_seeds(n_samples, total_runs, seed)
    logging.debug(seeds)

    # length of reps and numbers should now be equal to total_runs
    logging.info("Checking sanity of data...")
    assert len(numbers) == total_runs
    assert len(reps) == total_runs
    logging.info("Sanity check ok...")

    logging.info("Creating YAML object")
    outyaml = {}
    logging.info("Creating exec path...")
    outyaml['exec_path'] = os.environ["PATH"] + ':' + os.getcwd()

    if not split:
        logging.info("Creating YAML object")
        outyaml = {}
        logging.info("Creating exec path...")
        outyaml['exec_path'] = os.environ["PATH"] + ':' + os.getcwd()
        logging.info("Creating fqSeqs...")
        outyaml['fqSeqs'] = [create_fqSeqs(row, numbers, reps, list(seeds[i])) for i, row in enumerate(input_table.itertuples())]
        outyaml['out_fn'] = 'mlst_res.tab'
        logging.info("Outputting the YAML input:")
        print(yaml.dump(outyaml))
    else:
        logging.info("Creating multiple YAML objects")
        for i, row in enumerate(input_table.itertuples()):
            filename = row.SAMPLE + '_' + str(i)
            fn = open(filename + '.yml', 'w')
            outyaml['fqSeqs'] = [create_fqSeqs(row, numbers, reps, list(seeds[i]))]
            outyaml['out_fn'] = row.SAMPLE + '_' + str(i) + '.tab'
            fn.write(yaml.dump(outyaml))
            fn.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.DEBUG)
    make_input()
