process METABAT2 {
    errorStrategy 'finish'    

    tag { sample }


    input:
    tuple val(sample), val(iteration_flag), val(iteration_count), path(fasta), path(bam)

    output:
    tuple val(sample), val(iteration_flag), val(iteration_count), path("*metabat-bins/*.fa"), emit: metabat_bins, optional: true
    tuple val(sample), val(iteration_flag), val(iteration_count), path("${sample}_depth.txt"), emit: metabat_bin_depths, optional: true


    script:
    """
    jgi_summarize_bam_contig_depths --referenceFasta ${fasta} --outputDepth ${sample}_depth.txt ${bam}
    metabat2 -i ${fasta} -a ${sample}_depth.txt -o metabat-bins/bin

    if ls metabat-bins/*.fa 1> /dev/null 2>&1; then
        echo "Sample ${sample}: Metabat bins exist."
    else
        echo "Sample ${sample}: No Metabat bins were generated."
    fi
    
    """
}
