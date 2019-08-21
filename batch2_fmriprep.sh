#!/bin/bash

# set IO

niidir=/data/fMRI/rawnii # input dir
prepre_dir=/data/fMRI/ # output dir ~~~fmriprep will generate a folder named fmriprep under outdir
work_dir=/data/fMRI/work_dir # work dir


# sublist

# parallel preprocessing

cd ${niidir} # Go to directory with "sub-*/" subfolders
    
fmriprep-docker ${niidir} ${prepre_dir} participant \
   --participant-label {41..59}   \
   --fs-license-file /data/fMRI/freesurfer_license.txt \
   --ignore slicetiming \
   --use-aroma \
   --use-syn-sdc \
   --work-dir ${work_dir}  \
   --fs-no-reconall


