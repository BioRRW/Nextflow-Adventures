process MULTIQC {
/*
    MULTIQC Process
    Written by Reed Woyda.
    July 2024
*/
    // Define the input for MULTIQC process
    input:
        path 'logs/*'

    // Define the output for MULTIQC process, including an HTML report and data files
    output:
        path "multiqc_report.html", emit: html
        path "multiqc_data", emit: data

    // Bash script for MULTIQC process
    script:
    """
    # Generate a multi-sample quality control report using MULTIQC
    # --config Specify a custom configuration file (multiqc_config.yaml)
    # . Search for log files in the current directory

    multiqc \\
        .

    """
}
