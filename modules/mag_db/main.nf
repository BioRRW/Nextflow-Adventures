process MAG_DB {
    /*
        MAG_DB Process
        Written by Reed Woyda under the Wrighton Lab at Colorado State University.
        November 2023
    */

    // Define the input for the MAG_DB process
    input:
        // Input is a path to filtered bins and an existing MAG database
        path(filtered_bins)
        path(mag_db)

    // Define the output for the MAG_DB process
    output:
        // Output is the main MAG database in the form of a path to a FASTA file
        path("mag_db.fa"), emit: main_mag_db_out

    script:
    """
    # Create a temporary MAG database by concatenating filtered bins and the existing MAG database
    cp ${mag_db} incoming_mag_db.fa
    cat ${filtered_bins} ${mag_db} > temp_mag_db.fa
    cp temp_mag_db.fa mag_db.fa
    rm incoming_mag_db.fa
    rm temp_mag_db.fa
    """
}
