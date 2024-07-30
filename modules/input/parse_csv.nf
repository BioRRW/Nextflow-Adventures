process PARSE_CSV {
    errorStrategy 'terminate'

    input:
        path input_csv

    output:
        tuple val(id), path(forward_pair), path(reverse_pair)

    script:
    """
    cat $input_csv | while IFS=',' read -r id forward_pair reverse_pair; do
        echo "$id $forward_pair $reverse_pair"
    done
    """
}