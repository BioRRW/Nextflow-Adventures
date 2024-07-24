process METABAT2 {
    tag { sample }


    input:
    tuple val(sample), path(fasta)
    tuple val(sample), path(bam)
    path run_metabat

    output:
    tuple val(sample), path("*metabat-bins/*.fa"), emit: metabat_bins
    tuple val(sample), path("*depth.txt"), emit: metabat_bin_depths


    script:
    """
    jgi_summarize_bam_contig_depths \\
    --outputDepth depth.txt \\
    --minContigLength 1500 \\
    ${bam}
    
    metabat2 \\
    -i ${fasta} \\
    --minContig 250 \\
    -o metabat-bins/${sample}
    


    """
}