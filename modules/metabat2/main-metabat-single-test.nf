process METABAT2 {
    
    tag { sample }


    input:
    // Below is commented out because we are testing with hardcoded
    // files which I did not make into tuples.
    //tuple val(sample), path(fasta)
    //tuple val(sample), path(bam)
    path(fasta)
    path(bam)
    path run_metabat

    output:
    //val tuple path("*metabat-bins/*.fa"), emit: metabat_bins
    //val tuple path("*depth.txt"), emit metabat_bin_depths

    //WCRC_304_final.contigs_2500.fa.metabat-bins-20230712_133821
    path("*metabat-bins/*.fa"), emit: metabat_bins
    path("*depth.txt"), emit: metabat_bin_depths

    script:
    """
    ${run_metabat} \\
    ${fasta} \\
    ${bam}
    
    
    mv *metabat-bins*/ WCRC_304_metabat-bins/

    """
    //will need to rename the metabat-bins with the ${sample} once I am not useing the sample
    //WCRC_304 data
}