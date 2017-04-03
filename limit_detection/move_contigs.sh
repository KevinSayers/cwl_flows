#!/usr/bin/env bash

# position $1 --- path to spades contig.fasta
# position $2 --- new name

OLD_SPADES_CONTIG=$1
NEW_SPADES_CONTIGS=$2.fasta

mv ${OLD_SPADES_CONTIG} ${HOME}/${NEW_SPADES_CONTIGS}
