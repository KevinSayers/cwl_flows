cwlVersion: v1.0
class: CommandLineTool

baseCommand: ['seqtk', 'sample']
stdout: $(inputs.seqid)___$(inputs.number)-$(inputs.seed)-$(inputs.rep)___R$(inputs.read_number).fq
inputs:
    seed:
        type: int
        inputBinding:
            prefix: -s
            position: 1
    fastq:
        type: File
        inputBinding:
            position: 2
    number:
        type: int
        inputBinding:
            position: 3
    seqid: string
    read_number: int
    rep: int
outputs:
    seqtkout:
        type: stdout
