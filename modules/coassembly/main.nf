process COASSEMBLY {
/*
    COASSEMBLY Process
    Written by Reed Woyda under the Wrighton Lab at Colorado State University.
    November 2023
*/
    // The purpose of this process is to combine fastq reads based on the
    // Experimental Design column in the input spreadsheet

    // Define the input for COASSEMBLY process, including path to raw reads and experimental design
    input:
        path(reads)
        path exp_design
        path( ch_parse_csv_script )

    // Define the output for COASSEMBLY process, which is a new channel of combined reads for downstream assembly
    output:
        path("reads/*_R{1,2}*f*.gz"), emit: combined_reads_ch

    // Bash script for COASSEMBLY process
    script:
    """
    #!/bin/bash

    # Create a directory for raw reads
    mkdir reads

    # Move raw read files into the reads directory
    mv *.gz reads/

    # Parse the experimental design CSV using a Python script
    # ${exp_design} specifies the input CSV file
    # reads/*.gz specifies the location of raw read files
    # ${params.threads} specifies the number of threads to use

    python ${ch_parse_csv_script} ${exp_design} reads/*.gz ${params.threads}

    """
}
