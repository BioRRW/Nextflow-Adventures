process FILTER_BINS {
    /*
        FILTER_BINS Process
        Written by Reed Woyda under the Wrighton Lab at Colorado State University.
        November 2023
    */

    // Add an ID tag to the process
    tag { sample }

    // If no bins were generated of required quality, then we need to stop this sample's execution
    errorStrategy 'finish'

    // Define the input for the FILTER_BINS process
    input:
        // Input is a tuple consisting of a sample, iteration_flag, iteration_count, bin files, and quality reports
        tuple val(sample), val(iteration_flag), val(iteration_count), path(bins), path(quality)

    // Define the output for FILTER_BINS process, including filtered bins
    output:
        tuple val(sample), val(iteration_flag), val(iteration_count), path(bins),path("all_bins/*"), emit: filtered_bins, optional: true
        tuple val(sample), val(iteration_flag), val(iteration_count), path(bins),path("complete-${params.completeness}_contam-${params.contamination}_filtered_bins/*"), emit: complete_filtered_bins, optional: true

    script:

    def output_file = "output.txt"

    """
    # Create directories for filtered bins and complete filtered bins
    mkdir -p all_bins
    mkdir -p complete-${params.completeness}_contam-${params.contamination}_filtered_bins

    # Use awk to filter bins based on completeness and contamination criteria
    awk -F "\\t" 'NR > 1 && \$2 > ${params.completeness}-1 && \$3 < ${params.contamination}+1 {print \$1}' ${quality} > "${output_file}"

    # Process each line in the output file
    while IFS= read -r line; do
        original_file="\${line}.fa"

        # Rename the headers using rename.sh or bbmap's rename tool
        if [[ "${params.profile}" == *"singularity"* ]]; then
            /opt/bbmap/rename.sh \\
            in="\${original_file}" \\
            out="all_bins/\${original_file}" \\
            prefix="\${original_file}"
        else
            rename.sh \\
            in="\${original_file}" \\
            out="all_bins/\${original_file}" \\
            prefix="\${original_file}"
        fi

        # Move the renamed file to the complete filtered bins directory if it meets the criteria
        if grep -q "\${line}" "${output_file}"; then
            cp "all_bins/\${original_file}" "complete-${params.completeness}_contam-${params.contamination}_filtered_bins/"
        fi
    done < "${output_file}"

    """
}
