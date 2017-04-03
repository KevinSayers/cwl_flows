cwlVersion: v1.0
class: CommandLineTool

baseCommand: spades-fast

requirements:
 - class: ResourceRequirement
   coresMin: 2
   coresMax: 8

inputs:
    forward_reads:
        type: File
        inputBinding:
            prefix: "--R1"
            position: 1
    reverse_reads:
        type: File
        inputBinding:
            prefix: "--R2"
            position: 2
    threads:
        type: int
        inputBinding:
            prefix: "--cpus"
            position: 3
    kmers:
        type: string?
        inputBinding:
            prefix: "--kmers"
            position: 3
    genome_size:
        type: float?
        inputBinding:
            prefix: "--gsize"
            position: 3
    output_dir:
        type: string
        inputBinding:
            prefix: "--outdir"
            position: 4
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
