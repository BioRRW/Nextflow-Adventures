process SICKLE_ITERATION {

    tag { sample }

    input:
    tuple val(sample), val(iteration), path(reads, stageAs: 'reads/*')

    output:
    tuple val(sample), val(iteration), path("*_trimmed_R*.fastq.gz"), emit: trimmed
    tuple val(sample), val(iteration), path("${sample}.singles.fastq.gz"), emit: singles
    tuple val(sample), val(iteration), path("${sample}.log"), emit: log

    script:
    def (forward, reverse) = reads

    """
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