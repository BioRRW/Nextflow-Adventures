process BBMAP {

    tag { sample }

    input:
    tuple val(sample), val(iteration_flag), val(iteration_count), path ( reads )
    path(database)

    output:
    path("logs/${sample}_mapping.log"), emit: metabat_log
    path("sorted_bam/${sample}_mapped.sorted.bam.gz"), emit: sorted_bam, optional: true

    script:
    def (forward, reverse) = reads

    """ 
    # Create output directory for bam and log files
    touch ${sample}_mapping.log

    # Output sample name and contig name to log file
    echo "Filename: ${sample}" >> "${sample}_mapping.log"
    echo "\n" >> "${sample}_mapping.log"
    echo "Mapping to: ${database}" >> "${sample}_mapping.log"
    echo "\n" >> "${sample}_mapping.log"

    # Output Read names to log
    echo "Forward: ${forward}" >> "${sample}_mapping.log"
    echo "Reverse: ${reverse}" >> "${sample}_mapping.log"

    # Count forward and reverse reads
    forward_read_count=\$(zcat ${forward} | grep -c "^@")
    reverse_read_count=\$(zcat ${reverse} | grep -c "^@")

    # Output count from reads to log file
    echo "Forward Read count: \${forward_read_count}" >> "${sample}_mapping.log"
    echo "Reverse Read count: \${reverse_read_count}" >> "${sample}_mapping.log"
    echo "\n" >> "${sample}_mapping.log"

    if [[ "${params.profile}" == *"singularity"* ]]; then
        /opt/bbmap/bbmap.sh \\
        -Xmx${params.map_mem}G \\
        threads=${params.threads} \\
        overwrite=t \\
        ref=${database} \\
        in1=${forward} \\
        in2=${reverse} \\
        out=${sample}.mapped.sam
    else
        bbmap.sh \\
        -Xmx${params.map_mem}G \\
        threads=${params.threads} \\
        overwrite=t \\
        ref=${database} \\
        in1=${forward} \\
        in2=${reverse} \\
        out=${sample}.mapped.sam
    fi

    if [[ "${params.profile}" == *"singularity"* ]]; then
        source /opt/miniconda/bin/activate support
    fi

    samtools \\
    view \\
    -@ ${params.threads} \\
    -bS \\
    ${sample}.mapped.sam > ${sample}.mapped.bam

    rm ${sample}.mapped.sam

    samtools \\
    sort \\
    -@ ${params.threads} \\
    -o ${sample}_mapped.sorted.bam \\
    ${sample}.mapped.bam

    # Output count of  total mapped reads to log file:
    echo "Total mapped reads: \$(samtools view -c ${sample}.mapped.bam)" >> "${sample}_mapping.log"

    rm ${sample}.mapped.bam

    if [[ "${params.profile}" == *"singularity"* ]]; then
        /opt/bbmap/reformat.sh \\
        -Xmx${params.filter_mem}g \\
        minidfilter=${params.map_min_id_filter} \\
        in=${sample}_mapped.sorted.bam \\
        out=${sample}_mapped.${params.map_min_id_filter}.sorted.bam \\
        pairedonly=${params.filter_paired} \\
        primaryonly=${params.filter_primary}
    else
        reformat.sh \\
        -Xmx${params.filter_mem}g \\
        minidfilter=${params.map_min_id_filter} \\
        in=${sample}_mapped.sorted.bam \\
        out=${sample}_mapped.${params.map_min_id_filter}.sorted.bam \\
        pairedonly=${params.filter_paired} \\
        primaryonly=${params.filter_primary}
    fi

    # Output total mapped reads to log file:
    echo "Reads after filtering at ${params.map_min_id_filter}: \$(samtools view -c ${sample}_mapped.${params.map_min_id_filter}.sorted.bam)" >> "${sample}_mapping.log"

    #source /opt/miniconda/bin/deactivate support
    if [[ "${params.profile}" == *"singularity"* ]]; then
        conda deactivate
    fi

    # Based on user input either remove sorted bam or keep them in output
    if [[ ${params.keep_bam} == "0" ]]; then
        rm ${sample}_mapped.sorted.bam
    else
        pigz -p ${params.threads} ${sample}_mapped.sorted.bam
        mkdir sorted_bam
        mv *sorted.bam.gz sorted_bam/
    fi

    rm ${sample}_mapped.${params.map_min_id_filter}.sorted.bam

    mkdir logs
    mv ${sample}_mapping.log logs/

    
    """  
}  
