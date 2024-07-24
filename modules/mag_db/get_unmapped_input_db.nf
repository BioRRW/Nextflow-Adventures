process GET_UNMAPPED_INPUT_DB {

    input:
    tuple val(sample), val(iteration_flag), val(iteration_count), path(reads)
    path( build_mag_db )
    
    output:
    tuple val(sample), val(iteration_flag), val(iteration_count), path("*unmapped_repaired_R*.fastq.gz"), emit: unmapped
    tuple val(sample), val(iteration_flag), val(iteration_count), path("${sample}_iteration.log"), emit: unmapped_log
    tuple val(sample), val(iteration_flag), val(iteration_count), path("unmapped_bam/${sample}_unmapped_POSSORT.bam.gz"), emit: unmapped_bam, optional: true



    script:
    def (forward, reverse) = reads
    """

    # Output sample name and contig name to log file
    echo "Filename: ${sample}" >> "${sample}_iteration.log"
    echo "Mapping against user-provided database ${params.input_mag_db}." >> "${sample}_iteration.log"
    echo "\n" >> "${sample}_iteration.log"

    if [[ "${params.profile}" == *"singularity"* ]]; then
        source /opt/miniconda/bin/activate support
    fi

    bowtie2 \\
    -D ${params.bowtie_D} \\
    -R ${params.bowtie_R} \\
    -N ${params.bowtie_N} \\
    -L ${params.bowtie_L} \\
    -i ${params.bowtie_i} \\
    -p ${params.threads} \\
    -x ${build_mag_db} \\
    -S "${sample}_MAGdb.sam" \\
    -1 "${forward}" \\
    -2 "${reverse}"

    samtools \\
    view \\
    -@ ${params.threads} \\
    -bS \\
    -o ${sample}_MAGdb.bam \\
    ${sample}_MAGdb.sam

    rm ${sample}_MAGdb.sam

    /opt/bbmap/reformat.sh \\
    t=${params.threads} \\
    -Xmx${params.filter_mem}g \\
    in=${sample}_MAGdb.bam \\
    out=${sample}_unmapped.bam \\
    unmappedonly

    rm ${sample}_MAGdb.bam

    samtools \\
    sort \\
    -@ ${params.threads} \\
    -o ${sample}_unmapped_POSSORT.bam \\
    ${sample}_unmapped.bam

    
    rm ${sample}_unmapped.bam

    # need to convert the unmapped reads back to fastq files
    samtools \\
    fastq \\
    -1 ${sample}_unmapped_R1.fastq \\
    -2 ${sample}_unmapped_R2.fastq \\
    -t \\
    ${sample}_unmapped_POSSORT.bam


    # Based on user input either remove sorted bam or keep it in output
    if [[ ${params.keep_bam} ]]; then
        pigz -p ${params.threads} ${sample}_unmapped_POSSORT.bam
        mkdir unampped_bam
        mv ${sample}_unmapped_POSSORT.bam.gz unmapped_bam/
    else
        rm ${sample}_unmapped_POSSORT.bam
    fi

    if [[ "${params.profile}" == *"singularity"* ]]; then
        /opt/bbmap/repair.sh -Xmx${params.filter_mem}g repair=t in=${sample}_unmapped_R1.fastq in2=${sample}_unmapped_R2.fastq out=${sample}_unmapped_repaired_R1.fastq out2=${sample}_unmapped_repaired_R2.fastq outs=temp.fastq
    else
        repair.sh -Xmx${params.filter_mem}g repair=t in=${sample}_unmapped_R1.fastq in2=${sample}_unmapped_R2.fastq out=${sample}_unmapped_repaired_R1.fastq out2=${sample}_unmapped_repaired_R2.fastq outs=temp.fastq
    fi


    rm ${sample}_unmapped_R1.fastq
    rm ${sample}_unmapped_R2.fastq

    # Gzip the unmapped fastq files using pigz
    pigz -p ${params.threads} ${sample}_unmapped_repaired_R1.fastq
    pigz -p ${params.threads} ${sample}_unmapped_repaired_R2.fastq

    # output Read names
    echo "Unmapped forward: ${forward}" >> "${sample}_iteration.log"
    echo "Unmapped Reverse: ${reverse}" >> "${sample}_iteration.log"

    # Count forward and reverse reads which did not map
    forward_read_count=\$(zcat ${sample}_unmapped_repaired_R1.fastq | grep -c "^@")
    reverse_read_count=\$(zcat ${sample}_unmapped_repaired_R2.fastq | grep -c "^@")

    # Output count from reads to log file
    echo "Unmapped forward Read count: \${forward_read_count}" >> "${sample}_iteration.log"
    echo "Unmapped reverse Read count: \${reverse_read_count}" >> "${sample}_iteration.log"

    # Remove the unGZIPPED fastq files
    rm *.fastq


    rm *.bt2
    if [[ "${params.profile}" == *"singularity"* ]]; then
        source /opt/miniconda/bin/deactivate
    fi

    """

}