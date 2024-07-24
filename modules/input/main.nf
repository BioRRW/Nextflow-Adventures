process INPUT {
    errorStrategy 'terminate'

    input:
        path(reads)

    script:
    """
    #!/bin/bash

    # Check if the input files exist
    if [ ! -f ${reads} ]; then
        echo "Input files do not exist: ${reads}"
        exit 1
    fi

    rm *

    """
}