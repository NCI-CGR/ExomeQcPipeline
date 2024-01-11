#!/bin/bash


MANIFEST=$1
CASE_FILE=$2
OUTDIR=$3

#dos2unix $MANIFEST
NF=$(awk -F"," 'NR==1{print NF}' $MANIFEST)

if [[ $NF -gt 14 ]]; then
  #a[$2]+=$1 - accumulating values for each group("group" is considered as unique value of the 2nd field, used as array a index)
  awk -F "," 'NR>1{if($15 == ""){$15=1}; a[$7"_"$13]+=$11*$15 }END{ for(i in a) print i"\t"a[i] | "sort -n"}' $MANIFEST > ${OUTDIR}/coverage_added_downsample.txt
  awk -F "," 'NR>1{ a[$7"_"$13]+=$11 }END{ for(i in a) print i"\t"a[i] | "sort -n"}' $MANIFEST > ${OUTDIR}/coverage_added.txt
  #compare if the final coverage is same before and after multiply downsample ratio
  awk -F"\t" 'BEGIN {print "ANALYSISID\tADDED_COV\tDOWNSAMPLE"} NR==FNR { if (n[$2] = $2);next} {print $0"\t",n[$2]?"NO":"YES"}' ${OUTDIR}/coverage_added.txt ${OUTDIR}/coverage_added_downsample.txt > ${OUTDIR}/Sum_Coverage.txt
else
  awk -F "," 'BEGIN{print "ANALYSISID\tADDED_COV\tDOWNSAMPLE"} NR>1{ a[$7"_"$13]+=$11 }END{ for(i in a) print i"\t"a[i]"\tNO" | "sort -n"}' $MANIFEST > ${OUTDIR}/Sum_Coverage.txt
fi

#glu util.join -1 ANALYSISID -2 ANALYSISID -j inner ${OUTDIR}/Sum_Coverage.txt ${CASE_FILE} -o ${OUTDIR}/Final_merged_coverage.txt:c=ANALYSISID,STATUS,COV,ADDED_COV,DOWNSAMPLE 
(head -n 1 ${CASE_FILE} && tail -n +2 ${CASE_FILE} |sort) > ${CASE_FILE}.tmp
(head -n 1 ${OUTDIR}/Sum_Coverage.txt && tail -n +2 ${OUTDIR}/Sum_Coverage.txt|sort) > ${OUTDIR}/Sum_Coverage.txt.tmp
join -t $'\t' ${CASE_FILE}.tmp ${OUTDIR}/Sum_Coverage.txt.tmp  > ${OUTDIR}/Final_merged_coverage.txt
rm ${CASE_FILE}.tmp  ${OUTDIR}/Sum_Coverage.txt.tmp

awk -F"\t" '{print $1"\t"$3}' ${OUTDIR}/Sum_Coverage.txt > ${OUTDIR}/../Downsample.txt


