process SICKLE_PE {
    /*
        SICKLE_PE Process
        Written by Reed Woyda under the Wrighton Lab at Colorado State University.
        November 2023
    */
    // Add an ID tag to the process
    tag { sample }

    // Define the input for SICKLE_PE process
    input:
        tuple val(sample), val(iteration_flag), val(iteration_count), path(reads, stageAs: 'reads/*')

    // Define the output for SICKLE_PE process, including trimmed read pairs, singles, and a log file
    output:
        tuple val(sample), val(iteration_flag), val(iteration_count), path("*_trimmed_R*.fastq.gz"), emit: trimmed
        //tuple val(sample), path("${sample}.singles.fastq.gz"), emit: singles
        tuple val(sample), val(iteration_flag), val(iteration_count), path("${sample}.log"), emit: log

    // Bash script for SICKLE_PE process
    script:
    def (forward, reverse) = reads

    """
    # Trim paired-end reads using Sickle
    # -t Quality type (e.g., phred33, phred64)
    # -g Use gzip compression
    # -l Minimum length for trimmed reads
    # -q Minimum quality score for trimming
    # -f Input forward read file
    # -r Input reverse read file
    # -o Output trimmed forward reads
    # -p Output trimmed reverse reads
    # -s Output unpaired (singles) reads
    # 1> "${sample}.log"  # Redirect standard output to a log file
    sickle pe \\
        -t ${params.qual_type} \\ 
        -g \\  
        -l ${params.trim_length} \\  
        -q ${params.trim_quality} \\  
        -f "${forward}" \\  
        -r "${reverse}" \\  
        -o "${sample}_trimmed_R1.fastq.gz" \\  
        -p "${sample}_trimmed_R2.fastq.gz" \\  
        -s "${sample}.singles.fastq.gz" \\  
        1> "${sample}.log"
    """
}
