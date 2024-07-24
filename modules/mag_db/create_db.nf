process CREATE_DB {

    output:
    path("mag_db.fa"), emit: temp_db


    script:
    """

    touch mag_db.fa

    """
}