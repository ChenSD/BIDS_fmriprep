%==========================================================================
%     SPM First-level analysis for preprocessed data by fmriprep
%==========================================================================
%     Based on SPM12
%
%     Writen by Shengdong Chen, ACRLAB, 2019/6/10
%==========================================================================

%% Prepare BIDS dirs
% Inputdirs
clc;clear
BIDSdir = '/data/fMRI/fmriprep/'; % root inputdir for sublist
multiconditiondir='/data/fMRI/firstlevel/multicondition';
TR = 1.5;     % Repetition time, in seconds
unit='secs'; % onset times in secs (seconds) or scans (TRs)
dissub= ["18","39"]; % IDs of subject who should be discarded

% Outputdirs
outputdir='/data/fMRI/firstlevel2/task_post' ;  % root outputdir for sublist
sublist=dir(fullfile(BIDSdir,'sub*'));
isFile   = [sublist.isdir];
sublist = {sublist(isFile).name};
spm_mkdir(outputdir,char(sublist)); % for >R2016b, use B = string(A) 

%% Loop for sublist
spm('Defaults','fMRI'); %Initialise SPM fmri
spm_jobman('initcfg');  %Initialise SPM batch mode

fun_name_gz='_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz';
fun_name_nii='_space-MNI152NLin2009cAsym_desc-preproc_bold.nii';

for i=1:length(sublist)
    
	subname=sublist{i};
	subid=subname(5:6);
    if ismember(subid,dissub)   % whether subid belongs to dissub
        continue;
    end
	
    %% Inputdirs and files (Default)
    sub_inputdir=fullfile(BIDSdir,subname,'func');
    func_run2=[sub_inputdir,filesep,subname,'_task-','run2',fun_name_gz];
    func_nii_run2=[sub_inputdir,filesep,'sm6',subname,'_task-','run2',fun_name_nii];
%     if ~exist(func_nii_run2,'file'), gunzip(func_run2) 
%     end
    
    func_run3=[sub_inputdir,filesep,subname,'_task-','run3',fun_name_gz];
    func_nii_run3=[sub_inputdir,filesep,'sm6',subname,'_task-','run3',fun_name_nii];
