process READ_MAPPING {
    /*
        READ_MAPPING Process
        Written by Reed Woyda under the Wrighton Lab at Colorado State University.
        November 2023
    */

    // Add an ID tag to the process
    tag { sample }

    // Define the input for the READ_MAPPING process
    input:
        // Input is a tuple with sample information, iteration flag, and count, along with paths to reads and a MAG database
        tuple val(sample), val(iteration_flag), val(iteration_count), path(reads), file(input_db)

    // Define the output for the READ_MAPPING process, including log files and optional sorted BAM files
    output:
        // Output consists of paths to log files and optional sorted BAM files associated with the sample and filtering parameters
        path("${sample}_mapping.log"), emit: metabat_log
        path("sorted_bam/${sample}_${params.map_min_id_filter}_sorted.bam.gz"), emit: sorted_bam, optional: true

    script:
    def (forward, reverse) = reads

    """ 
    if [[ "${params.profile}" == *"singularity"* ]]; then
        source /opt/miniconda/bin/activate support
    fi

    # Build a bowtie2 database
    bowtie2-build \\
    ${input_db} \\               # Path to the input MAG database
    MAG_DB \\                    # Name of the output database
    --threads ${params.threads}  # Number of threads for parallel processing


    # Output sample name and contig name to log file
    echo "Filename: ${sample}" >> "${sample}_mapping.log"
    echo "Mapping to built bowtie2 database using: ${input_db}" >> "${sample}_mapping.log"
    echo "\n" >> "${sample}_mapping.log"

    # output Read names
    echo "Forward: ${forward}" >> "${sample}_mapping.log"
    echo "Reverse: ${reverse}" >> "${sample}_mapping.log"

    # Count forward and reverse reads going in
    forward_read_count=\$(zcat ${forward} | grep -c "^@")
    reverse_read_count=\$(zcat ${reverse} | grep -c "^@")

    # Output count from reads to log file
    echo "Initial forward Read count: \${forward_read_count}" >> "${sample}_mapping.log"
    echo "Initial reverse Read count: \${reverse_read_count}" >> "${sample}_mapping.log"
    echo "\n" >> "${sample}_mapping.log"

    # Map reads using bowtie2
    bowtie2 \\
    -D ${params.bowtie_D} \\     # Report shorter alignments
    -R ${params.bowtie_R} \\     # Change the repetitive seeds
    -N ${params.bowtie_N} \\     # Mismatches in seed alignment
    -L ${params.bowtie_L} \\     # Length of seed substrings
    -i ${params.bowtie_i} \\     # Seed extension options
    -p ${params.threads} \\      # Number of threads for parallel processing
    -x MAG_DB \\                # Name of the MAG database
    -S "${sample}.sam" \\       # Output SAM file
    -1 "${forward}" \\           # Input forward read file
    -2 "${reverse}"             # Input reverse read file

    # Convert SAM to BAM format
    samtools \\
    view \\
    -@ ${params.threads} \\      # Number of threads for parallel processing
    -bS \\
    -o ${sample}.bam \\          # Output BAM file
    ${sample}.sam

    rm ${sample}.sam

    # Filter reads
    if [[ "${params.profile}" == *"singularity"* ]]; then
        /opt/bbmap/reformat.sh \\
        -Xmx${params.filter_mem}g \\  # Maximum memory for Java virtual machine
        minidfilter=${params.map_min_id_filter} \\  # Minimum identity filter
        in=${sample}.bam \\           # Input BAM file
        out=${sample}_${params.map_min_id_filter}.bam \\  # Output filtered BAM file
        pairedonly=${params.filter_paired} \\  # Keep only paired reads
        primaryonly=${params.filter_primary}   # Keep only primary alignments
    else
        reformat.sh \\
        -Xmx${params.filter_mem}g \\  # Maximum memory for Java virtual machine
        minidfilter=${params.map_min_id_filter} \\  # Minimum identity filter
        in=${sample}.bam \\           # Input BAM file
        out=${sample}_${params.map_min_id_filter}.bam \\  # Output filtered BAM file
        pairedonly=${params.filter_paired} \\  # Keep only paired reads
        primaryonly=${params.filter_primary}   # Keep only primary alignments
    fi
    
    # Count forward and reverse reads from the BAM file
    forward_read_count=\$(samtools view -@ ${params.threads} -F 4 -f 0x10 -c ${sample}.bam)
    reverse_read_count=\$(samtools view -@ ${params.threads} -F 4 -f 16 -c ${sample}.bam)

    # Output count from reads to log file
    echo "Number of mapped reads BEFORE filtering:" >> "${sample}_mapping.log"
    echo "Mapped forward Read count: \${forward_read_count}" >> "${sample}_mapping.log"
    echo "Mapped reverse Read count: \${reverse_read_count}" >> "${sample}_mapping.log"

    rm ${sample}.bam

    # Count forward and reverse reads from the BAM file
    forward_read_count=\$(samtools view -@ ${params.threads} -F 4 -f 0x10 -c ${sample}_${params.map_min_id_filter}.bam)
    reverse_read_count=\$(samtools view -@ ${params.threads} -F 4 -f 16 -c ${sample}_${params.map_min_id_filter}.bam)

    # Output filtered read counts from reads to log file
    echo "Number of mapped reads AFTER filtering at ${params.map_min_id_filter}:" >> "${sample}_mapping.log"
    echo "Mapped forward Read count: \${forward_read_count}" >> "${sample}_mapping.log"
    echo "Mapped reverse Read count: \${reverse_read_count}" >> "${sample}_mapping.log"

    # Based on user input either remove sorted bam or keep it in output
    if [[ ${params.keep_bam} == "0"  ]]; then
        rm ${sample}_${params.map_min_id_filter}.bam
    else
        samtools \\
        sort \\
        -@ ${params.threads} \\
        -o ${sample}_${params.map_min_id_filter}_sorted.bam \\
        ${sample}_${params.map_min_id_filter}.bam

        pigz -p ${params.threads} ${sample}_${params.map_min_id_filter}_sorted.bam
        mkdir sorted_bam

        mv ${sample}_${params.map_min_id_filter}_sorted.bam.gz sorted_bam/

    fi

    if [[ "${params.profile}" == *"singularity"* ]]; then
        source /opt/miniconda/bin/deactivate
    fi

    """

}

