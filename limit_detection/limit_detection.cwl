cwlVersion: v1.0
class: Workflow

requirements:
 - class: ScatterFeatureRequirement
 - class: InlineJavascriptRequirement
 - class: StepInputExpressionRequirement
 - class: SubworkflowFeatureRequirement
 - $import: readPair.yml

inputs:
    fqSeqs:
        type:
            type: array
            items: "readPair.yml#FilePair"

outputs:
    fqout:
        type: "readPair.yml#FilePair[]"
        outputSource: subsample/resampled_fastq

steps:
    subsample:
        in:
            forward:
                source: fqSeqs
                valueFrom: $(self.forward)
            reverse:
                source: fqSeqs
                valueFrom: $(self.reverse)
            seqid:
                source: fqSeqs
                valueFrom: $(self.seqid)
            seed:
                source: fqSeqs
                valueFrom: $(self.seed)
            number:
                source: fqSeqs
                valueFrom: $(self.number)
            rep:
                source: fqSeqs
                valueFrom: $(self.rep)
        scatter: [forward, reverse, seqid, seed, number, rep]
        scatterMethod: dotproduct
        out: [resampled_fastq]
        run: seqtk_sample_PE.cwl
