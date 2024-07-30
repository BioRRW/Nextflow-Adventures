# Nextflow Examples and Tutorials

Welcome to the Nextflow Examples and Tutorials repository! This repository contains a collection of Nextflow pipelines that demonstrate various features and capabilities of Nextflow, ranging from beginner to expert levels.

## Table of Contents

- [Introduction](#introduction)
- [Installation and Setup](#install)
- [Input Data](#input)
- [Getting Started](#getting-started)
- [Examples](#examples)
  - [Simple](#simple)
  - [Beginner](#beginner)
  - [Intermediate](#intermediate)
  - [Advanced](#advanced)
  - [Expert](#expert)
- [Contributing](#contributing)
- [License](#license)

<a name="introduction"></a>
## Introduction

### These Nextflow Adventures!

The point of this repository is to provide an introduction into Nextflow, using next-generation sequencing (NGS) data analysis as an example.

Here, I have provided a main Nextflow file/workflow, `genome-QC.nf` which can be used with various `nextflow*.config` files. These various config files are aimed at beginner, intermediate and advanced levels. Beginner is designed to be ran on a computer/cluster/high-performance computing (HPC) cluster which does not have any job scheduler. Intermediate starts to involve Nextflow [profiles](https://www.nextflow.io/docs/latest/config.html#config-profiles) which allow the user to switch quickly between using Singularity and Conda. Finally, Advanced introduces [SLURM](https://slurm.schedmd.com/documentation.html) job scheduling, something which many HPC clusters require a user to use.

In the next sections I detail how to install Nextflow, Conda and Singularity. Then, I start to go in depth in how to input data.

**Jump to [Getting Started](#getting-started) or [Examples](#examples) to get rolling with the code!**

### Nextflow brief introduction
Nextflow is a powerful and flexible workflow management system that enables reproducible computational workflows. This repository aims to provide a comprehensive set of examples and tutorials to help users of all skill levels get started with Nextflow and advance their skills.

Nextflow has great [documentation](https://www.nextflow.io/docs/latest/index.html) which you should definitely check out.

There are sections for [scripts](https://www.nextflow.io/docs/latest/script.html), [processes](https://www.nextflow.io/docs/latest/process.html), [channels](https://www.nextflow.io/docs/latest/channel.html), and much more.

There are also extensive [tutorials](https://www.nextflow.io/blog/2023/learn-nextflow-in-2023.html).

### Nextflow channel basics:
Nextflow channels are used to manage the flow of data between processes in a pipeline. For paired-end sequencing reads, channels can be used to pass the forward and reverse read files as paired data to downstream processes. Each channel acts as a queue that holds data and allows processes to consume it as needed, ensuring proper synchronization and data handling. By using channels, Nextflow ensures that each process receives the correct input data and can execute independently. This modular approach allows for flexible and efficient data processing in bioinformatics pipelines.

--------

<a name="install"></a>
## Installation and Setup

Nextflow pipelines either rely on 1) the host system, 2) Conda recipe file or Conda Environment, or 3) Singularity/Docker container. Thus, the user must ensure they have the dependencies installed in one of these locations (1-3). 

### Clone the repository

```bash
git clone https://github.com/BioRRW/Nextflow-Adventures.git`
```

### Nextflow

It is essential the user has Nextflow installed. This can optionally be done through Conda.

[Install Nextflow >= v23.04.2.5870](https://www.nextflow.io/docs/latest/getstarted.html)
[Install Anaconda/Miniconda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html)

### Singularity

If the user is choosing to use Singularity containers, they must install Singularity and download (or build) the Singularity containers.

[Install Singularity >= v3.7.0](https://docs.sylabs.io/guides/3.0/user-guide/installation.html) (to pull Singularity images from SyLabs).

### Conda and Conda environments

#### Install Conda and (optionally) Mamba

Follow [this link](https://conda.io/projects/conda/en/latest/user-guide/install/index.html) to install Conda or Miniconda.

Follow [this link](https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html) to install Mamba.

#### Setting up Conda environments

Conda can be used two ways in Nextflow: 1) Nextflow will build the necessary Conda environment for each process based on a provided `.yml` file. 2) Nextflow will use a pre-built Conda environment provided by the user. 

Pros and Cons:
Relying on Nextflow to build the Conda environments can be slow as building Conda environments with Conda can be slow. 
Relying on Nextflow to build the Conda environments can also introduce errors based on system settings.
Relying on the user to build the Conda environments puts strain on the user however allows Mamba/Conda to deal with conflicts.
The user can use Conda or Mamba to build the Conda environments - Mamba can make this significantly faster.

Here is where we have defined these within the `nextflow*.config` file:

```bash
        /* Conda Environment recipe files */
        genome_qc_env = "./containers/conda/genome-qc-env.yml"

        /* Conda Pre-built Environment Locations */
        genome_qc_prebuilt_env = "./containers/conda/genome-qc-env"
```

Both of these are valid options. In this tutorial we will rely on the user pre-building the Conda environments.

To build these environments, fist navigate to the `./containers/conda/` directory and then build the environment:

```bash
cd containers/conda
conda env create --prefix ./genome-qc-env --file genome-qc-env.yml 
# OR alternative use Mamba (suggested)
mamba env create --prefix ./genome-qc-env --file genome-qc-env.yml
```

### Singularity Containers

The user can typically rely on Nextflow to find and download a given container *if* that container is hosted on [Sylabs](https://cloud.sylabs.io/).

For this repository, I have *NOT YET* hosted a Singularity container on SyLabs. In the future, below will be the command to download this container. The user should be within the `containers` directory before downloading the container.

I will eventually host this container on SyLabs but for now, the user must build it themselves.

``` bash
cd /containers
sudo singularity build genome-qc.sif genome-qc-singularity-recipe
```
If the user does not have `root` access, they may use the singularity option: `--fakeroot`.

--------
<a name="input"></a>
## Input Data

Nextflow offers a wide array of ways to take in input. In this repository we will cover two ways: 1) using a built in `Channel.fromFilePairs()` function to populate Nextflow channels with NGS paired-end sequencing files, R1 and R2. 2) use `Channel.fromPath(params.input_csv).splitCsv(sep: ',')` to directory take in a CSV file containing a <sample>, <R1 file> and <R2> file and generate out Nextflow channels.

**Note:** The data we will be using has the requirement of being named with `R1` and `R2` in the respective read-pair filenames AND they must be gzipped (i.e. *.gz).

### Input via `--input_reads` user-provided directory 

We have setup, in the `nextflow*.config` files, an input filename design (which can totally be modified) to look for all files in a provided directory with `R1` or `R2` and also `f*.gz`. in short, this requires the user to provide filenames with `R1` and `R2` in them and additionally have them gzipped.

These requirements are not always required and is a set assumption for this tutorial and must be stated to the user.

Nextflow config setup:
```bash
    reads = "./raw_reads/*_R{1,2}*.f*.gz"
    reads_fmt = "*_R{1,2}*.f*.gz"
```
Here, `reads` is a default location where the pipeline will look for potential read files. `reads_fmt` is setting the file pattern we are looking for when the user specifies a directory.

Example usage:
```bash
    nextflow run genome-QC.nf -c genome-QC-intermediate.config --input_reads test_data/
```

### Input via CSV file

We are first requiring the user to have the CSV in the following format:

```bash
<sample_name> , /path/to/sample_R1.fastq.gz     , /path/to/sample_R2.fastq.gz
Sample1       , /data/reads/Sample1_R1.fastq.gz , /data/reads/Sample1_R2.fastq.gz
```

Example usage:
```bash
    nextflow run genome-QC.nf -c genome-QC-intermediate.config --input_csv example_input.csv
```

See the file, [example_input.csv](./example_input.csv) for the CSV file used in this tutorial.

--------

<a name="getting-started"></a>
## Getting Started

To get started with these examples, clone the repository and follow the instructions for each example. Below is a general guide to running the pipelines:

1. **Clone the repository**:

    ```bash
    git clone https://github.com/BioRRW/Nextflow-Adventures.git
    cd Nextflow-Examples
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

---------

<a name="examples"></a>
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

--------

## Contributing

Contributions are welcome! If you have any examples, tutorials, or improvements, please submit a pull request or open an issue.

I will be continually adding more examples and also digging deeper into an expert level!

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
