#!/usr/bin/env python3

'''
Collect MLST results
'''

import os
import sys
from fnmatch import fnmatch

def parse_run(run_path):
    run_id = os.path.basename(run_path)
    run_id = run_id.split('_')[0]
    run_id = run_id.split('-')
    rid = run_id[0]
    n_reads = run_id[1]
    seed = run_id[2]
    rep = run_id[3]
    return (rid, n_reads, seed, rep)

def parse_result(filename):
    fn = open(filename, 'r')
    line = fn.readline().strip()
    fn.close()
    line = line.split('\t')
    rid, n_reads, seed, rep = parse_run(line[0])
    scheme = line[1]
    st = line[2]
    if len(line) > 3:
        mlst_alleles = ';'.join(line[3:])
    else:
        mlst_alleles = '-'
    return '\t'.join([rid, n_reads, seed, rep, scheme, st, mlst_alleles])

if __name__ == '__main__':
    list_of_files = sys.argv[1]
    output_file = sys.argv[2]
    fl = open(list_of_files)
    fn = open(output_file, 'w')
    for mlstout in fl:
        mlstout = mlstout.strip()
        mlstout = parse_result(mlstout)
        fn.write(mlstout+'\n')
    fn.close()
    fl.close()
