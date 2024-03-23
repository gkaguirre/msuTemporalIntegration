function nuisanceVars = parseNuisanceVars(rawDataPath,nuisanceFileNames,covarSet)


% Loop through the set of acquisitions
for ii = 1: length(nuisanceFileNames)

    % Load the covar tsv file
    T = readtable(fullfile(rawDataPath,nuisanceFileNames{ii}),'FileType','text','Delimiter','\t');

    % Extract and mean center the covariates
    thisMat = [];
    for jj = 1:length(covarSet)
        thisMat(jj,:) = T.(covarSet{jj});
    end
    thisMat = thisMat - mean(thisMat,2,'omitmissing');
    thisMat(isnan(thisMat(:))) = 0;
    thisMat = thisMat ./ std(thisMat,[],2);

    % Store this matrix
    nuisanceVars{ii} = thisMat;
end

end