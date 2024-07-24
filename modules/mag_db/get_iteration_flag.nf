process GET_ITERATION_FLAG {
    tag { sample }

    input:
    tuple val(sample), val(iteration_flag), val(iteration_count), path(reads)


    output:
    val(iteration_flag), emit: iter_flag

    script:
    """
    """

}