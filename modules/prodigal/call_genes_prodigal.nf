process CALL_GENES {
    /*
        CALL_GENES Process
        Written by Reed Woyda under the Wrighton Lab at Colorado State University.
        November 2023
    */

    errorStrategy 'finish'

    // Add an ID tag to the process
    tag { sample }

    // Define the input for CALL_GENES process
    input:
        // Input is a tuple consisting of a sample with associated iteration_flag and iteration_count
        // and the path to the input fasta file
        tuple val(sample), val(iteration_flag), val(iteration_count), path(fasta)

    // Define the output for CALL_GENES process, including called genes, proteins, and GFF files
    output:
        // Output a channel for called genes file - fna
        path("called_genes/*"), emit: prodigal_genes, optional: true
        // Output a channel for called protein file - faa
        path("called_proteins/*"), emit: prodigal_proteins, optional: true
        // Output a channel for GFF file
        path("called_gff/*"), emit: prodigal_gff, optional: true

    // Bash script for CALL_GENES process
    script:
    """
    if [ -s "${fasta}" ]; then
        # Run Prodigal to predict genes and generate GFF, protein, and DNA files
        prodigal \\
        -i "${fasta}" \\
        -f gff \\
        -o "${sample}_called_genes.gff" \\
        -a "${sample}_called_genes.faa" \\
        -d "${sample}_called_genes.fna"

        # Create output directories
        mkdir -p called_genes
        mkdir -p called_proteins
        mkdir -p called_gff

        # Move the generated files to their respective directories
        mv "${sample}_called_genes.gff" called_gff/
        mv "${sample}_called_genes.faa" called_proteins/
        mv "${sample}_called_genes.fna" called_genes/
    else
        echo "Warning: Input fasta file is empty for sample ${sample}. Skipping CALL_GENES."
    fi
    """
}
