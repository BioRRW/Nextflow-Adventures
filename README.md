# Nextflow Examples and Tutorials

Welcome to the Nextflow Examples and Tutorials repository! This repository contains a collection of Nextflow pipelines that demonstrate various features and capabilities of Nextflow, ranging from beginner to expert levels.

## Table of Contents

- [Introduction](#introduction)
- [Examples](#examples)
  - [Simple](#simple)
  - [Beginner](#beginner)
  - [Intermediate](#intermediate)
  - [Advanced](#advanced)
  - [Expert](#expert)
- [Getting Started](#getting-started)
- [Contributing](#contributing)
- [License](#license)

## Introduction

Nextflow is a powerful and flexible workflow management system that enables reproducible computational workflows. This repository aims to provide a comprehensive set of examples and tutorials to help users of all skill levels get started with Nextflow and advance their skills.

## Examples

### Simple

The simple example contains process definitions within the main workflow, providing an easy-to-understand introduction to Nextflow.

### Beginner

The beginner example has separate `.nf` and `config` files, making it easier to manage and extend the pipeline configuration.

- **Pipeline**: `genome-QC.nf`
- **Configuration**: `genome-QC-beginner.config`

### Intermediate

The intermediate example introduces profiles, allowing you to switch between different configurations, such as using Conda or Singularity, without SLURM.

- **Pipeline**: `genome-QC.nf`
- **Configuration**: `genome-QC-intermediate.config`
- **Profiles**: `conda`, `singularity`, `conda_slurm`, `singularity_slurm`

### Advanced

The advanced example includes SLURM profiles, enabling the use of SLURM workload manager for job scheduling.

- **Pipeline**: `genome-QC.nf`
- **Configuration**: `genome-QC-advanced.config`
- **Profiles**: `conda`, `singularity`

### Expert

The expert example has separate workflows, demonstrating how to modularize and structure complex pipelines.

## Getting Started

To get started with these examples, clone the repository and follow the instructions for each example. Below is a general guide to running the pipelines:

1. **Clone the repository**:

    ```bash
    git clone https://github.com/yourusername/nextflow-examples.git
    cd nextflow-examples
    ```

2. **Run the desired example**:

    For the beginner example:

    ```bash
    nextflow run genome-QC.nf -c genome-QC-beginner.config --input_reads test_data/
    ```

    For the intermediate example with the `conda` profile:

    ```bash
    nextflow run genome-QC.nf -c genome-QC-intermediate.config -profile conda --input_reads test_data/
    ```

    For the advanced example with the `singularity` profile:

    ```bash
    nextflow run genome-QC.nf -c genome-QC-advanced.config -profile singularity --input_reads test_data/
    ```

3. **Modify the configurations**:

    Adjust the configuration files as needed for your specific environment and requirements.

## Contributing

Contributions are welcome! If you have any examples, tutorials, or improvements, please submit a pull request or open an issue.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
