filename = 'sub-C0103_ses-1_task-main_run-6_events.tsv';
t = tdfread(filename);
nEvents = 147;
stimTime = t.onset(1:nEvents);
for ii = 1:nEvents
    stimulus(1,ii) = 1;
    stimulus(2,ii) = str2double(t.face_x_loc_in_similarity_space_HC(ii,:));
    stimulus(3,ii) = str2double(t.face_y_loc_in_similarity_space_HC(ii,:));
    stimulus(4,ii) = str2double(t.face_z_loc_in_similarity_space_HC(ii,:));
    if contains(t.dot_side(ii,:),'Right')
        stimulus(5,ii) = 1;
    end
    if contains(t.dot_side(ii,:),'Left')
        stimulus(5,ii) = -1;
    end
end