

% Place to save the results
saveDir = '/Users/aguirre/Desktop';

% The TR of the fMRI data, in seconds
tr = 2.2;

% Get the stimulus files from the eventFile content. This function is
% currently hard-coded to look for the event files from just one subject at
% a fixed location. A more general implementation is obviously needed.
[stimulus,stimTime] = parseEventFiles();

% Get the data files; this is also currently hard coded
[data,templateImage] = parseDataFiles();

% Create a mask of brain voxels
brainThresh = 2000;
xyz = templateImage.volsize;
vxs = find(reshape(templateImage.vol, [prod(xyz), 1]) > brainThresh);

% Create the stimLabels
nFaces = 27;
stimLabels = cellfun(@(x) sprintf('face_%02d',str2double(string(x))),num2cell(1:nFaces),'UniformOutput',false);
stimLabels = [stimLabels, 'right-left'];
modelOpts = {'stimLabels',stimLabels};

% Define the modelClass
modelClass = 'mattarAdapt';

% Call the forwardModel
results = forwardModel(data,stimulus,tr,...
    'stimTime',stimTime,...
    'vxs',vxs,...
    'averageVoxels',false,...
    'verbose',true,...
    'modelClass',modelClass,...
    'modelOpts',modelOpts);

% Save the results
fileName = fullfile(saveDir,'mattarAdaptResults.mat');
save(fileName,'results');

% Show the results figures
figFields = fieldnames(results.figures);
if ~isempty(figFields)
    for ii = 1:length(figFields)
        figHandle = struct2handle(results.figures.(figFields{ii}).hgS_070000,0,'convert');
        figHandle.Visible = 'on';
    end
end
