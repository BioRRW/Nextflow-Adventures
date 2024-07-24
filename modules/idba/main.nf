process IDBA {
/*
    IDBA Process
    Written by Reed Woyda under the Wrighton Lab at Colorado State University.
    November 2023
*/
    errorStrategy 'finish'

    // Add an ID tag to the process
    tag { sample }

    // Define the input for IDBA process, including raw read data and multiQC output
    input:
        tuple val(sample), val(iteration_flag), val(iteration_count), path(reads, stageAs: 'reads/*')
        val(multiqc_output)
        path(pull_seq_script)
    
    // Define the output for IDBA process, which includes contigs, trimmed contigs, and assembly log files
    output:
        // Output original contigs (optional for testing purposes)
        tuple val(sample), val(iteration_flag), val(iteration_count), path("all_contigs/${sample}.contigs.fa"), emit: contigs, optional: true
        // Output trimmed contigs with a specific minimum length (optional for testing purposes)
        tuple val(sample), val(iteration_flag), val(iteration_count), path("${params.min_contig_len}_contigs/${sample}.contigs.${params.min_contig_len}.fa"), emit: trimmed_contigs, optional: true
        // Output assembly log (optional for testing purposes)
        tuple val(sample), val(iteration_flag), val(iteration_count), path("logs/${sample}.idba.log"), emit: assembly_log, optional: true

    // Execute this process only when multiQC output is available
    when:
        multiqc_output != null

    // Bash script for IDBA process
    script:
    def (forward, reverse) = reads

    """
    # Prepare input for IDBA-UD by creating an interleaved FASTA file
    # IDBA-UD does not accept .gz files
    pigz -d -c -p ${params.threads} ${forward} > forward.fq
    pigz -d -c -p ${params.threads} ${reverse} > reverse.fq

    # Use fq2fa to merge and filter the forward and reverse reads into merged.fa
    # Merge paired-end reads
    # Filter low-quality reads
    # Input forward read file
    # Input reverse read file
    fq2fa \\
    --merge \\
    --filter \\
    forward.fq \\
    reverse.fq \\
    merged.fa

    # Clean up temporary files
    rm *.fq

    # Run IDBA-UD for metagenome assembly
    # Input merged read file
    # Output directory
    # Number of CPU threads for parallel processing
    # Minimum k-mer size
    # Maximum k-mer size
    # Step size for k-mer sizes

    idba_ud \\
    --read merged.fa \\
    --out ${sample}_idba \\
    --num_threads ${params.threads} \\
    --mink ${params.idba_min_k} \\
    --maxk ${params.idba_max_k} \\
    --step  ${params.idba_step_k}  

    # Clean up the merged.fa file
    rm merged.fa

    # Create a directory for trimmed contigs
    mkdir ${params.min_contig_len}_contigs

    if [ -s "${sample}_idba/scaffold.fa" ]; then 
        # Use pullseq to filter contigs by minimum length
        python ${pull_seq_script} \\
        -i ${sample}_idba/scaffold.fa \\
        -m ${params.min_contig_len} \\
        -o "${params.min_contig_len}_contigs/${sample}.contigs.${params.min_contig_len}.fa"  

        # Create directories for all contigs and logs
        mkdir all_contigs
        mkdir logs

        # Move the scaffold.fa and log files to appropriate directories
        mv ${sample}_idba/scaffold.fa all_contigs/${sample}.contigs.fa
        mv ${sample}_idba/log logs/${sample}.idba.log 

        # Remove the temporary IDBA-UD directory
        rm -rf ${sample}_idba/
    else
        # Handle the case where IDBA-UD did not produce any contigs
        echo "Sample ${sample} - Error: IDBA-UD did not produce any contigs."
        rm -rf ${sample}_idba/
    fi
    """  
}
