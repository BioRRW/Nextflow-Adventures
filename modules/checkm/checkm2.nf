process CHECKMTWO {
    /*
        CHECKMTWO Process
        Written by Reed Woyda under the Wrighton Lab at Colorado State University.
        November 2023
    */

    // Add an ID tag to the process
    tag { sample }

    // Define the input for CHECKMTWO process
    input:
        tuple val(sample), val(iteration_flag), val(iteration_count), path(bins), path(depth)

    // Define the output for CHECKMTWO process, including CheckM quality report
    output:
        tuple val(sample), val(iteration_flag), val(iteration_count), path("${sample}_quality_report.tsv"), emit: checkm_results

    // Use a temporary work directory for the process
    scratch true

    // Bash script for CHECKMTWO process
    script:
    """
    mkdir -p bins
    mv ${bins} bins/  # Move bin files to a 'bins' directory

    if [[ "${params.profile}" == *"conda"* ]]; then
        # Set a temporary directory in a known writable location
        TMPDIR="/tmp/tmp_${sample}"
        SHORT_TMPDIR="/tmp/short_tmp_${sample}"

        mkdir -p \${TMPDIR}
        ln -s \${TMPDIR} \${SHORT_TMPDIR}
        mkdir -p bins
        mv ${bins} bins/

        echo "TMPDIR is set to \$SHORT_TMPDIR"
        echo "Disk usage before CheckM2 run:"
        df -h \$SHORT_TMPDIR
    fi

    if [[ "${params.profile}" == *"singularity"* ]]; then
        source /opt/mamba/bin/activate checkm2  # Activate the CheckM2 environment
    fi

    if [[ "${params.profile}" == *"conda"* ]]; then
        checkm2 \\
        predict \\
        -x fa \\
        -i bins/ \\
        -o checkm2_v1.0.1 \\
        -t ${params.threads} \\
        --tmpdir \$SHORT_TMPDIR
    else
        checkm2 \\
        predict \\
        -x fa \\
        -i bins/ \\
        -o checkm2_v1.0.1 \\
        -t ${params.threads}
    fi


    if [[ "${params.profile}" == *"singularity"* ]]; then
        source /opt/mamba/bin/deactivate  # Deactivate the CheckM2 environment
    fi
    mv checkm2_v1.0.1/quality_report.tsv ${sample}_quality_report.tsv  # Rename and move the CheckM quality report
    rm -rf checkm2_v1.0.1  # Remove temporary files and directories

    # Cleanup symlink
    if [[ "${params.profile}" == *"conda"* ]]; then
        rm \${SHORT_TMPDIR}
    fi
    """
}
