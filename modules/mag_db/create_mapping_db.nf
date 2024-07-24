process CREATE_MAPPING_DB {

    input:
    path(input_db)

    output:
    path("*bt2"), emit: db_files


    script:
    """
    if [[ "${params.profile}" == *"singularity"* ]]; then
        source /opt/miniconda/bin/activate support
    fi
    
    bowtie2-build \\
    ${input_db} \\
    MAG_DB \\
    --threads ${params.threads}

    if [[ "${params.profile}" == *"singularity"* ]]; then
        source /opt/miniconda/bin/deactivate
    fi

    """

}