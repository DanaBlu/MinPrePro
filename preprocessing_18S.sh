#! user/bin/bash

#basecalling
guppy_basecaller -i fast5_pass/ -r -s basecalling -c dna_r9.4.1_e8.1_hac.cfg -x auto --do_read_splitting

#demultiplexing
guppy_barcoder -i basecalling/pass/ -r -s demultiplexing --barcode_kits SQK-NBD112-24 -x auto

#merge demultiplexed files
mkdir demultiplexing_merged
cd demultiplexing 

for i in barcode*; do
        cat ${i}/*.fastq > ../demultiplexing_merged/${i}.fastq 
done

#pychopper
cd ..
mkdir pychopper
cd pychopper

#create primer fasta file
echo ">SSP
AATCTGGTTGATCCTGCCAG
>VNP
TGATCCTTCTGCAGGTTCACCTA" > custom_primers_single.fasta

#create primer config file
echo "+:SSP,-VNP|-:VNP,-SSP" > primer_config_single.txt

input=../demultiplexing_merged # input directory with all merged FASTQ files

# perform pychopper
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
  pychopper \
  -r ${output}_report.pdf \
  -m edlib \
  -b custom_primers_single.fasta \
  -c primer_config_single.txt \
  -u ${output}_unclassified.fastq \
  -w ${output}_rescued.fastq \
  $file \
  ${output}_pychopper_output.fastq
done

#sort unclassified fastq files in one folder
mkdir unclassified

for i in barcode*; do
        cp ${i}/*_unclassified.fastq unclassified 
done

#pychopper for unclassified 
input=unclassified # input directory with all merged FASTQ files

# perform pychopper
for file in ${input}/*.fastq
do 

  # folder and filenames
  f_ex=${file##*/}
  foldername=$(echo $f_ex | cut -d"_" -f 1)
  filename=$(echo $f_ex | cut -d"_" -f 1)_rescued
  
  # make directories
  mkdir rescued
  mkdir rescued/${foldername}
  output=rescued/${foldername}/${filename}
 
  # perform pychopper rescue 
  pychopper \
  -r ${output}_report.pdf \
  -m edlib \
  -b custom_primers_single.fasta \
  -c primer_config_single.txt \
  -x rescue \
  -u ${output}_unclassified.fastq \
  -w ${output}_rescued.fastq \
  $file \
  ${output}_pychopper_output.fastq
done

#merge all pychopper files (normal & rescued)
mkdir pychopper_merged     
mkdir pychopper_merged/merged_normal
mkdir pychopper_merged/merged_rescued

for i in barcode*; do
        cat ${i}/*output*.fastq > pychopper_merged/merged_normal/${i}.fastq 
done

cd rescued   

for i in barcode*; do
        cat ${i}/*output*.fastq > ../pychopper_merged/merged_rescued/${i}.fastq
done

#output reads
cd ../pychopper_merged

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
done > ../../reads.txt

#Merge normal & rescued pychopper reads
mkdir ../../final_output


for i in merged_normal/barcode*.fastq; do
	cat ${i} > ../../final_output/${i##*/}
done

for f in merged_rescued/barcode*.fastq; do
	cat ${f} >> ../../final_output/${f##*/}
done
