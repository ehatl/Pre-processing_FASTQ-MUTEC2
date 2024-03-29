#! /bin/bash

#This pipeline is for Aligments files with the References,
#transform SAM to BAM, Sort and Merge BAMs files and 
#finally add ReadsGroups
#I follow the Best Practices of GATK 4 for Mutect2

source /Path/to/config_file.sh

#Input Files
Uno=${1}
Dos=${2}
Tres=${3}
Cuatro=${4}

######## Alignment Files wit BWA-mem ############

#Change names for SAM output files
SAMoutp=`basename ${Uno} | sed 's/_R1_001_paired\.fq\.gz/_paired\.sam/'`
SAMoutsR1=`basename ${Uno} | sed 's/_R1_001_paired\.fq\.gz/_R1_single\.sam/'`
SAMoutsR2=`basename ${Dos} | sed 's/_R2_001_paired\.fq\.gz/_R2_single\.sam/'`


#Run BWA-mem
#Alignment for Paired read of Trimmomatic output
${BWA} -t ${NT} ${GenomeREF} ${FILTERFQ}"/"${Uno} ${FILTERFQ}"/"${Dos} -o ${PATHBAM}"/"${SAMoutp}
#Alignment for Paired read of Trimmomatic output
${BWA} -t ${NT} ${GenomeREF} ${FILTERFQ}"/"${Tres} -o ${PATHBAM}"/"${SAMoutsR1}
${BWA} -t ${NT} ${GenomeREF} ${FILTERFQ}"/"${Cuatro} -o ${PATHBAM}"/"${SAMoutsR2}


####### Cambiar de formato los SAM a BAM ########

#Generating output file names
BAMoutp=`echo ${SAMoutp} | sed 's/\.sam/\.bam/'`
BAMoutsR1=`echo ${SAMoutsR1} | sed 's/\.sam/\.bam/'`
BAMoutsR2=`echo ${SAMoutsR2} | sed 's/\.sam/\.bam/'`


#Change format from SAM to BAM
${SAMTOOLS} view -bS --threads ${NT} ${PATHBAM}"/"${SAMoutp} -o ${PATHBAM}"/"${BAMoutp}
${SAMTOOLS} view -bS --threads ${NT} ${PATHBAM}"/"${SAMoutsR1} -o ${PATHBAM}"/"${BAMoutsR1}
${SAMTOOLS} view -bS --threads ${NT} ${PATHBAM}"/"${SAMoutsR2} -o ${PATHBAM}"/"${BAMoutsR2}


###### Sort by coordinate of BAM files ########

#Change names for sorted BAM output files
BAMSORTp=`echo ${BAMoutp} | sed 's/\.bam/_sorted\.bam/'`
BAMSORTsR1=`echo ${BAMoutsR1} | sed 's/\.bam/_sorted\.bam/'`
BAMSORTsR2=`echo ${BAMoutsR2} | sed 's/\.bam/_sorted\.bam/'`


#Run Picard to order
${Picard} SortSam I=${PATHBAM}"/"${BAMoutp} O=${PATHBAM}"/"${BAMSORTp} SO=coordinate
${Picard} SortSam I=${PATHBAM}"/"${BAMoutsR1} O=${PATHBAM}"/"${BAMSORTsR1} SO=coordinate
${Picard} SortSam I=${PATHBAM}"/"${BAMoutsR2} O=${PATHBAM}"/"${BAMSORTsR2} SO=coordinate


##### Merge BAM files ########

#Change name for sort BAM file
BAMoutm=`echo ${BAMSORTp} | sed 's/_paired_sorted\.bam/_merged\.bam/'`

#Run Picard for merge BAM 
${Picard} MergeSamFiles INPUT=${PATHBAM}"/"${BAMSORTp} INPUT=${PATHBAM}"/"${BAMSORTsR1} INPUT=${PATHBAM}"/"${BAMSORTsR2} OUTPUT=${PATHBAM}"/"${BAMoutm}


###### Add readgroups to the attached BAM file ######

#Change name for BAM-RG file 
BAMoutRG=`echo ${BAMoutm} | sed 's/_merged\.bam/_merged-RG\.bam/'`

#Generation of ReadGroups (it is necessary to change RGLB by date or by who performed it)
#RGPL on the platform where the experiment was done, the index is always created not moved.
RGID=`basename ${Uno} | cut -d '_' -f 1`
RGPU=`basename ${Uno} | cut -d '_' -f 3`
RGSM=`basename ${Uno} | cut -d '_' -f 1,3`

#Run Picard to attached readgroups
#The RGBL readgroup must be replaced for each experiment.
${Picard} AddOrReplaceReadGroups I=${PATHBAM}"/"${BAMoutm} O=${PATHBAM}"/"${BAMoutRG} RGID=${RGID} RGPU=${RGPU} RGLB=2021_ALf RGSM=${RGSM}  RGPL=ILLUMINA CREATE_INDEX=true


#Deleting unneeded files
#rm -r ${PATHBAM}"/"${SAMoutp} ${PATHBAM}"/"${SAMoutsR1} ${PATHBAM}"/"${SAMoutsR2} ${PATHBAM}"/"${BAMoutp} ${PATHBAM}"/"${BAMoutsR1} ${PATHBAM}"/"${BAMoutsR2} ${PATHBAM}"/"${BAMSORTp} ${PATHBAM}"/"${BAMSORTsR1} ${PATHBAM}"/"${BAMSORTsR2}
