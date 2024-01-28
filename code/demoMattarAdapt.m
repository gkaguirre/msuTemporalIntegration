% demoMattarAdapt
%
% Demonstrates non-linear fitting of fMRI data using the forwardModel and a
% custom parameterized model ('mattarAdapt'). This model includes a gain
% parameter for the response to each unique face (vs. the blank intervals),
% a parameter for the effect of making a right sided vs. left sided button
% press in response to the cover task, and two parameters that model a
% carry-over effect of the stimuli. The carry-over effect is based upon the
% Mattar 2016 Current Biology approach, in which a "drifting prior" follows
% the position of stimuli within a 3D face space. The movement of the prior
% is controlled by the adapt mu parameter (which varies between zero and
% unity). The effect of the prior upon the fMRI signal is controlled by an
% adapt gain parameter.
%
% The model also fits the shape of the HRF at each voxel.
%

% Housekeeping
clear
close all

% Whole brain or one voxel?
fitOneVoxel = false;

% The subject ID
subjectID = 'sub-C0103';

% The TR of the fMRI data, in seconds
tr = 2.2;

% The number of unique face stimuli
nFaces = 27;

% Set the typicalGain, which is about 0.1 as we have converted the data to
% proportion change
typicalGain = 0.1;

% Place to save the results
saveDir = fullfile('/Users/aguirre/Desktop',subjectID);
if ~isdir(saveDir)
    mkdir(saveDir);
end

% Get the stimulus files from the eventFile content. This function is
% currently hard-coded to look for the event files from just one subject at
% a fixed location. A more general implementation is obviously needed.
[stimulus,stimTime] = parseEventFiles(subjectID);

% Get the data files; this is also currently hard coded
[data,templateImage] = parseDataFiles(subjectID);

% Pick the voxels to analyze
xyz = templateImage.volsize;
if fitOneVoxel
    % A single voxel that is in the right FFA
    vxs = 83864;
    averageVoxels = true;
else
    % Create a mask of brain voxels
    brainThresh = 2000;
    vxs = find(reshape(templateImage.vol, [prod(xyz), 1]) > brainThresh);
    averageVoxels = false;
end

% Create the model opts, which includes stimLabels and typicalGain
stimLabels = cellfun(@(x) sprintf('face_%02d',str2double(string(x))),num2cell(1:nFaces),'UniformOutput',false);
stimLabels = [stimLabels, 'right-left'];
modelOpts = {'stimLabels',stimLabels,'typicalGain',typicalGain};

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

    % Save a map of the right-left effect size
    newImage = templateImage;
    volVec = results.params(:,28);
    volVec(isnan(volVec)) = 0;
    newImage.vol = reshape(volVec,xyz(1),xyz(2),xyz(3));
    fileName = fullfile(saveDir,[subjectID '_mattarAdapt_rightButton-leftButton.nii']);
    MRIwrite(newImage, fileName);

    % Save a map of the adapt mu parameter
    newImage = templateImage;
    volVec = results.params(:,29);
    volVec(isnan(volVec)) = 0;
    newImage.vol = reshape(volVec,xyz(1),xyz(2),xyz(3));
    fileName = fullfile(saveDir,[subjectID '_mattarAdapt_adaptMu.nii']);
    MRIwrite(newImage, fileName);

    % Save a map of the adapt gain parameter
    newImage = templateImage;
    volVec = results.params(:,30);
    volVec(isnan(volVec)) = 0;
    newImage.vol = reshape(volVec,xyz(1),xyz(2),xyz(3));
    fileName = fullfile(saveDir,[subjectID '_mattarAdapt_adaptGain.nii']);
    MRIwrite(newImage, fileName);

end
