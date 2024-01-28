function [stimulus,stimTime] = parseEventFiles()

rawDataPath = '/Users/aguirre/Dropbox (Personal)/SZ_TemporalIntegration_fMRI/example_data/rawdata/sub-C0103/ses-1/func';

eventFileNames = {...
    'sub-C0103_ses-1_task-main_run-4_events.tsv',...
    'sub-C0103_ses-1_task-main_run-5_events.tsv',...
    'sub-C0103_ses-1_task-main_run-6_events.tsv',...
    'sub-C0103_ses-1_task-main_run-7_events.tsv',...
    'sub-C0103_ses-1_task-main_run-8_events.tsv'...
    };

% The number of events per eventFile
nAcqs = length(eventFileNames);
nEvents = 147;
nUniqueFaces = 27;
nStimMatRows = nUniqueFaces + 4;
preStimTimeSecsRaw = 30; % The period to model prior to the presentation of the first event

% A pattern used to find the face identity index within the stimulus name
pat = digitsPattern(1,2);

% Grab the temporal support from these files and use this to figure out the
% deltaT for the stimuli, and the start time of stimulus presentation
for ee = 1:length(eventFileNames)

    % Get this eventTable
    fileName = fullfile(rawDataPath,eventFileNames{ee});
    eventStruct = tdfread(fileName);

    % Get the raw event times
    if ee == length(eventFileNames)
        % Handle the special case of the last acquisition, that had one fewer
        % events
        rawTime{ee} = eventStruct.onset(1:nEvents-1);
    else
        rawTime{ee} = eventStruct.onset(1:nEvents);
    end
end
stimDeltaT = round(mean(cellfun(@(x) mean(diff(x)),rawTime)),8);

% Calculate the time to model prior to the first event
nEventsPre = ceil(preStimTimeSecsRaw/stimDeltaT);
preStimTimeSecs = nEventsPre*stimDeltaT;

% Clear the stimulus cell array variable
stimulus = [];

% loop over event files
for ee = 1:nAcqs

    % Get this eventTable
    fileName = fullfile(rawDataPath,eventFileNames{ee});
    eventStruct = tdfread(fileName);

    % Get the raw event times. We just care about the timing of the first
    % stimulus
    firstEventTime = eventStruct.onset(1);

    % Create and store the stimTime
    stimTime{ee} = (firstEventTime - preStimTimeSecs:stimDeltaT:firstEventTime+(nEvents-1)*stimDeltaT);

    % Loop through the events and generate the stimMat
    stimMat = zeros(nStimMatRows,nEventsPre+nEvents);
    for ii = 1:(nEvents-(ee==nAcqs))

        % Identify this face stim
        str = extract(eventStruct.stim_file(ii,:),pat);
        faceID = str2double(str{1});

        % Enter a delta function to model the gain for this stimulus
        stimMat(faceID,ii+nEventsPre) = 1;

        % Model if the button press was right or left sided
        if contains(eventStruct.dot_side(ii,:),'Right')
            stimMat(nUniqueFaces+1,ii+nEventsPre) = 1;
        end
        if contains(eventStruct.dot_side(ii,:),'Left')
            stimMat(nUniqueFaces+1,ii+nEventsPre) = -1;
        end

        % Get the [x,y,z] location in face space
        stimMat(nUniqueFaces+2,ii+nEventsPre) = str2double(eventStruct.face_x_loc_in_similarity_space_HC(ii,:));
        stimMat(nUniqueFaces+3,ii+nEventsPre) = str2double(eventStruct.face_y_loc_in_similarity_space_HC(ii,:));
        stimMat(nUniqueFaces+4,ii+nEventsPre) = str2double(eventStruct.face_z_loc_in_similarity_space_HC(ii,:));
    end

    % Mean center the unique face rows
    for ff = 1:nUniqueFaces
        stimMat(ff,:) = stimMat(ff,:) - mean(stimMat(ff,:));
    end

    % Store the stimMat
    stimulus{ee} = stimMat;

end


end