process MAP_MAG_DB {
    tag { sample }

    input:
    tuple val(sample), path(reads, stageAs: 'reads/*')
    path(mag_db)
    path(reformat)

    output:
    //tuple val(sample), path("<unmapped reads fastq gz>"), emit: unmapped_reads
    tuple val (sample), path("${sample}_${params.MAG_min_id_filter}_MAGS_POSSORT.bam")

    script:
    def (forward, reverse) = reads

    // Not sure if I want to keep the database building here or move it to MAT_DB()
    // If it is here, it gets re-made for every sample... might be a waste of resources
    // Keeping here for now but may move
    // may need to add the --large-index flag here for large databases

    // The parameters for bowtie still need to be made into modifyable parameters
    //  Same goes for the BAM and SAM generation

    """ 

    bowtie2-build \\
    ${mag_db} \\
    MAG_DB \\
    --threads ${params.threads}

    bowtie2 \\
    -D 10 -R 2 -N 0 -L 22 -i S,0,2.50 \\
    -p ${params.threads} \\
    -x MAG_DB \\
    -S "${sample}_MAGdb.sam" \\
    -1 "${forward}" \\
    -2 "${reverse}"

    samtools \\
    view \\
    -@ ${params.threads} \\
    -bS \\
    ${sample}_MAGdb.sam > ${sample}_MAGdb.bam
    
    ${reformat} \\
    -Xmx${params.filter_mem}g \\
    in=${sample}_MAGdb.bam \\
    out=${sample}_${params.MAG_min_id_filter} \\
    minidfilter=${params.MAG_min_id_filter} \\
    pairedonly=${params.MAG_filter_paired} \\
    primaryonly=${params.MAG_filter_primary}

    # need to collect the reads which didn't map
    # For now I will jsut collect all unmappd in general however,
    #   this does not take into account the reads which were tossed out 
    #   from the filtering and paird/primary done with reformat.sh above

    ${reformat} \\
    -t=${params.threads}
    -Xmx${params.filter_mem}g \\
    in=WCRC_304_mapped_99perMAGs.bam \\
    out=${sample}_unmapped.bam \\
    unmappedonly

    samtools \\
    sort \\
    -@ ${params.threads} \\
    -o ${sample}_unmapped_POSSORT.bam \\
    ${sample}_unmapped.bam

    samtools \\
    sort \\
    -@ ${params.threads} \\
    -o ${sample}_${params.MAG_min_id_filter}_MAGS_POSSORT.bam \\
    ${sample}_${params.MAG_min_id_filter}

    # need to convert the unmapped reads back to fastq files
    ${reformat} \\
    -t=${params.threads} \\
    -Xmx${params.filter_mem}g \\
    in=${sample}_unmapped_POSSORT.bam \\
    out1=${sample}_unmapped_R1.fastq \\
    out2=${sample}_unmapped_R1.fastq \\
    gzip=true


    """

}