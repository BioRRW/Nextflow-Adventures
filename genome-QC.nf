/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    genom-QC: a Nextflow example
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Load Modules
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { INPUT } from './modules/input'
include { FASTQC as FASTQC_RAW } from './modules/fastqc'
include { FASTQC as FASTQC_TRIMMED } from './modules/fastqc'
include { FASTP } from './modules/fastp'
include { MULTIQC } from './modules/multiqc'


/* Display help message */
if ((params.help) || (params.h)){
    helpMessage()
    exit 0
}

/* Options to display the current version */
if((params.version) || (params.v)){
    version()
    exit 0
}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Main workflow for the genome QC pipeline
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {
    if ( params.input_reads ) {
        reads = Channel.fromFilePairs(params.input_reads + params.reads_fmt, checkIfExists: true)
        temp_reads = params.input_reads + params.reads_fmt
    } else {
        reads = Channel.fromFilePairs(params.reads, checkIfExists: true)
        temp_reads = params.reads
    }

    // Logging based on user input

    log.info """
            COMET Pipeline v0.0.1
            QC Only
            ===================================
            reads        : ${temp_reads}
            outdir       : ${params.outdir}
            threads      : ${params.threads}
            """
            .stripIndent()        

        // Pass reads channel to initial FastQC 
        FASTQC_RAW( reads )

        // Pass reads channel to the trimmer - FastP 
        FASTP ( reads )

        // Pass FastP output channel, trimmed, to initial FastQC 
        FASTQC_TRIMMED( FASTP.out.trimmed_reads )

        qc_reads = FASTP.out.trimmed_reads

        // Collect logs from raw data fastQC and trimmed fastQC for MultiQC
        Channel
            .empty()
            .mix(FASTQC_RAW.out)
            .mix(FASTQC_TRIMMED.out)
            .map { sample, files -> files }
            .collect()
            .set { log_files }
            
        // Pass the collected log files to MultiQC
        MULTIQC( log_files )

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Error function definition
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def filesExist(locations) {
    locations.every { file(it).exists() }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Version menu
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
def version() {
    log.info"""

    genome-QC Example v0.0.1

    Software versions used:
    FastQC     v0.12.1
    MultiQC    v1.14
    FastP      v0.23.2

    """.stripIndent()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Help menu
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
def helpMessage() {
    log.info"""

    nextflow run genome-QC.nf [OPTIONS]
    nextflow run genome-QC.nf --help
    nextflow run genome-QC.nf --version

    Example usage: QC a set of input reads
    nextflow run genome-QC.nf --input_reads test_data/

    List of full command line options
        General:
            --help    (--h)         Display this help menu
            --version (--v)         Display the current version 
            
        Inputs:
            --input_reads           STR     ( Path to raw sequencing data. Can be gzipped. Default: raw_reads/*_R{1,2}*.f*.gz )
                                            ( The user must provide a path to a directory containing the reads, NOT a path to the reads themselves. )

        Outputs:
            --outdir                STR     (Path to desired output directory, example: example_output/)
                                            (Default: ./COMET-Results-0.4.0)

        Fastp trimming options:
            --trim_quality          INT     ( Default: 20 )

        Computation:
            --threads               INT     ( Default: 10. Number of CPUs to allocate to EACH process individually. )
            --queue_size            INT     Speficy the total number of processes which can occur at a time.    
                                                I.e., How many assemblies and mappings can occur at a given time?
            
        Nextflow Options:
            -resume                 Pipeline will resume from previous run if terminated prematurely.
            -with-report            Creates an HTML report with various metrics about the pipelines execution.
            -with-trace             Creates a text log file with logging from the Nextflow run.

        Documentation: https://github.com/BioRRW/Nextflow-Examples

        Software versions used:
        FastQC     v0.12.1
        MultiQC    v1.14
        FastP      v0.23.2

        """.stripIndent()
}
