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
    assemblies:
        type: File[]
        outputSource: spades/assembly
    mlst_res:
        type: File[]
        outputSource: mlst/mlstout

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

    unpack_output:
        run:
            class: ExpressionTool
            inputs:
                nested_read_pairs:
                    type:
                        type: array
                        items: Any
            outputs:
                read_pairs:
                    type: "readPair.yml#FilePair[]"
            expression: >
                ${
                    var ret=[];
                    for (var i = 0; i < inputs.nested_read_pairs.length; ++i) {
                        for (var j = 0; j < inputs.nested_read_pairs[i].length; ++j){
                        ret.push(inputs.nested_read_pairs[i][j]);
                        }
                    }
                    return { 'read_pairs' : ret }
                }
        in:
            nested_read_pairs: subsample/resampled_fastq
        out:
            [read_pairs]

    spades:
        in:
            forward_reads:
                source: unpack_output/read_pairs
                valueFrom: $(self.forward)
            reverse_reads:
                source: unpack_output/read_pairs
                valueFrom: $(self.reverse)
            output_dir:
                source: unpack_output/read_pairs
                valueFrom: $(self.seqid)-$(self.number[0])-$(self.seed[0])-$(self.rep[0])_spades
            only_assembler:
                valueFrom: ${return true;}
            threads:
                valueFrom: ${return 2;}
            kmers:
                valueFrom: ${return "33";}
        out:
            [assembly]
        scatter: [forward_reads, reverse_reads, output_dir]
        scatterMethod: dotproduct
        run: spades.cwl

    mlst:
        in:
            contigs:
                source: spades/assembly
        out:
            [mlstout]
        scatter: contigs
        run: mlst.cwl
