process GET_UNMAPPED {
    /*
        GET_UNMAPPED Process
        Written by Reed Woyda under the Wrighton Lab at Colorado State University.
        November 2023
    */

    // Add an ID tag to the process
    tag { sample }

    // Define the input for the GET_UNMAPPED process
    input:
        // Input consists of a tuple with sample information, iteration flag, and count, along with paths to reads and a MAG database
        tuple val(sample), val(iteration_flag), val(iteration_count), path(reads), path(mag_db)

    // Define the output for the GET_UNMAPPED process, including unmapped read files, logs, and optional BAM files
    output:
        // Output consists of paths to unmapped read files, logs, and optional BAM files associated with the sample, iteration flag, and count
        tuple val(sample), val(iteration_flag), val(iteration_count), path("*unmapped_repaired_R*.fastq.gz"), emit: unmapped
        tuple val(sample), val(iteration_flag), val(iteration_count), path("${sample}_iteration.log"), emit: unmapped_log
        tuple val(sample), val(iteration_flag), val(iteration_count), path("unmapped_bam/${sample}_unmapped_POSSORT.bam.gz"), emit: unmapped_bam, optional: true

    script:
    def (forward, reverse) = reads

    """ 

    # Output sample name and contig name to log file
    echo "Filename: ${sample}" >> "${sample}_iteration.log"
    echo "Bulding bowtie2 database on ${mag_db}" >> "${sample}_iteration.log"
    echo "\n" >> "${sample}_iteration.log"

    # output Read names
    echo "Forward: ${forward}" >> "${sample}_iteration.log"
    echo "Reverse: ${reverse}" >> "${sample}_iteration.log"

    # Count forward and reverse reads going in
    forward_read_count=\$(zcat ${forward} | grep -c "^@")
    reverse_read_count=\$(zcat ${reverse} | grep -c "^@")

    # Output count from reads to log file
    echo "Initial forward Read count: \${forward_read_count}" >> "${sample}_iteration.log"
    echo "Initial reverse Read count: \${reverse_read_count}" >> "${sample}_iteration.log"
    echo "\n" >> "${sample}_iteration.log"

    if [[ "${params.profile}" == *"singularity"* ]]; then
        source /opt/miniconda/bin/activate support
    fi

    # Build a bowtie2 database for the MAG database
    # Path to the input MAG database
    # Output database name
    # Output database name
    # Number of threads for parallel processing

    bowtie2-build \\
    ${mag_db} \\
    MAG_DB \\
    --threads ${params.threads}

    # Map reads to the MAG database using bowtie2
    # Report shorter alignments
    # Change the repetitive seeds
    # Mismatches in seed alignment
    # Length of seed substrings
    # Seed extension options
    # Number of threads for parallel processing
    # Name of the MAG database
    # Output SAM file
    # Input forward read file
    # Input reverse read file

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

    # Convert SAM to BAM format and filter for unmapped reads
    # Number of threads for parallel processing
    # Output BAM file

    samtools \\
    view \\
    -@ ${params.threads} \\
    -bS \\
    -o ${sample}_MAGdb.bam \\
    ${sample}_MAGdb.sam

    rm ${sample}_MAGdb.sam
    
    # Filter and sort BAM to extract unmapped reads
    if [[ "${params.profile}" == *"singularity"* ]]; then
        /opt/bbmap/reformat.sh \\
        t=${params.threads} \\
        -Xmx${params.filter_mem}g \\
        in=${sample}_MAGdb.bam \\
        out=${sample}_unmapped.bam \\
        unmappedonly
    else
        reformat.sh \\
        t=${params.threads} \\
        -Xmx${params.filter_mem}g \\
        in=${sample}_MAGdb.bam \\
        out=${sample}_unmapped.bam \\
        unmappedonly
    fi

    rm ${sample}_MAGdb.bam

    samtools \\
    sort \\
    -@ ${params.threads} \\
    -o ${sample}_unmapped_POSSORT.bam \\
    ${sample}_unmapped.bam

    rm ${sample}_unmapped.bam

    # Convert unmapped reads back to FASTQ format
    # Output unmapped forward reads
    # Output unmapped reverse reads
    # Input sorted BAM file containing unmapped reads
    samtools \\
    fastq \\
    -1 ${sample}_unmapped_R1.fastq \\
    -2 ${sample}_unmapped_R2.fastq \\
    -t \\
    ${sample}_unmapped_POSSORT.bam


    # Based on user input either remove sorted bam or keep it in output
    if [[ ${params.keep_bam} == "0"  ]]; then
        rm ${sample}_unmapped_POSSORT.bam
    else
        pigz -p ${params.threads} ${sample}_unmapped_POSSORT.bam
        mkdir unampped_bam
        mv ${sample}_unmapped_POSSORT.bam.gz unmapped_bam/
    fi

    if [[ "${params.profile}" == *"singularity"* ]]; then
        /opt/bbmap/repair.sh -Xmx${params.filter_mem}g repair=t in=${sample}_unmapped_R1.fastq in2=${sample}_unmapped_R2.fastq out=${sample}_unmapped_repaired_R1.fastq out2=${sample}_unmapped_repaired_R2.fastq outs=temp.fastq
    else
        repair.sh -Xmx${params.filter_mem}g repair=t in=${sample}_unmapped_R1.fastq in2=${sample}_unmapped_R2.fastq out=${sample}_unmapped_repaired_R1.fastq out2=${sample}_unmapped_repaired_R2.fastq outs=temp.fastq
    fi

    rm temp.fastq
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

    rm *.bt2
    
    if [[ "${params.profile}" == *"singularity"* ]]; then
        source /opt/miniconda/bin/deactivate
    fi

    """

}

