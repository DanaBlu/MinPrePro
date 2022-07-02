#! user/bin/bash

#basecalling

guppy_basecaller -i fast5_pass/ -r -s run1_basecalling -c dna_r9.4.1_e8.1_hac.cfg -x auto --do_read_splitting


#demultiplexing

guppy_barcoder -i run1_basecalling/pass/ -r -s run1_demultiplexing --barcode_kits SQK-NBD112-24 -x auto

#merge demultiplexed files

mkdir run1_demultiplexing_merged
cd run1_demultiplexing 

for i in barcode*; do
        cat ${i}/*.fastq > ../run1_demultiplexing_merged/${i}.fastq 
done


#pychopper
# files
cd ../run1_pychopper

input=../run1_demultiplexing_merged # input directory with all merged FASTQ files, 1 for each barcode or single DRS run guppy_basecaller/barcode

# perform pychopper for all cDNA and (PCR)-cDNA files

for file in ${input}/*.fastq
do 

  # folder and filenames
  f_ex=${file##*/}
  foldername=${f_ex%%.*}
  filename=${f_ex%%.*}
  
  # make directories
  mkdir ${foldername}
  output=${foldername}/${filename}

  # perform pychopper using precomputed q
  cdna_classifier.py \
  -r ${output}_report_run1.pdf \
  -m edlib \
  -b custom_primers_single.fasta \
  -c primer_config_single.txt \
  -u ${output}_unclassified_run1.fastq \
  -w ${output}_rescued_run1.fastq \
  $file \
  ${output}_pychopper_output_run1.fastq
done

#sort unclassified fastq files in one folder

mkdir run1_unclassified

for i in barcode*; do
        cp ${i}/*_unclassified_run1.fastq run1_unclassified 
done

#pychopper for unclassified 
# files
input=run1_unclassified # input directory with all merged FASTQ files, 1 for each barcode or single DRS r>

# perform pychopper for all cDNA and (PCR)-cDNA files

for file in ${input}/*.fastq
do 

  # folder and filenames
  f_ex=${file##*/}
  foldername=$(echo $f_ex | cut -d"_" -f 1)
  filename=$(echo $f_ex | cut -d"_" -f 1)_rescued
  
  # make directories
 mkdir run1_rescued 
 mkdir run1_rescued/${foldername}
  output=run1_rescued/${foldername}/${filename}
 

  # perform pychopper using precomputed q
  cdna_classifier.py \
  -r ${output}_report_run1.pdf \
  -m edlib \
  -b custom_primers_single.fasta \
  -c primer_config_single.txt \
  -x rescue \
  -u ${output}_unclassified_run1.fastq \
  -w ${output}_rescued_run1.fastq \
  $file \
  ${output}_pychopper_output_run1.fastq
done


#merge all pychopper files (normal & rescued)

mkdir run1_pychopper_merged     
mkdir run1_pychopper_merged/merged_normal
mkdir run1_pychopper_merged/merged_rescued


for i in barcode*; do
        cat ${i}/*output*.fastq > run1_pychopper_merged/merged_normal/${i}.fastq 
done


cd run1_rescued   

for i in barcode*; do
        cat ${i}/*output*.fastq > ../run1_pychopper_merged/merged_rescued/${i}.fastq
done


#output reads

cd ../run1_pychopper_merged

normal=($(cat merged_normal/*.fastq | wc -l)/4)
rescued=($(cat merged_rescued/*.fastq | wc -l)/4)
(( all = normal + rescued ))

echo Number of basecalled, demultiplexed, trimmed and reorientated reads:
echo $all

echo Number of basecalled, demultiplexed, trimmed and reorientated reads per barcode:
for i in merged_normal/barcode*.fastq; do
        a=($(cat ${i} | wc -l)/4)
        for f in merged_rescued/barcode*.fastq; do
                b=($(cat ${f} | wc -l)/4)
        done
        ((c=a+b))
v=${i##*/}
v=${v%%.*}
echo ${v}
echo $c
done