%     if ~exist(func_nii_run3,'file'), gunzip(func_run3)
%     end   
   
    %% Output dirs where you save SPM.mat
    subdir=fullfile(outputdir,subname);
    if exist(fullfile(subdir,'SPM.mat'),'file'), continue
    end
    
	%% Basic parameters
    matlabbatch{1}.spm.stats.fmri_spec.dir = {subdir};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = unit; % 'secs' or 'scans'
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;
    
    %% Load input files for task specilized (run2 and 3)
     % run2---------------------------------------------------------
    run2_scans = spm_select('Expand',func_nii_run2);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = cellstr(run2_scans);
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {});
    % Multicondition file
    multicondition_file=[multiconditiondir,filesep,subname,'-run2.mat'];
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi = {multicondition_file}; % e.g., subinput_dir/sub01-run1.mat
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).regress = struct('name', {}, 'val', {});
    % Confounds file
    confounds_run2=spm_load([sub_inputdir,filesep,subname,'_task-','run2','_desc-confounds_regressors.tsv'])  ; % e.g., subinput_dir/sub01_task-run1_desc*.tsv
    confounds_matrix_run2=[confounds_run2.a_comp_cor_00,confounds_run2.a_comp_cor_01,confounds_run2.a_comp_cor_02,confounds_run2.a_comp_cor_03, confounds_run2.a_comp_cor_04,confounds_run2.a_comp_cor_05,...
        confounds_run2.trans_x, confounds_run2.trans_y, confounds_run2.trans_z,confounds_run2.rot_x,confounds_run2.rot_y,confounds_run2.rot_z];
    confounds_name_run2=[sub_inputdir,filesep,subname,'_task-','run2','_acomcorr.txt'];
    if ~exist(confounds_name_run2,'file'), dlmwrite(confounds_name_run2,confounds_matrix_run2) % e.g., sub-01_task-run1_acomcorr.txt
    end
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).multi_reg = {confounds_name_run2}; %
    matlabbatch{1}.spm.stats.fmri_spec.sess(1).hpf = 128; % High-pass filter (hpf) without using consine
      
	%% run3 ------------------------------------------
    run3_scans=spm_select('Expand',func_nii_run3);
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).scans = cellstr(run3_scans);
    %multicondition file
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi = {[multiconditiondir,filesep,subname,'-run3.mat']};
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).regress = struct('name', {}, 'val', {});
    %confound file
    confounds_run3=spm_load([sub_inputdir,filesep,subname,'_task-','run3','_desc-confounds_regressors.tsv'])  ; % e.g., subinput_dir/sub01_task-run1_desc*.tsv
    confounds_matrix_run3=[confounds_run3.a_comp_cor_00,confounds_run3.a_comp_cor_01,confounds_run3.a_comp_cor_02,confounds_run3.a_comp_cor_03, confounds_run3.a_comp_cor_04,confounds_run3.a_comp_cor_05,...
        confounds_run3.trans_x, confounds_run3.trans_y, confounds_run3.trans_z,confounds_run3.rot_x,confounds_run3.rot_y,confounds_run3.rot_z];
    confounds_name_run3=[sub_inputdir,filesep,subname,'_task-','run3','_acomcorr.txt'];
    if ~exist(confounds_name_run3,'file'), dlmwrite(confounds_name_run3,confounds_matrix_run3) % e.g., sub-01_task-run1_acomcorr.txt
    end    
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).multi_reg = {confounds_name_run3}; %confounds_name_run3
    matlabbatch{1}.spm.stats.fmri_spec.sess(2).hpf = 128;
	
	%% Model  (Default)
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';
    
    %% Model estimation (Default)
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep;
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tname = 'Select SPM.mat';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(1).name = 'filter';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(1).value = 'mat';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(2).name = 'strtype';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).tgt_spec{1}(2).value = 'e';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).sname = 'fMRI model specification: SPM.mat File';
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).src_exbranch = substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1});
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1).src_output = substruct('.','spmmat');
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
    
    
    %% Contrasts
    % Default
    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep;
    matlabbatch{3}.spm.stats.con.spmmat(1).tname = 'Select SPM.mat';
    matlabbatch{3}.spm.stats.con.spmmat(1).tgt_spec{1}(1).name = 'filter';
    matlabbatch{3}.spm.stats.con.spmmat(1).tgt_spec{1}(1).value = 'mat';
    matlabbatch{3}.spm.stats.con.spmmat(1).tgt_spec{1}(2).name = 'strtype';
    matlabbatch{3}.spm.stats.con.spmmat(1).tgt_spec{1}(2).value = 'e';
    matlabbatch{3}.spm.stats.con.spmmat(1).sname = 'Model estimation: SPM.mat File';
    matlabbatch{3}.spm.stats.con.spmmat(1).src_exbranch = substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1});
    matlabbatch{3}.spm.stats.con.spmmat(1).src_output = substruct('.','spmmat');
    
    % Set contrasts of interest. For example, if you want to get the effects of negative emotion arousal,
    % you can define the contrast watch_negative VS. watch_neutral by inputing a vector [1 -1].
    % Condition1=beta1=face  Condition2=beta2=think
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'sad';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.convec = [1];
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'both'; %'none';
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'neutral';
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.convec = [0 1];
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'both';
    %
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'sad_neutral';
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.convec = [1 -1];
    matlabbatch{3}.spm.stats.con.consess{3}.tcon.sessrep = 'both';
    matlabbatch{3}.spm.stats.con.delete = 0;
    
	%% Run matlabbatch jobs
    spm_jobman('run',matlabbatch);

end

