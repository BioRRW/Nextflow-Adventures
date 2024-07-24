process CHECKM {

    tag { sample }

    input:
    tuple val(sample), val(iteration_flag), val(iteration_count), path(bins), path(depth)

    output:
    tuple val(sample), val(iteration_flag), val(iteration_count), path("checkm/*results.txt"), emit: checkm_results

    script:

    """ 
    mkdir bins
    mv ${bins} bins/

    checkm \\
    lineage_wf \\
    -t ${params.threads} \\
    -x fa \\
    --reduced_tree \\
    bins/ \\
    checkm

    cd checkm

    checkm \\
    qa \\
    -o 2 \\
    -f results.txt \\
    --tab_table \\
    -t ${params.threads} \\
    lineage.ms \\
    .

    mv results.txt ${sample}_results.txt

    """
}    

