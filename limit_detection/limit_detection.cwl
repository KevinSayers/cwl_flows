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
    exec_path:
        type: string
    out_fn:
        type: string

outputs:
    mlst_collection:
        type: File
        outputSource: collect_mlst_res/mlst_table

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

    spades-fast:
        in:
            forward_reads:
                source: unpack_output/read_pairs
                valueFrom: $(self.forward)
            reverse_reads:
                source: unpack_output/read_pairs
                valueFrom: $(self.reverse)
            output_dir:
                source: unpack_output/read_pairs
                valueFrom: $(self.seqid)___$(self.number[0])-$(self.seed[0])-$(self.rep[0])___spades
            threads:
                valueFrom: ${return 8;}
        out:
            [assembly, run_id]
        scatter: [forward_reads, reverse_reads, output_dir]
        scatterMethod: dotproduct
        run: spades-fast.cwl

    rename_contigs:
        requirements:
            - class: EnvVarRequirement
              envDef:
                PATH: $(inputs.exec_path)
        run:
            class: CommandLineTool
            baseCommand: move_contigs.sh
            inputs:
                spades_contigs:
                    type: File
                    inputBinding:
                        position: 1
                run_id:
                    type: string
                    inputBinding:
                        position: 2
                exec_path:
                    type: string
            outputs:
                contigs:
                    type: File
                    outputBinding:
                        glob: "*.fasta"
        in:
            spades_contigs:
                source: spades-fast/assembly
            run_id:
                source: spades-fast/run_id
            exec_path: exec_path
        out:
            [contigs]
        scatter: [spades_contigs, run_id]
        scatterMethod: dotproduct


    mlst:
        in:
            contigs:
                source: rename_contigs/contigs
        out:
            [mlstout]
        scatter: contigs
        run: mlst.cwl

    collect_mlst_res:
        requirements:
        - class: EnvVarRequirement
          envDef:
            PATH: $(inputs.exec_path)
        - class: InitialWorkDirRequirement
          listing:
            - entryname: paths.txt
              entry: ${ var res = '';
                        for (var i = 0; i < inputs.mlstout.length; ++i) {
                            res += inputs.mlstout[i].path + '\n';
                            }
                            return res;
                        }
        run:
            class: CommandLineTool
            baseCommand: ['collect_mlst.py']
            arguments: ["paths.txt"]
            inputs:
                mlstout:
                    type: File[]
                exec_path:
                    type: string
                out_fn:
                    type: string
                    inputBinding:
                        position: 2
            outputs:
                mlst_table:
                    type: File
                    outputBinding:
                        glob: "*.tab"
        in:
            mlstout: mlst/mlstout
            exec_path: exec_path
            out_fn: out_fn
        out:
            [mlst_table]
