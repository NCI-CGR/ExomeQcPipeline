## Introduction of ExomeQcPipeline

ExomeQcPipeline can be excuted in four modes: germline wes mode,germline wgs mode and somatic pair mode and tumor only mode. Difference between the four modes are 
1. somatic pair mode contains exclusive modules of bam-matcher to check tumor normal pairs and no sample relateness check.
2. tumor only mode is mostly same as somatic pair mode except nor bam-matcher test. 
3  germline wes/target mode contains sample relateness check and post calling qc contains total filtered variant count, ti/tv ratio and base change check, call rate check and sample PCA. 
4. wgs mode is mostly same as wes/target mode except no capturekit related qc stats.

Also the pipeline has two branches: report generation branch and non report generation branch(bam level):
1. report generation branch: will automaticlly generate all modules according to somatic/germline setting in the config.yaml file. Output report will be in word_doc folder.
2. non report generation branch: will run any module set as TRUE in config_no_report.yaml file. Output table and figure will be in the subfolder of the particular module.

## Input Requirement:

__None report branch:__
- Fill the config file modules_slurm/config.yaml
  - Build manifest file
  - Bam-matcher_check: fill pair.txt if for somatic pair mode
  - pre_calling_check: fill pre-calling qc 
  - postcalling_check: fill ensemble_dir TRUE

__Report branch:__
- Fill all items in modules/config.yaml
  - Manifest for for the build
  - Input bam file folder (bam files from different groups should be is different subfolders)
  - Pre-calling qc report from secondary analysis pipeline
  - Capturekit bed file (somatic and wes only)
  - vcf file jointly called from input bam files(germline wes/target/wgs data only)
  - paired tumor normal folder paith with files following "_5callers_voting_PASS.vcf" suffix(somatic mode only)
  - tumor only input folder paith with files following "_WES_PON_passed.vcf" suffix(tumor only mode only)


## How to run:

__None report branch:__
1. Create ExomeQcPipeline folder under build directory and download this repo to the ExomeQcPipeline folder
2. Modify all parameters in `modules_slurm/config.yaml`
3. run `sh run_snakefile_no_report.sh`

__Report branch:__
1. Create ExomeQcPipeline folder under build directory and download this repo to the ExomeQcPipeline folder
2. Modify all parameters in `modules_slurm/config.yaml`
3. run `sh run_snakefile_report.sh`

## Test dataset:

__germline:__
  - 72 Giab controls sample testing build: /DCEG/Projects/Exome/builds/build_germline_pipeline_V3_testing/QC/
  
  1. run `mv test/config_germline_example.yaml modules/config.yaml`
  2. run `mv test/config_no_report_germline_example.yaml modules/config_no_report.yaml`

__somatic:__
  - Breast cancer tumor normal buildL /DCEG/Projects/Exome/builds/build_SR0443-004_somatic_UMI_25938/QC/
  
  1. run `mv test/config_somatic_example.yaml modules/config.yaml`
  2. run `mv test/config_no_report_somatic_example.yaml modules/config_no_report.yaml`

## Possible errors:

1, Error in dyn.load(file, DLLpath = DLLpath, ...) : unable to load shared object '/mnt/nfs/gigantor/ifs/DCEG/Home/luow2/R/x86_64-pc-linux-gnu-library/3.4/farver/libs/farver.so':
   run `module unload gcc/4.8.4`
   
2, Doc report generated but figures are all unviewable. 
   run `chmod -R 775 ExomeQcPipeline`   


