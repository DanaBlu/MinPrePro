#! user/bin/bash

guppy_basecaller -i fast5_pass/ -r -s run1_basecalling_1d -c dna_r9.4.1_e8.1_hac.cfg -x auto --do_read_splitting

guppy_basecaller_duplex –-input_path fast5_pass/ -r –-save_path run1_basecalling_duplex_guppy -c dna_r9.4.1_e8.1_hac.cfg -x auto –-duplex_pairing_mode from_1d_summary –-duplex_pairing_file run1_basecalling/sequencing_summary --do_read_splitting

guppy_basecaller_duplex –-input_path fast5_pass/ -r –-save_path run1_basecalling_duplex_minknow -c dna_r9.4.1_e8.1_hac.cfg -x auto –-duplex_pairing_mode from_1d_summary –-duplex_pairing_file sequenc-ing_summary_FAR74699_6bfe3c4d --do_read_splitting

