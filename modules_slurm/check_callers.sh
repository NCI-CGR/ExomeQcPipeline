#!/bin/bash
. /etc/profile.d/modules.sh
module load bcftools

vcf=$1
dir=$(dirname $vcf)

shift
if [[ $# == 1 ]]; then
	bed=$1
	region="-R ${bed}"
else
	region=""
fi
bcftools view $region $vcf | grep '^[^#]' | awk '{print $8}' | awk -F"set=" '{print $2}' | sort | uniq -c > ${dir}/caller_concordance.txt
