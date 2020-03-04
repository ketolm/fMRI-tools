#!/bin/bash

# This is the Tedana pre-processing pipeline for the Simulatenous EEG-fMRI RO1

source activate ketolmpraxic

PROJ_HOME=/mnt/praxic/pdnetworks2/subjects
FSLDIR=/usr/share/fsl/5.0
AFNIDIR=/usr/lib/afni/bin
TEDANADIR=/mnt/home/ketolm/anaconda3/envs/ketolmpraxic/bin

SESSION=session1

cd ${PROJ_HOME}

CONDITIONS=('mcvsa' 'mcvsm' 'mrest')

# HAVEN'T DONE SUBJECTS STARTING WITH 9 YET
for d in `ls -d /mnt/praxic/pdnetworks2/subjects/[1][5-9][0-9][0-9][0-9][0-9]`; do

    SUBJ=$(basename ${d})
    echo ${SUBJ}
    
    for condTYPE in ${CONDITIONS[@]}; do

	condPATH=${SUBJ}/${SESSION}/${condTYPE}
	
	##1. Motion correction 
	# create reference volume
	echo Motion correction
	${FSLDIR}/bin/fslroi ${condPATH}/${condTYPE}_e001.nii.gz ${condPATH}/refvol_e001.nii.gz 0 1;\

	#motion correct firt echo
	${FSLDIR}/bin/mcflirt -in ${condPATH}/${condTYPE}_e001.nii.gz -out ${condPATH}/${condTYPE}_e001_mc -reffile ${condPATH}/refvol_e001.nii.gz -rmsrel -rmsabs -spline_final -mats -plots;\

	# split echo 2 and 3 into separate 3D volumes
	${FSLDIR}/bin/fslsplit ${condPATH}/${condTYPE}_e002.nii.gz e002_on_;\
	${FSLDIR}/bin/fslsplit ${condPATH}/${condTYPE}_e003.nii.gz e003_on_;\

	# apply tranformation calculated by mcflirt to each 3D volume for echo 2/3
	for ii in `ls -f e002_on_*.nii.gz`; do
	    echo ${ii};\
	    MM=`echo "${ii}" | awk -F'[_.]' '{print $3}'`;\
	    echo ${MM[@]};\
	    ${FSLDIR}/bin/flirt -in ${ii} -ref ${condPATH}/refvol_e001.nii.gz -applyxfm -init ${condPATH}/${condTYPE}_e001_mc.mat/MAT_${MM} -out e002_on_mc_${MM}.nii.gz;\
	done
	echo "Made it to e003"
	for ii in `ls -f e003_on_*.nii.gz`; do
	    echo ${ii};\
	    MM=`echo "${ii}" | awk -F'[_.]' '{print $3}'`;\
	    echo ${MM[@]};\
	    ${FSLDIR}/bin/flirt -in ${ii} -ref ${condPATH}/refvol_e001.nii.gz -applyxfm -init ${condPATH}/${condTYPE}_e001_mc.mat/MAT_${MM} -out e003_on_mc_${MM}.nii.gz;\
	done

	#merge the files back to 1 4D volumes for echo 2/3
	${FSLDIR}/bin/fslmerge -t ${condPATH}/${condTYPE}_e002_mc.nii.gz e002_on_mc_*.nii.gz;\
	${FSLDIR}/bin/fslmerge -t ${condPATH}/${condTYPE}_e003_mc.nii.gz e003_on_mc_*.nii.gz;\
	rm -rf e002_on_*.nii.gz e003_on_*.nii.gz

	##2. Multi-echo denoising
	# create a functional mask
	echo Multi-echo denoising
	${FSLDIR}/bin/bet ${condPATH}/refvol_e001.nii.gz ${condPATH}/fbrain_on -m;\
	${TEDANADIR}/tedana -d ${condPATH}/${condTYPE}_e001_mc.nii.gz ${condPATH}/${condTYPE}_e002_mc.nii.gz ${condPATH}/${condTYPE}_e003_mc.nii.gz -e 9.5 27.5 45.5 --mask ${condPATH}/fbrain_on_mask.nii.gz --png --out-dir ${condPATH};\

	##3. Motion outlier detection and despiking
	echo Despiking
	${AFNIDIR}/3dDespike -prefix ${condPATH}/dsp_dn_mcf_on.nii.gz -ssave ${condPATH}/spikeyness.nii.gz ${condPATH}/dn_ts_OC.nii.gz

	##4. Detrending, low pass at 1/(Fre in Hz*TR*2.35)
	echo Detrending
	#calculate DC
	${FSLDIR}/bin/fslmaths ${condPATH}/dsp_dn_mcf_on.nii.gz -Tmean ${condPATH}/DC.nii.gz;\
	#band pass filter data and add back DC component
	${FSLDIR}/bin/fslmaths ${condPATH}/dsp_dn_mcf_on.nii.gz -bptf 17 -1 -add ${condPATH}/DC.nii.gz ${condPATH}/dt_dsp_dn_mcf_on.nii.gz;\

	##5. Smoothing (FWHM/2.35) FWHM of 6mm
	echo Smoothing
	${FSLDIR}/bin/fslmaths ${condPATH}/dt_dsp_dn_mcf_on.nii.gz -s 2.55 ${condPATH}/s_dt_dsp_dn_mcf.nii.gz;\

    done

done

