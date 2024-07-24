process METASPADES {
/*
    METASPADES Process
    Written by Reed Woyda under the Wrighton Lab at Colorado State University.
    November 2023
*/
    errorStrategy 'finish'

    // Add an ID tag to the process
    tag { sample }

    // Define the input for METASPADES process, including raw read data and multiQC output
    input:
        tuple val(sample), val(iteration_flag), val(iteration_count), path(reads, stageAs: 'reads/*')
        val(multiqc_output)
        path(pull_seq_script)
    
    // Define the output for METASPADES process, which includes contigs, assembly graphs, trimmed contigs, and assembly log files
    output:
    tuple val(sample), val(iteration_flag), val(iteration_count), path("all_contigs/${sample}.contigs.fa"), emit: contigs, optional: true
    tuple val(sample), val(iteration_flag), val(iteration_count), path("all_graphs/${sample}.assembly.graph.fastg"), optional: true
    tuple val(sample), val(iteration_flag), val(iteration_count), path("${params.min_contig_len}_contigs/${sample}.contigs.${params.min_contig_len}.fa"), emit: trimmed_contigs, optional: true
    tuple val(sample), val(iteration_flag), val(iteration_count), path("logs/${sample}.assembly.spades.log"), emit: assembly_log, optional: true


    // Execute this process only when multiQC output is available
    // This allows the pipeline to finish all QC before starting assemblies. While this is inefficient for the pipeline, it is efficient for reducing overconsumption of resources on an HPC
    when:
        multiqc_output != null

    // Bash script for METASPADES process
    script:
    def (forward, reverse) = reads

    """
    # Run METASPADES for metagenome assembly
    # Output directory
    # Perform assembly only
    # Input paired-end read file 1
    # Input paired-end read file 2
    # Memory allocation for METASPADES
    # Number of CPU threads for parallel processing
    # K-mer size parameter

    if [[ "${params.profile}" == *"singularity"* ]]; then
        python /opt/SPAdes-3.15.5/metaspades.py \\
        -o "${sample}_metaspades" \\
        --only-assembler \\
        -1 "${forward}" \\
        -2 "${reverse}" \\
        -m ${params.metaspades_mem} \\
        -t ${params.threads} \\
        -k ${params.k_metaspades}
    else
        python metaspades.py \\
        -o "${sample}_metaspades" \\
        --only-assembler \\
        -1 "${forward}" \\
        -2 "${reverse}" \\
        -m ${params.metaspades_mem} \\
        -t ${params.threads} \\
        -k ${params.k_metaspades}
    fi


    # Create a directory for all contigs
    mkdir all_contigs

    # Move the contigs, assembly graph, and log files to appropriate directories
    mv ${sample}_metaspades/contigs.fasta all_contigs/${sample}.contigs.fa
    mv ${sample}_metaspades/assembly_graph.fastg ${sample}_metaspades/${sample}.assembly.graph.fastg
    mv ${sample}_metaspades/spades.log ${sample}_metaspades/${sample}.assembly.spades.log
    
    # Create a directory for trimmed contigs
    mkdir ${params.min_contig_len}_contigs

    if [ -s "all_contigs/${sample}.contigs.fa" ]; then 
        # Use pullseq to filter contigs by minimum length
        python ${pull_seq_script} \\
        -i "all_contigs/${sample}.contigs.fa" \\
        -m ${params.min_contig_len} \\
        -o "${params.min_contig_len}_contigs/${sample}.contigs.${params.min_contig_len}.fa" 

        # Create directories for all assembly graphs and logs
        mkdir all_graphs
        mkdir logs

        # Move the assembly graph and log files to appropriate directories
        mv ${sample}_metaspades/${sample}.assembly.spades.log logs/${sample}.assembly.spades.log 
        mv ${sample}_metaspades/${sample}.assembly.graph.fastg all_graphs/${sample}.assembly.graph.fastg

        # Remove the temporary METASPADES directory
        rm -rf ${sample}_metaspades/
    else
        # Handle the case where METASPADES did not produce any contigs
        echo "Sample ${sample} - Error: Metaspades did not produce any contigs."
        rm -rf ${sample}_metaspades/
    fi
    """  
}
