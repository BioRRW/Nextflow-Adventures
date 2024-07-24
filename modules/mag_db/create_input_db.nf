process CREATE_INPUT_DB {

    input:
    path( input_mag_db )
    
    output:
    path( "provided_input_MAG_db.fa" ), emit: built_provided_mag_db



    script:
    """
    mv ${input_mag_db} provided_input_MAG_db.fa

    """

}

