%-----------------------------------------------------------------------
% Registers mprage to first output from tedana, then normalizes the files
%-----------------------------------------------------------------------
function [matlabbatch] = coregister_norm_smooth_job(anatFile, regFile, modifiedFiles)
    %% register mprage
    matlabbatch{1}.spm.spatial.coreg.estwrite.ref = regFile;
    matlabbatch{1}.spm.spatial.coreg.estwrite.source = anatFile;
    matlabbatch{1}.spm.spatial.coreg.estwrite.other = {''};
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
    matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
    matlabbatch{2}.spm.spatial.normalise.estwrite.subj.vol = anatFile;
    %% normalize 
    matlabbatch{2}.spm.spatial.normalise.estwrite.subj.resample = modifiedFiles;
    matlabbatch{2}.spm.spatial.normalise.estwrite.eoptions.biasreg = 0.0001;
    matlabbatch{2}.spm.spatial.normalise.estwrite.eoptions.biasfwhm = 60;
    matlabbatch{2}.spm.spatial.normalise.estwrite.eoptions.tpm = {'/usr/local/spm12/tpm/TPM.nii'};
    matlabbatch{2}.spm.spatial.normalise.estwrite.eoptions.affreg = 'mni';
    matlabbatch{2}.spm.spatial.normalise.estwrite.eoptions.reg = [0 0.001 0.5 0.05 0.2];
    matlabbatch{2}.spm.spatial.normalise.estwrite.eoptions.fwhm = 0;
    matlabbatch{2}.spm.spatial.normalise.estwrite.eoptions.samp = 3;
    matlabbatch{2}.spm.spatial.normalise.estwrite.woptions.bb = [-78 -112 -70
                                                                 78 76 85];
    matlabbatch{2}.spm.spatial.normalise.estwrite.woptions.vox = [2 2 2];
    matlabbatch{2}.spm.spatial.normalise.estwrite.woptions.interp = 4;
    matlabbatch{2}.spm.spatial.normalise.estwrite.woptions.prefix = 'w';
    
    %% smooth
    matlabbatch{3}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Estimate & Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
    matlabbatch{3}.spm.spatial.smooth.fwhm = [8 8 8];
    matlabbatch{3}.spm.spatial.smooth.dtype = 0;
    matlabbatch{3}.spm.spatial.smooth.im = 0;
    matlabbatch{3}.spm.spatial.smooth.prefix = 's';
    
    
    spm('defaults', 'FMRI');

    spm_jobman('run', matlabbatch);
done
