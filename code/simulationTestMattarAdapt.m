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
rawDataPath = '/Users/aguirre/Desktop/SZ_TemporalIntegration_fMRI/example_data/derivatives/fMRIprep/sub-C0103/ses-1/func';
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
rawEventPath = '/Users/aguirre/Desktop/SZ_TemporalIntegration_fMRI/example_data/rawdata/sub-C0103/ses-1/func';
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
[data,templateImage] = parseDataFiles(rawDataPath,dataFileNames,0);

% Keep just one voxel of data for this simulation
for ii = 1:length(data)
    data{ii} = data{ii}(1,:);
end

% Get the nuisanceVars
nuisanceVars = parseNuisanceVars(rawDataPath,nuisanceFileNames,covarSet);

% Create the model opts, which includes stimLabels and typicalGain. The
% paraSD key-value controls how varied the HRF solutions can be. A value of
% 3 is fairly conservative and will keep the HRFs close to a canonical
% shape. This is necessary for the current experiment as the stimulus
% sequence does not uniquely constrain the temporal delay in the HRF.
stimLabels = {'blockOn','firstFace','repeatFace','right-left'};
modelOpts = {'stimLabels',stimLabels,'typicalGain',typicalGain,...
    'paraSD',3,'polyDeg',polyDeg};

% Define the modelClass
modelClass = 'mattarAdapt';

model = mattarAdapt(data,stimulus,tr,...
    'stimTime',stimTime,modelOpts{:});

% Define the model parameters for the simulation
x = model.initial;

% Set the gain parameters to have a substanital effect of blockOn, and then
% no effect of firstface, pure repeat, or the left-right effect
x(1)=0.5;
x(2:4)=0;

% Set the mu to zero (pure adapt), and the stimulus history gain to 0.1
x(5)=0;
x(6)=0.3;

% Create simulated data for a voxel
datats = model.forward(x);

% Add some noise, and place this simulated time series back into data 
datats = datats + randn(size(datats))*range(datats)/5;
acqLength = size(data{1},2);
for ii = 1:length(data)
    data{ii}(1,:) = datats((ii-1)*acqLength+1:ii*acqLength);
end

% Call the forwardModel
results = forwardModel(data,stimulus,tr,...
    'stimTime',stimTime,...
    'verbose',true,...
    'modelClass',modelClass,...
    'modelOpts',modelOpts);



