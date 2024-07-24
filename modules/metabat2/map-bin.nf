process MAP_BIN {
    /*
        MAP_BIN Process
        Written by Reed Woyda under the Wrighton Lab at Colorado State University.
        November 2023
    */

    errorStrategy 'finish'  // Finish the process even if errors occur

    // Add an ID tag to the process
    tag { sample }

    // Define the input for the MAP_BIN process
    input:
        // Input is a tuple consisting of a sample, iteration_flag, iteration_count, read files, and contigs
        tuple val(sample), val(iteration_flag), val(iteration_count), path(reads), path(contigs)

    // Define the output for MAP_BIN process, including Metabat bins, bin depth logs, binning logs, and sorted BAM files
    output:
        tuple val(sample), val(iteration_flag), val(iteration_count), path("all_metabat_bins/*.fa"), emit: metabat_bins, optional: true
        tuple val(sample), val(iteration_flag), val(iteration_count), path("logs/${sample}_depth.txt"), emit: metabat_bin_depths, optional: true
        tuple val(sample), val(iteration_flag), val(iteration_count), path("logs/${sample}_binning.log"), emit: metabat_log, optional: true
        tuple val(sample), val(iteration_flag), val(iteration_count), path("sorted_bam/${sample}_mapped.sorted.bam.gz"), emit: sorted_bam, optional: true

    script:
    def (forward, reverse) = reads

    """
    # Create output directory for bam and log files
    touch ${sample}_binning.log


    if [[ -s "${contigs}" ]]; then

        # Output sample name and contig name to log file
        echo "Filename: ${sample}" >> "${sample}_binning.log"
        echo "\n" >> "${sample}_binning.log"
        echo "Mapping to: ${contigs}" >> "${sample}_binning.log"
        echo "\n" >> "${sample}_binning.log"

        # Output Read names to log
        echo "Forward: ${forward}" >> "${sample}_binning.log"
        echo "Reverse: ${reverse}" >> "${sample}_binning.log"

        # Count forward and reverse reads
        forward_read_count=\$(zcat ${forward} | grep -c "^@")
        reverse_read_count=\$(zcat ${reverse} | grep -c "^@")
	
        # Output count from reads to log file
        echo "Forward Read count: \${forward_read_count}" >> "${sample}_binning.log"
        echo "Reverse Read count: \${reverse_read_count}" >> "${sample}_binning.log"
        echo "\n" >> "${sample}_binning.log"

        if [[ "${params.profile}" == *"singularity"* ]]; then
            /opt/bbmap/bbmap.sh \\
            -Xmx${params.map_mem}G \\
            threads=${params.threads} \\
            overwrite=t \\
            ref=${contigs} \\
            in1=${forward} \\
            in2=${reverse} \\
            out=${sample}.mapped.sam
        else
            bbmap.sh \\
            -Xmx${params.map_mem}G \\
            threads=${params.threads} \\
            overwrite=t \\
            ref=${contigs} \\
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
        echo "Total mapped reads: \$(samtools view -c ${sample}.mapped.bam)" >> "${sample}_binning.log"

        rm ${sample}.mapped.bam

        if [[ "${params.profile}" == *"singularity"* ]]; then
            /opt/bbmap/reformat.sh \\
            -Xmx${params.filter_mem}g \\
            minidfilter=${params.bin_min_id_filter} \\
            in=${sample}_mapped.sorted.bam \\
            out=${sample}_mapped.${params.bin_min_id_filter}.sorted.bam \\
            pairedonly=${params.filter_paired} \\
            primaryonly=${params.filter_primary}
        else
            reformat.sh \\
            -Xmx${params.filter_mem}g \\
            minidfilter=${params.bin_min_id_filter} \\
            in=${sample}_mapped.sorted.bam \\
            out=${sample}_mapped.${params.bin_min_id_filter}.sorted.bam \\
            pairedonly=${params.filter_paired} \\
            primaryonly=${params.filter_primary}
        fi

        # Output total mapped reads to log file:
        echo "Reads after filtering at ${params.bin_min_id_filter}: \$(samtools view -c ${sample}_mapped.${params.bin_min_id_filter}.sorted.bam)" >> "${sample}_binning.log"

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

        jgi_summarize_bam_contig_depths --referenceFasta ${contigs} --outputDepth ${sample}_depth.txt ${sample}_mapped.${params.bin_min_id_filter}.sorted.bam
        metabat2 -i ${contigs} -a ${sample}_depth.txt -o all_metabat_bins/bin

        rm ${sample}_mapped.${params.bin_min_id_filter}.sorted.bam

        if ls all_metabat_bins/*.fa 1> /dev/null 2>&1; then
            echo "Sample ${sample}: Metabat bins exist." >> "${sample}_binning.log"

            cd all_metabat_bins

            for bin_file in *.fa; do
                base_name=\$(basename "\${bin_file}" .fa)
                if [[ "\${base_name}" == *"${sample}"* ]]; then
                    new_name="\${base_name}_renamed.fa"
                else
                    new_name="${sample}_\${base_name}_renamed.fa"
                fi
                mv "\${bin_file}" "\${new_name}"
            done

            cd ..
        else
            echo "Sample ${sample}: No Metabat bins were generated." >> "${sample}_binning.log"
        fi

        mkdir logs
        mv ${sample}_binning.log logs/
        mv ${sample}_depth.txt logs/

    else
        echo "Sample ${sample} - Error: No contigs >= ${params.min_contig_len} were generated by ${params.assembler}." >> "${sample}_binning.log"
    fi
    """  
}  
