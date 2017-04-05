'''
Take a bunch of yml inputs and run them in parallel
'''

import click
import multiprocessing
import logging
import subprocess
import shlex
import os
import json

#def run_cwltool(tool, inyml, cachedir = None, tmpdir = None):
def run_cwltool(args):
    tool, inyml, cachedir, tmpdir = args
    cmd = 'cwltool'
    yml_prefix = inyml.strip(".yml")
    if cachedir != None:
        cmd += ' --cachedir {}'.format(os.path.join(cachedir, yml_prefix))
    if tmpdir != None:
        cmd += ' --tmpdir-prefix {}'.format(os.path.join(tmpdir, yml_prefix))
    cmd += ' {} {}'.format(tool, inyml)
    logging.info("Running {}".format(cmd))
    p = subprocess.Popen(shlex.split(cmd), stdout = subprocess.PIPE, stderr = subprocess.PIPE)
    out, err = p.communicate()
    logging.info("Output from {} was: {}".format(inyml, out))
    logging.info("Error from {} was: {}}".format(inyml, err))
    return json.loads(out)

def build_jobs(tool, inyml, cachedir, tmpdir):
    jobs = []
    logging.info("Creating jobs list...")
    for yml in inyml:
        jobs.append((tool, yml, cachedir, tmpdir))
    logging.info("Created {} jobs...".format(len(jobs)))
    return jobs

@click.command()
@click.argument('cwl_tool', nargs = 1)
@click.argument('cwl_inputs', nargs = -1)
@click.option('--n_jobs', '-j', default = 9,
    help="Number of concurrent jobs", show_default = True)
@click.option("--cachedir_prefix", "-c", default = None,
    help="A prefix path for cachedir", show_default = True)
@click.option("--tmpdir_prefix", "-t", default = None,
    help="A prefix path for the tmpdir", show_default = True)
def parallel_cwltool(cwl_tool, cwl_inputs, n_jobs, cachedir_prefix, tmpdir_prefix):
    jobs = build_jobs(cwl_tool, cwl_inputs, cachedir_prefix, tmpdir_prefix)
    p = multiprocessing.Pool(n_jobs)
    results = p.map(run_cwltool, jobs)
    pass

if __name__ == "__main__":
    FORMAT = '%(asctime)-15s %(message)s'
    logging.basicConfig(format=FORMAT, datefmt = '%Y-%m-%d', level = 'DEBUG')
    parallel_cwltool()
