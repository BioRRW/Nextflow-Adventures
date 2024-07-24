process MEGAHIT {
    /*
        MEGAHIT Process
        Written by Reed Woyda under the Wrighton Lab at Colorado State University.
        November 2023
    */
    errorStrategy 'finish'

    // Add an ID tag to the process
    tag { sample }

    // Define the input for MEGAHIT process, including raw read data and multiQC output
    input:
        tuple val(sample), val(iteration_flag), val(iteration_count), path(reads, stageAs: 'reads/*')
        val(multiqc_output)
        path(pull_seq_script)
    
    // Define the output for MEGAHIT process, which includes trimmed contigs and assembly log files
    output:
    // CAN USE THIS LINE BELOW FOR TESTING - making things run faster
    //tuple val(sample), val(iteration_flag), val(iteration_count), path("all_contigs/${sample}.contigs.fa"), emit: trimmed_contigs, optional: true
    tuple val(sample), val(iteration_flag), val(iteration_count), path("all_contigs/${sample}.contigs.fa"), emit: contigs, optional: true
    tuple val(sample), val(iteration_flag), val(iteration_count), path("${params.min_contig_len}_contigs/${sample}.contigs.${params.min_contig_len}.fa"), emit: trimmed_contigs, optional: true
    tuple val(sample), val(iteration_flag), val(iteration_count), path("logs/${sample}.log"), emit: assembly_log, optional: true

    // Execute this process only when multiQC output is available
    // This allows the pipeline to finish all QC before starting assemblies. While this is inefficient for the pipeline, it is efficient for reducing overconsumption of resources on an HPC
    when:
        multiqc_output != null

    // Bash script for MEGAHIT process
    script:
    def (forward, reverse) = reads

    """
    # Run MEGAHIT for metagenome assembly
    # Input paired-end read file 1
    # Input paired-end read file 2
    # Prefix for output files
    # Directory for MEGAHIT output
    # Minimum k-mer size for assembly
    # Maximum k-mer size for assembly
    # K-mer size step
    # Memory allocation strategy
    # Maximum memory usage
    # Number of CPU threads for parallel processing

    megahit \\
    -1 "${forward}" \\
    -2 "${reverse}" \\
    --out-prefix "${sample}" \\
    --out-dir "${sample}_megahit" \\
    --k-min ${params.k_min} \\
    --k-max ${params.k_max} \\
    --k-step ${params.k_step} \\
    --mem-flag ${params.mem_flag} \\
    -m ${params.megahit_mem} \\
    -t ${params.threads}

    # Create a directory for contigs with a minimum length
    mkdir ${params.min_contig_len}_contigs

    if [ -s "${sample}_megahit/${sample}.contigs.fa" ]; then 
        # Use pullseq to filter contigs by minimum length
        python ${pull_seq_script} \\
        -i "${sample}_megahit/${sample}.contigs.fa" \\
        -m ${params.min_contig_len} \\
        -o "${params.min_contig_len}_contigs/${sample}.contigs.${params.min_contig_len}.fa"

        # Create directories for all contigs and logs
        mkdir all_contigs
        mkdir logs

        # Move the main contigs and log files to the appropriate directories
        mv ${sample}_megahit/${sample}.contigs.fa all_contigs/${sample}.contigs.fa
        mv ${sample}_megahit/${sample}.log logs/${sample}.log

        # Remove the temporary MEGAHIT directory
        rm -rf ${sample}_megahit
    
    else
        # Handle the case where MEGAHIT did not produce any contigs
        echo "Sample ${sample} - Error: MEGAHIT did not produce any contigs."
        rm -rf ${sample}_megahit/
    fi
    """  
}
