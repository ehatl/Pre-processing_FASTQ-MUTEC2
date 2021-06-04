#! /bin/bash

source /media/citogenetica/Alfredo_Disk/May_Mouse_MS_2021/Scripts_files/config_file.sh

#Entrada de los archivos a analizar
Uno=${1}
Dos=${2}
Tres=${3}
Cuatro=${4}

######## Alineamiento de archivos ############
#Cambio de nombres para generar los archivos SAM
SAMoutp=`basename ${Uno} | sed 's/_R1_001_paired\.fq\.gz/_paired\.sam/'`
SAMoutsR1=`basename ${Uno} | sed 's/_R1_001_paired\.fq\.gz/_R1_single\.sam/'`
SAMoutsR2=`basename ${Dos} | sed 's/_R2_001_paired\.fq\.gz/_R2_single\.sam/'`


#Ejecutar bwa con sus parametros
#Alineamieto pareado
${BWA} -t ${NT} ${GenomeREF} ${FILTERFQ}"/"${Uno} ${FILTERFQ}"/"${Dos} -o ${PATHBAM}"/"${SAMoutp}
#Alineamiento de los no pareados
${BWA} -t ${NT} ${GenomeREF} ${FILTERFQ}"/"${Tres} -o ${PATHBAM}"/"${SAMoutsR1}
${BWA} -t ${NT} ${GenomeREF} ${FILTERFQ}"/"${Cuatro} -o ${PATHBAM}"/"${SAMoutsR2}


####### Cambiar de formato los SAM a BAM ########

#Generando nombres de archivos de salida
BAMoutp=`echo ${SAMoutp} | sed 's/\.sam/\.bam/'`
BAMoutsR1=`echo ${SAMoutsR1} | sed 's/\.sam/\.bam/'`
BAMoutsR2=`echo ${SAMoutsR2} | sed 's/\.sam/\.bam/'`


#Cambio de formato los SAM a BAM
${SAMTOOLS} view -bS --threads ${NT} ${PATHBAM}"/"${SAMoutp} -o ${PATHBAM}"/"${BAMoutp}
${SAMTOOLS} view -bS --threads ${NT} ${PATHBAM}"/"${SAMoutsR1} -o ${PATHBAM}"/"${BAMoutsR1}
${SAMTOOLS} view -bS --threads ${NT} ${PATHBAM}"/"${SAMoutsR2} -o ${PATHBAM}"/"${BAMoutsR2}


###### Ordenar por coordenada los archivos BAM ########

#Cambio de nombre para generar archivos BAM sorted
BAMSORTp=`echo ${BAMoutp} | sed 's/\.bam/_sorted\.bam/'`
BAMSORTsR1=`echo ${BAMoutsR1} | sed 's/\.bam/_sorted\.bam/'`
BAMSORTsR2=`echo ${BAMoutsR2} | sed 's/\.bam/_sorted\.bam/'`


#Ejecutar picard para ordenar
${Picard} SortSam I=${PATHBAM}"/"${BAMoutp} O=${PATHBAM}"/"${BAMSORTp} SO=coordinate
${Picard} SortSam I=${PATHBAM}"/"${BAMoutsR1} O=${PATHBAM}"/"${BAMSORTsR1} SO=coordinate
${Picard} SortSam I=${PATHBAM}"/"${BAMoutsR2} O=${PATHBAM}"/"${BAMSORTsR2} SO=coordinate


##### Hacer merge de los archivos BAM ########

#Cambio de nombre para el archivo BAM merge
BAMoutm=`echo ${BAMSORTp} | sed 's/_paired_sorted\.bam/_merged\.bam/'`

#Ejecutar Picard para generar el BAM merge
${Picard} MergeSamFiles INPUT=${PATHBAM}"/"${BAMSORTp} INPUT=${PATHBAM}"/"${BAMSORTsR1} INPUT=${PATHBAM}"/"${BAMSORTsR2} OUTPUT=${PATHBAM}"/"${BAMoutm}


###### Agregar readgroups al archivo BAM merge ######

#Cambio de nombre para archivo BAM-RG
BAMoutRG=`echo ${BAMoutm} | sed 's/_merged\.bam/_merged-RG\.bam/'`

#Generacion de ReadGroups (es necesario cambiar RGLB por fecha o quien lo realizo, 
#RGPL en la plataforma que se hizo el experimento, siempre se crea el indice no mover.
RGID=`basename ${Uno} | cut -d '_' -f 1`
RGPU=`basename ${Uno} | cut -d '_' -f 3`
RGSM=`basename ${Uno} | cut -d '_' -f 1,3`

#Ejecutar Picard para agregar readgroups
#El readgroup RGBL debe de ser remplazado para cada experimento
${Picard} AddOrReplaceReadGroups I=${PATHBAM}"/"${BAMoutm} O=${PATHBAM}"/"${BAMoutRG} RGID=${RGID} RGPU=${RGPU} RGLB=2021_ALf RGSM=${RGSM}  RGPL=ILLUMINA CREATE_INDEX=true


#Eliminando archivos ya no necesarios
#rm -r ${PATHBAM}"/"${SAMoutp} ${PATHBAM}"/"${SAMoutsR1} ${PATHBAM}"/"${SAMoutsR2} ${PATHBAM}"/"${BAMoutp} ${PATHBAM}"/"${BAMoutsR1} ${PATHBAM}"/"${BAMoutsR2} ${PATHBAM}"/"${BAMSORTp} ${PATHBAM}"/"${BAMSORTsR1} ${PATHBAM}"/"${BAMSORTsR2}
