""""
Reusable functions for the pipeline.
"""
from glob import glob


def initializeConfigVariables(config: dict):
    """
    Initializes variables from the config.
    To be used in Snakemake modules at top level.
    """

    manifest = config['manifest']
    project = config['project']
    version = config['version']
    GROUPS=[]
    SAMPLES = []
    sampleGroupDict = {}
    refFile = config['ref']
    bam_location = config['bam_location'] # not returned, but used in getBam function

    with open(manifest) as f:
        next(f)
        for line in f:
            (group, analysisid) = [line.split(',')[i] for i in [6,12]] #with list index [6,11,12], it will throw error "list indices must be integers or slices, not tuple". Need to explicitly specify by the loop, because you cannot index list
            sample = group + "_" + analysisid
            sample = analysisid
            if (sample not in SAMPLES):
                SAMPLES.append(sample)
                sampleGroupDict[sample] = group        
                if group not in GROUPS:            
                    GROUPS.append(group)

    def getBam(wildcards):
        """
        Returns the BAM file path for a given sample.
        To be used in Snakemake rules.
        """
        (group) = sampleGroupDict[wildcards.sample]
        return (glob(bam_location + '/' + group + '/' + wildcards.sample + '.bam')) 

    return (manifest, project, version, GROUPS, SAMPLES, sampleGroupDict, refFile, getBam)
