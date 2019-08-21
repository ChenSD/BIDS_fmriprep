#!/bin/bash

# set IO

bids_dir=/data/fMRI/rawnii # input BIDS dir (raw nii data)
output_dir=/data/fMRI/MRIQC # output dir for MRIQC results
work_dir=/tmp/work_dir # work dir

# parallel preprocessing

cd ${bids_dir} # Go to directory with "sub-*/" subfolders
    

docker run -it --rm \
   -v ${bids_dir}:/data:ro \
   -v ${output_dir}:/out   \
   poldracklab/mriqc:latest /data /out group \
   --no-sub \
   --work-dir ${work_dir}  \
   --modalities bold




