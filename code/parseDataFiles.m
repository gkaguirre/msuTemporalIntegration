function [data,templateImage] = parseDataFiles()

rawDataPath = '/Users/aguirre/Dropbox (Personal)/SZ_TemporalIntegration_fMRI/example_data/derivatives/fMRIprep/sub-C0103/ses-1/func';

dataFileNames = {...
    'sub-C0103_ses-1_task-main_run-4_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz',...
    'sub-C0103_ses-1_task-main_run-5_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz',...
    'sub-C0103_ses-1_task-main_run-6_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz',...
    'sub-C0103_ses-1_task-main_run-7_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz',...
    'sub-C0103_ses-1_task-main_run-8_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz'...
    };

data = [];

for nn = 1:length(dataFileNames)

    fileName = fullfile(rawDataPath,dataFileNames{nn});
    fileName = escapeFileCharacters(fileName);

    thisAcqData = MRIread(fileName);
    % Check if this is the first acquisition. If so, retain an
    % example of the source data to be used as a template to format
    % the output files.
    if nn == 1
        templateImage = thisAcqData;
        templateImage.vol = squeeze(templateImage.vol(:,:,:,1));
        templateImage.nframes = 1;
    end
    thisAcqData = thisAcqData.vol;

    thisAcqData = single(thisAcqData);
    thisAcqData = reshape(thisAcqData, [size(thisAcqData,1)*size(thisAcqData,2)*size(thisAcqData,3), size(thisAcqData,4)]);
    thisAcqData(isnan(thisAcqData)) = 0;

    % Set the first time point to zero as there is some clear effect of not
    % yet reaching steady state magnetization
    thisAcqData(:,1) = thisAcqData(:,2);

    % Store the acquisition data in a cell array
    data{nn} = thisAcqData;

end

end