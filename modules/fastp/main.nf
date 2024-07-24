process FASTP {
/*
    FASTP Process
    Written by Reed Woyda.
    July 2024
*/
    // Add an ID tag to the process
    tag { sample }

    // Define the input for FASTP process
    input:
        tuple val(sample), path(reads, stageAs: 'reads/*')

    // Define the output for FASTP process, including trimmed read pairs and a log file
    output:
        tuple val(sample), path("*_trimmed_R*.fastq.gz"), emit: trimmed_reads
        tuple val(sample), path("${sample}.log"), emit: log

    // Bash script for FASTP process
    script:
    def (forward, reverse) = reads

    """
    # Trim paired-end reads using FASTP
    # -i Input forward read file
    # -I Input reverse read file
    # -q Minimum quality score for trimming
    # --detect_adapter_for_pe Detect adapters in paired-end reads
    # --thread Number of threads for parallel processing
    # -o Output trimmed forward reads
    # -O Output trimmed reverse reads
    # 1> "${sample}.log"  # Redirect standard output to a log file

    fastp \\
        -i "${forward}" \\
        -I "${reverse}" \\
        -q ${params.trim_quality} \\
        --detect_adapter_for_pe \\
        --thread ${params.threads} \\
        -o "${sample}_trimmed_R1.fastq.gz" \\
        -O "${sample}_trimmed_R2.fastq.gz" \\
        1> "${sample}.log"
    """
}
