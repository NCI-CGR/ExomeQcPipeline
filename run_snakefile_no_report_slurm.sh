#!/bin/sh

module load python3/3.10.2 singularity slurm R

DATE=$(date +%y%m%d)
proDir=$(awk '($0~/^project:/){print $2}' modules_slurm/config.yaml | sed "s/['\"]//g")
mkdir -p ${proDir}/logs_${DATE}


snakemake --unlock -s Snakefile_no_report_slurm --configfile modules_slurm/config.yaml

#sbcmd="qsub -cwd -q {cluster.q} -pe by_node {threads} -o logs_${DATE}/ -e logs_${DATE}/ -V"
sbcmd="sbatch --time=24:00:00 --mem=64g --partition=bigmemq,cgrq --cpus-per-task={threads} --output=${proDir}/logs_${DATE}/snakejob_%j.out"

#qsub -cwd -q seq-calling.q -N run_Snakefile_no_report  -o logs_${DATE}/Snakefile_no_report.stdout -e logs_${DATE}/Snakefile_no_report.stderr -b y "module load python3 sge R/3.4.0 gcc zlib;snakemake -pr -s Snakefile_no_report --keep-going --rerun-incomplete --local-cores 1 --jobs 1000 --configfile modules/config.yaml --cluster \"$sbcmd\" --cluster-config cluster.yaml --latency-wait 120 all"

echo "#!/bin/sh" > ${proDir}/logs_${DATE}/run_snakefile_no_report_slurm.sbatch

echo "module load python3/3.10.2 singularity slurm R; snakemake -pr -s Snakefile_no_report_slurm --use-singularity --singularity-args \"--bind /DCEG,/scratch\" --keep-going --rerun-incomplete --local-cores 1 --jobs 1000 --configfile modules_slurm/config.yaml --cluster \"$sbcmd\" --cluster-config cluster_slurm.yaml --latency-wait 120" >> ${proDir}/logs_${DATE}/run_snakefile_no_report_slurm.sbatch

sbatch --time=24:00:00 --output=${proDir}/logs_${DATE}/run_snakefile_no_report_slurm.out --error=${proDir}/logs_${DATE}/run_snakefile_no_report_slurm.err ${proDir}/logs_${DATE}/run_snakefile_no_report_slurm.sbatch

