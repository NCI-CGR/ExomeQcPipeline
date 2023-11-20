#!/bin/sh
. /etc/profile.d/modules.sh
module load R plink/2.0 bcftools tabix

VCF=$1
shift

if [[ $# == 1 ]]; then
	sampList=$1
	PARAMS="-S $sampList"
else
	PARAMS=""
fi	

DIR=$(dirname $VCF)
NAME=$(basename $VCF .vcf.gz)

bcftools view -f threeCallers,twoCallers -i '(INFO/HC_AF > 0.05) || (INFO/DV_AF > 0.05 )' --types snps $PARAMS -Oz -o ${DIR}/${NAME}.common.eur.vcf.gz $VCF
tabix -p vcf ${DIR}/${NAME}.common.eur.vcf.gz 

plink2 --vcf ${DIR}/${NAME}.common.eur.vcf.gz  --double-id --allow-extra-chr --set-missing-var-ids @:#\$1,\$2 --indep-pairwise 50 10 0.1 --vcf-half-call m --out ${DIR}/${NAME}

plink2 --vcf ${DIR}/${NAME}.common.eur.vcf.gz --double-id --allow-extra-chr --set-missing-var-ids @:#\$1,\$2 --extract ${DIR}/${NAME}.prune.in  --vcf-half-call m --make-bed --pca --out ${DIR}/${NAME}.common.eur

Rscript modules_slurm/PCA.R ${DIR}/${NAME}.common.eur.eigenvec ${DIR}/${NAME}.common.eur.eigenval



