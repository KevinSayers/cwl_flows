cwlVersion: v1.0
class: Workflow

requirements:
 - class: ScatterFeatureRequirement
 - class: InlineJavascriptRequirement
 - class: StepInputExpressionRequirement
 - $import: readPair.yml

inputs:
    forward: File
    reverse: File
    seqid: string
    seed: int[]
    number: int[]
    rep: int[]

outputs:
    resampled_fastq:
        type: "readPair.yml#FilePair"
        outputSource: collect_output/fastq_pair_out
steps:
    subsample_1:
        in:
            fastq: forward
            seed: seed
            number: number
            rep: rep
            seqid: seqid
            read_number:
                valueFrom: ${return 1;}
        scatter: [seed, number, rep]
        scatterMethod: dotproduct
        out: [seqtkout]
        run: seqtk_sample.cwl
    subsample_2:
        in:
            fastq: reverse
            seed: seed
            number: number
            rep: rep
            seqid: seqid
            read_number:
                valueFrom: ${return 2;}
        scatter: [seed, number, rep]
        scatterMethod: dotproduct
        out: [seqtkout]
        run: seqtk_sample.cwl
    collect_output:
        run:
            class: ExpressionTool
            inputs:
                seq_1:
                    type:
                        type: array
                        items: File
                seq_2:
                    type:
                        type: array
                        items: File
                seqid: string
            outputs:
                fastq_pair_out: "readPair.yml#FilePair"
            expression: >
                ${
                    var ret=[];
                    for (var i = 0; i < inputs.seq_1.length; ++i) {
                        var tmp = {}
                        tmp['forward'] = inputs.seq_1[i];
                        tmp['reverse'] = inputs.seq_2[i];
                        tmp['seqid'] = inputs.seqid
                        ret.push(tmp);
                    }
                    return { 'fastq_pair_out' : ret }
                }
        in:
            seq_1: subsample_1/seqtkout
            seq_2: subsample_2/seqtkout
            seqid: seqid
        out:
            [ fastq_pair_out ]
