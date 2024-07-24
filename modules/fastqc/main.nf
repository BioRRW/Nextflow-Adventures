process FASTQC {
/*
    FASTQC Process
    Written by Reed Woyda.
    July 2024
*/
    // Add ID tag to process
    tag { sample }

    //Input is a tuple consisting of a set of FASTQ reads with an associated sample, iteration_flag and iteration_count
    input:
    tuple val(sample), path(reads)

    //Output is a tuple consisting of a path to FastQC output files associated sample, iteration_flag and iteration_count
    output:
    tuple val(sample), path("*_fastqc.{zip,html}")



    script:
    """
    # Run fastqc with the input reads and the default number of threads

    fastqc -q ${reads} -t ${params.threads}
    """
}