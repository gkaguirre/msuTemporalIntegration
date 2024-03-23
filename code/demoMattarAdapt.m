% demoMattarAdapt
%
% Demonstrates non-linear fitting of fMRI data using the forwardModel and a
% custom parameterized model ('mattarAdapt'). This model includes a gain
% parameter for the response to each unique face (vs. the blank intervals),
% the effect of being the first face after the blank period, the effect of
% having a perfect repetition of face identity, and a parameter for the
% effect of making a right sided vs. left sided button press in response to
% the cover task, and two parameters that model a carry-over effect of the
% stimuli. The carry-over effect is based upon the Mattar 2016 Current
% Biology approach, in which a "drifting prior" follows the position of
% stimuli within a 3D face space. The movement of the prior is controlled
% by the adapt mu parameter (which varies between zero and unity). The
% effect of the prior upon the fMRI signal is controlled by an adapt gain
% parameter.
%
% The model also fits the shape of the HRF at each voxel.
%

% Housekeeping
clear
close all

% Whole brain or one voxel?
fitOneVoxel = true;

% The smoothing kernel for the fMRI data in space
smoothSD = 0.75;

% The polynomial degree used for high-pass filtering of the timeseries
polyDeg = 1;

% The subject ID
subjectID = 'sub-C0103';

% Place to save the results files
saveDir = fullfile('/Users/aguirre/Desktop',subjectID);

% This is the set of covariates returned by fmriprep that we will include
% as nuisance variables in the regression
covarSet = {'csf','csf_derivative1','white_matter','white_matter_derivative1','framewise_displacement'};

% Paths and filenames for the data
rawDataPath = '/Users/aguirre/Dropbox (Personal)/SZ_TemporalIntegration_fMRI/example_data/derivatives/fMRIprep/sub-C0103/ses-1/func';
dataFileNames = {...
    'sub-C0103_ses-1_task-main_run-4_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz',...
    'sub-C0103_ses-1_task-main_run-5_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz',...
    'sub-C0103_ses-1_task-main_run-6_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz',...
    'sub-C0103_ses-1_task-main_run-7_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz',...
    'sub-C0103_ses-1_task-main_run-8_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz'...
    };

nuisanceFileNames = {...
    'sub-C0103_ses-1_task-main_run-4_desc-confounds_timeseries.tsv',...
    'sub-C0103_ses-1_task-main_run-5_desc-confounds_timeseries.tsv',...
    'sub-C0103_ses-1_task-main_run-6_desc-confounds_timeseries.tsv',...
    'sub-C0103_ses-1_task-main_run-7_desc-confounds_timeseries.tsv',...
    'sub-C0103_ses-1_task-main_run-8_desc-confounds_timeseries.tsv'...
    };


% Paths and filenames for the events
rawEventPath = '/Users/aguirre/Dropbox (Personal)/SZ_TemporalIntegration_fMRI/example_data/rawdata/sub-C0103/ses-1/func';
eventFileNames = {...
    'sub-C0103_ses-1_task-main_run-4_events.tsv',...
    'sub-C0103_ses-1_task-main_run-5_events.tsv',...
    'sub-C0103_ses-1_task-main_run-6_events.tsv',...
    'sub-C0103_ses-1_task-main_run-7_events.tsv',...
    'sub-C0103_ses-1_task-main_run-8_events.tsv'...
    };


%% I recommend not changing parameters past this point

% The TR of the fMRI data, in seconds
tr = 2.2;

% The number of unique face stimuli
nFaces = 27;

% Set the typicalGain, which is about 0.1 as we have converted the data to
% proportion change
typicalGain = 0.1;

% Place to save the results
if ~isfolder(saveDir)
    mkdir(saveDir);
end

% Get the stimulus files from the eventFile content.
[stimulus,stimTime] = parseEventFiles(rawEventPath,eventFileNames);

% Get the data files
[data,templateImage] = parseDataFiles(rawDataPath,dataFileNames,smoothSD);

% Get the nuisanceVars
nuisanceVars = parseNuisanceVars(rawDataPath,nuisanceFileNames,covarSet);

% Pick the voxels to analyze
xyz = templateImage.volsize;
if fitOneVoxel
    % A single voxel that is in the right FFA
    vxs = 83793;
    averageVoxels = true;
else
    % Create a mask of brain voxels
    brainThresh = 2000;
    vxs = find(reshape(templateImage.vol, [prod(xyz), 1]) > brainThresh);
    averageVoxels = false;
end

% Create the model opts, which includes stimLabels and typicalGain. The
% paraSD key-value controls how varied the HRF solutions can be. A value of
% 3 is fairly conservative and will keep the HRFs close to a canonical
% shape. This is necessary for the current experiment as the stimulus
% sequence does not uniquely constrain the temporal delay in the HRF.
stimLabels = cellfun(@(x) sprintf('face_%02d',str2double(string(x))),num2cell(1:nFaces),'UniformOutput',false);
stimLabels = [stimLabels,'firstFace','repeatFace','right-left'];
modelOpts = {'stimLabels',stimLabels,'typicalGain',typicalGain,...
    'paraSD',3,'polyDeg',polyDeg,'nuisanceVars',nuisanceVars};

% Define the modelClass
modelClass = 'mattarAdapt';

% Call the forwardModel
results = forwardModel(data,stimulus,tr,...
    'stimTime',stimTime,...
    'vxs',vxs,...
    'averageVoxels',averageVoxels,...
    'verbose',true,...
    'modelClass',modelClass,...
    'modelOpts',modelOpts);

% Show the results figures
figFields = fieldnames(results.figures);
if ~isempty(figFields)
    for ii = 1:length(figFields)
        figHandle = struct2handle(results.figures.(figFields{ii}).hgS_070000,0,'convert');
        figHandle.Visible = 'on';
    end
end

% Save some files if we processed the whole brain
if ~fitOneVoxel

    % Save the results
    fileName = fullfile(saveDir,[subjectID '_mattarAdaptResults.mat']);
    save(fileName,'results');

    % Save the template image
    fileName = fullfile(saveDir,[subjectID '_epiTemplate.nii']);
    MRIwrite(templateImage, fileName);

    % Save a map of R2 values
    newImage = templateImage;
    volVec = results.R2;
    volVec(isnan(volVec)) = 0;
    newImage.vol = reshape(volVec,xyz(1),xyz(2),xyz(3));
    fileName = fullfile(saveDir,[subjectID '_mattarAdapt_R2.nii']);
    MRIwrite(newImage, fileName);

    % Save maps for the various param vals
    paramLabels = {'firstFace','repeatFace','right-left','adaptMu','adaptGain'};
    paramIdx = nFaces+1:nFaces+length(paramLabels);
    for ii = 1:length(paramLabels)
        newImage = templateImage;
        volVec = results.params(:,paramIdx(ii));
        volVec(isnan(volVec)) = 0;
        newImage.vol = reshape(volVec,xyz(1),xyz(2),xyz(3));
        fileName = fullfile(saveDir,[subjectID '_mattarAdapt_' paramLabels{ii} '.nii']);
        MRIwrite(newImage, fileName);
    end

end
