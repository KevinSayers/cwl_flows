cwlVersion: v1.0
class: CommandLineTool

baseCommand: spades.py

requirements:
 - class: ResourceRequirement
   coresMin: 2
   coresMax: 8

inputs:
    forward_reads:
        type: File
        inputBinding:
            prefix: "-1"
            position: 1
    reverse_reads:
        type: File
        inputBinding:
            prefix: "-2"
            position: 2
    threads:
        type: int
        inputBinding:
            prefix: "--threads"
            position: 3
    only_assembler:
        type: boolean
        inputBinding:
            prefix: "--only-assembler"
            position: 4
    kmers:
        type: string
        inputBinding:
            prefix: "-k"
            position: 5
    output_dir:
        type: string
        inputBinding:
            prefix: -o
            position: 6
outputs:
    assembly:
        type: File
        outputBinding:
            glob: $(inputs.output_dir)/contigs.fasta
    run_id:
        type: string
        outputBinding:
            outputEval: ${
                return inputs.output_dir;
                }
