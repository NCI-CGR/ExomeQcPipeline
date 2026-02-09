"""
This workflow executes a minmal set of checks for quick check at BAM level. It includes following checks:
    - ancestry: runs fastNGSadmix to generate ancestry estimates.
    - contamination: Uses VerifyBamID to estimate contamination.
    - sex: Uses samtools to estimate XYratio.

Usage:

    ml singularity
    unset SLURM_JOB_ID 
    snakemake -s Snakefile_minimal.smk --configfile test_data/config_minimal.yaml --use-singularity --singularity-args "--bind /DCEG,/scratch"
    --workflow-profile profiles/slurm_minimal

output:
    - qc_report.tsv: 
        SAMPLE  ChrX    ChrY    XYratio Contamination_rate      CEU     CHB     YRI     PEL
        1       3418535 6777 504.432 0.00135211 0.0000 1.0000 0.0000 0.0000
        2       2150339 580665 3.70324 0.0109599 0.0000 1.0000 0.0000 0.0000
        3       1631527 413473 3.94591 0.0144326 0.0000 1.0000 0.0000 0.0000
"""

configfile: "test_data/config_minimal.yaml"


with open(config["bamList"], 'r') as bamList:
    BAM = bamList.readlines()
BAM = [line.strip() for line in BAM if line.strip()]  # Remove empty lines and strip whitespace

SAMPLES = range(len(BAM))
project= config["project"]

###############################################
# SEX CHECK
###############################################
module sexcheck_workflow:
    snakefile: "modules_slurm/Snakefile_sex_plot"
    config: config

rule all:
    input:
        project + "/qc_report.tsv"


localrules: aggregate_XYratio, aggregate_ancestry, aggregate_contamination, combine_all_reports


use rule XYratio_single from sexcheck_workflow with:
    input: 
        bam=lambda wildcards: BAM[int(wildcards.sample)]
    output: 
        temp(project + "/XYratio_single/{sample}.tsv")

rule aggregate_XYratio:
    input:
        expand(project + "/XYratio_single/{sample}.tsv", sample=SAMPLES)
    output:
        temp(project + "/XYratio_table.tsv")
    shell:
        """
        echo -e 'SAMPLE\tChrX\tChrY\tXYratio' > {output}
        awk 'BEGIN {{OFS="\t"}} {{print $1, $2, $3, $2/$3}}' {input} >> {output}
        """


###############################################
# ANCESTRY CHECK
###############################################

module ancestry_workflow:
    snakefile: "modules_slurm/Snakefile_ancestry_plot_fastNGSadmix"
    config: config


use rule angsd from ancestry_workflow with:
    input:
        bam=lambda wildcards: BAM[int(wildcards.sample)]
    output:
        temp(project + "/ancestry/{sample}.beagle.gz")

use rule fastNGSadmix from ancestry_workflow with:
    output:
        temp(project + "/ancestry/{sample}.qopt")
        

rule aggregate_ancestry:
    input:
        expand(project + "/ancestry/{sample}.qopt", sample=SAMPLES)
    output:
        temp(project + "/ancestry_table.tsv")
    shell:
        r"""
        echo -e 'SAMPLE\tCEU\tCHB\tYRI\tPEL' > {output}
        awk 'FNR==2 {{
        fname = FILENAME;
        sub(/^.*\//, "", fname);       # remove path
        sub(/\.qopt$/, "", fname);     # remove extension
        print fname, $0;
        nextfile
        }}' {input} >> {output}
        """


###############################################
# CONTAMINATION CHECK
###############################################


module contamination_workflow:
    snakefile: "modules_slurm/Snakefile_contamination_plot"
    config: config

rule run_verifyBamID:
    """This is a copy of the rule at modules_slurm/Snakefile_contamination_plot. 
    The original rule requires `Final_merged_coverage.tx` from secondary pipeline.
    This rule also includes `--DisableSanityCheck` to skip low coverage for testing purposes."""
    input:
        lambda wildcards: BAM[int(wildcards.sample)]
    threads: 4
    output:
        out1 = temp(project + '/contamination/{sample}.selfSM'),
    params:
        outDir = project + '/contamination/{sample}',
        ref = config['ref'],
        omnivcf = config[config['version']]['omniVcf']
    singularity: "docker://griffan/verifybamid2"
    shell:
        """
        VerifyBamID --BamFile {input} --UDPath {params.omnivcf}.dat.UD --BedPath {params.omnivcf}.dat.bed --MeanPath {params.omnivcf}.dat.mu --Reference {params.ref} --Output {params.outDir} --DisableSanityCheck
        """

rule aggregate_contamination:
    """ VerifyBAMID outputs SEQ_ID as basename.
     In this context, we are using `sample` (0-based index) so we need to aggregate appropriately .
    """
    input:
        expand(project + '/contamination/{sample}.selfSM', sample=SAMPLES)
    output:
        temp(project + "/contamination_table.tsv")
    shell:
        r"""
        echo -e 'SAMPLE\tContamination_rate' > {output}
        awk 'FNR==2 {{
        fname = FILENAME;
        sub(/^.*\//, "", fname);       # remove path
        sub(/\.selfSM$/, "", fname);     # remove extension
        print fname, $7;
        nextfile
        }}' {input} >> {output}
        """


###############################################
# AGGREGATE ALL REPORT
###############################################

rule combine_all_reports:
    input:
        sex=project + "/XYratio_table.tsv",
        ancestry=project + "/ancestry_table.tsv",
        contamination=project + "/contamination_table.tsv"
    output:
        project + "/qc_report.tsv"
    shell:
        """
        echo -e 'SAMPLE\tChrX\tChrY\tXYratio\tContamination_rate\tCEU\tCHB\tYRI\tPEL' > {output}
        join <(sort {input.sex}) <(tail -n +2 {input.contamination} | sort) | join - <(tail -n +2 {input.ancestry} | sort) >> {output}
        """