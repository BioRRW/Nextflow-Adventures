process GET_ITERATION_COUNT {
    tag { sample }

    input:
    tuple val(sample), val(iteration_flag), val(iteration_count), path(reads)


    output:
    val(iteration_count), emit: iter_count

    script:
    """
    """

}