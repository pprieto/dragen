#!/usr/bin/env nextflow
/*
========================================================================================
                         lifebit-ai/dragen
========================================================================================
 lifebit-ai/dragen Illumina's Dragen pipeline including indexing, mapping & variant calling
 #### Homepage / Documentation
 https://github.com/lifebit-ai/dragen
----------------------------------------------------------------------------------------
*/

// params.fasta = params.genome ? params.genomes[ params.genome ].fasta ?: false : false
if (params.fasta) {
    Channel.fromPath(params.fasta)
           .ifEmpty { exit 1, "FASTA annotation file not found: ${params.fasta}" }
           .into { fasta_index; fasta_dragen }
}

reads="${params.reads}/${params.reads_prefix}_{1,2}.${params.reads_extension}"
Channel
    .fromFilePairs(reads, size: 2)
    .ifEmpty { exit 1, "Cannot find any reads matching: ${reads}" }
    .set { reads_dragen}

dragen = reads_dragen.combine(fasta_dragen)

/*--------------------------------------------------
  Run Dragen mapping & variant calling
---------------------------------------------------*/

process dragen {
  tag "${name}"
  publishDir "${params.outdir}", mode: 'copy'

  input:
  set val(name), file(fastq), file(fasta) from dragen

  output:
  set val(name), file("${name}.vcf"), file(".command.log") into results

  script:
  """
  dragen \
  -r $fasta \
  --output-directory . \
  --output-file-prefix $name \
  -1 ${fastq[0]} \
  -2 ${fastq[1]}\
  --enable-variant-caller true \
  --vc-sample-name $name
  """
}