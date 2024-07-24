process GET_UNMAPPED {
    tag { sample }

    input:
    tuple val(sample), val(iteration_flag), val(iteration_count), path(reads)
    path(mag_db_unused)
    path(mag_db)


    output:
    //tuple val(sample), val(iteration_flag), val(iteration_count), path("*unmapped_repaired_R*.fastq"), emit: unmapped
    tuple val(sample), val(iteration_flag), val(iteration_count), path("*unmapped_R*.fastq"), emit: unmapped
    val(iteration_count), emit: iter_count

    script:
    def (forward, reverse) = reads

    """ 

    cp ${forward} ${sample}_unmapped_R1.fastq
    cp ${reverse} ${sample}_unmapped_R2.fastq
   
    """

}

/*

    bowtie2-build \\
    ${mag_db} \\
    MAG_DB \\
    --threads ${params.threads}

    bowtie2 \\
    -D ${params.bowtie_D} \\
    -R ${params.bowtie_R} \\
    -N ${params.bowtie_N} \\
    -L ${params.bowtie_L} \\
    -i ${params.bowtie_i} \\
    -p ${params.threads} \\
    -x MAG_DB \\
    -S "${sample}_MAGdb.sam" \\
    -1 "${forward}" \\
    -2 "${reverse}"

    samtools \\
    view \\
    -@ ${params.threads} \\
    -bS \\
    -o ${sample}_MAGdb.bam \\
    ${sample}_MAGdb.sam

    /opt/bbmap/reformat.sh \\
    t=${params.threads} \\
    -Xmx${params.filter_mem}g \\
    in=${sample}_MAGdb.bam \\
    out=${sample}_unmapped.bam \\
    mappedonly=t
    pairedonly=t

    samtools \\
    sort \\
    -@ ${params.threads} \\
    -o ${sample}_unmapped_POSSORT.bam \\
    ${sample}_unmapped.bam

    # need to convert the unmapped reads back to fastq files
    samtools \\
    fastq \\
    -1 ${sample}_unmapped_R1.fastq \\
    -2 ${sample}_unmapped_R2.fastq \\
    -t \\
    ${sample}_unmapped_POSSORT.bam

 
    /opt/bbmap/reformat.sh \\
    t=${params.threads} \\
    -Xmx${params.filter_mem}g \\
    in=${sample}_MAGdb.bam \\
    out=${sample}_unmapped.bam \\
    unmappedonly
    
    
    /opt/bbmap/repair.sh -Xmx${params.filter_mem}g repair=t in=${sample}_unmapped_R1.fastq in2=${sample}_unmapped_R2.fastq out=${sample}_unmapped_repaired_R1.fastq out2=${sample}_unmapped_repaired_R2.fastq outs=temp.fastq

*/