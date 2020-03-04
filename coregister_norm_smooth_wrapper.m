clc; clear all;

% List of open inputs
folders = dir('/mnt/praxic/pdnetworks2/subjects');

% initialize error log
errorlog = {}; ctr=1;
conditions = ['mrest'];
%['mcvsa'; 'mcvsm'; 'mrest'];

numRuns= 0;
subjs = {};
for j = folders'
    if numel(j.name) == 6
        numRuns= numRuns + 1; 
        subjs(numRuns,:) = {j.name};
    end
end

failedSubjs = {};
numFail = 0;

nrun = numRuns;
for crun = 1:nrun
    curSub = subjs{crun,:};
    disp(curSub)
    
    for condType = 1:numel(conditions(:,1))
        
        currentDir = strcat('/mnt/praxic/pdnetworks2/subjects/', curSub, '/session1/', conditions(condType,:) , '/s_dt_dsp_dn_mcf.nii');
        if exist(currentDir, 'file') == 2     
            
            disp(conditions(condType,:))

            anatFile = {strcat('/mnt/praxic/pdnetworks2/subjects/', curSub, '/session1/mprage/T1_brain.nii,1')};
            regFile  = {strcat('/mnt/praxic/pdnetworks2/subjects/', curSub, '/session1/', conditions(condType,:) , '/s_dt_dsp_dn_mcf.nii,1')};

            numScans = numel(dir(fullfile('/mnt/praxic/pdnetworks2/subjects/', curSub, '/session1/', conditions(condType,:), [conditions(condType,:) '_e001_mc.mat'],'/MAT*')));
            for curFiles = 1:numScans
               modifiedFiles{curFiles,:} = strcat('/mnt/praxic/pdnetworks2/subjects/', curSub, '/session1/', conditions(condType,:) , '/s_dt_dsp_dn_mcf.nii,', int2str(curFiles));     
            end


            try 
                batch_output = coregister_norm_smooth_job(anatFile, regFile, modifiedFiles);

            catch err
                errorlog{ctr,1} = crun;
                errorlog{ctr,2} = condType;
                errorlog{ctr,3} = err;
                ctr = ctr + 1;    
                continue;
            end
            
        else
            disp(['There is not fMRI data for ', curSub])
            numFail = numFail + 1;
            failedSubjs(numFail,:) = cellstr(curSub);
        end
    end
end

