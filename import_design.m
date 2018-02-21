function import_design(inputfile, dryrun)
    % IMPORT_DESIGN
    %
    %   USAGE: import_design(inputfile, dryrun)
    %
    if nargin < 1, mfile_showhelp; return; end
    if nargin < 2, dryrun = 0; end
    def = task_defaults;
    if iscell(inputfile), inputfile = char(inputfile); end

    % Check Paths
    checkdirs(struct2cell(def.path));
    % Load Trial Definition
    [~,inputname] = fileparts(inputfile);
    [trialSeeker,~,df] = xlsread(inputfile);
     % 1 - block
     % 2 - trial
     % 3 - cond
     % 4 - answer (1:yes, 2:no)
     % 5 - onset
     % 6 - image
     % 7 - question
     % 8 - isicue
    cols = df(1,:);
    data = df(2:end,:);
    ntrials              = length(unique(trialSeeker(:,2)));
    nblocks              = length(unique(trialSeeker(:,1)));
    stimcols             = data(:,6:8);
    blockidx             = trialSeeker(:,2)==1;
    preblockcues         = stimcols(blockidx,2);
    isicues              = stimcols(blockidx,3);
    qim                  = stimcols(:,[2 1]);
    blockSeeker          = trialSeeker(blockidx,[1 3 5]);
    pretrial1dur         = def.preblockquestionDur + def.firstISI;


    % Check for raw images and make slides for presentation
    stim = make_slides(def.path.rawimages, unique(qim(:,2)), def);
    

    % Check Trials
    trialons = reshape(trialSeeker(:,end), ntrials, nblocks);
    diffons = diff(trialons);
    minsoa = def.maxDur + def.inblockreminderDur;
    tooshortidx = diffons < minsoa;
    if any(tooshortidx)
        fprintf('The following blocks have trials with onsets spaced shorter than the min stim onset asynchrony of %2.2f secs:', minsoa)
        disp(find(any(tooshortidx))');
%         return
    end

    % Check Blocks
    minboa = pretrial1dur + ((def.maxDur + def.inblockreminderDur)*(ntrials-1));
    blockdiffons = diff(blockSeeker(:,3));
    tooshortidx = blockdiffons < minboa;
    if any(tooshortidx)
        fprintf('The following block''s onsets occur shorter than the min block onset asynchrony of %2.2f secs:', minboa)
        disp(find(tooshortidx));
%         return
    end

    blockSeeker(:,end)   = blockSeeker(:,end) - pretrial1dur;
    blockSeeker(:,end+1) = 1:nblocks;
    trialSeeker(:,end+1) = trialSeeker(:,end);
    trialSeeker(:,end-1) = 1:size(trialSeeker,1);
    totalTime = trialSeeker(end,6) + def.maxDur + def.endduration;
    numTRs              = ceil(totalTime/def.TR);
    totalTime           = def.TR*numTRs;
    fprintf('\nTotal Run Time: %d secs (%d TRs)', totalTime, numTRs);
    fprintf('\nN Blocks: %d', nblocks);
    fprintf('\nN Trials/Block: %d\n', ntrials);
    if ~dryrun
        
        
        stimfile = fullfile(def.path.stim, 'stimuli.mat');
        save(stimfile, 'stim');
        fprintf('\nPreloaded stimuli written to: %s\n', stimfile)
        designfile = fullfile(def.path.design, sprintf('%s.mat', inputname));
        save(designfile, 'trialSeeker', 'blockSeeker', 'qim', 'preblockcues', 'isicues');
        fprintf('Design written to: %s\n', designfile)
    end
% SUBFUNCTIONS
function checkdirs(thedirs)

    if ischar(thedirs), thedirs = cellstr(thedirs); end
    for i = 1:length(thedirs)
        if ~exist(thedirs{i}, 'dir'), mkdir(thedirs{i}); end
    end
function mfile_showhelp(varargin)
    % MFILE_SHOWHELP
    ST = dbstack('-completenames');
    if isempty(ST), fprintf('\nYou must call this within a function\n\n'); return; end
    eval(sprintf('help %s', ST(2).file));
function stim = make_slides(photodir, imnames, def)
    % MAKE SLIDES
    %


    % get scale
    sc          = imread(fullfile(def.path.stim, 'response_scale.jpg'));

    % images
    fn = fullfile(photodir, imnames);
    nim = length(fn);
    imnoexist = ~cellfun(@exist, fn);
    if any(imnoexist)
        disp('MISSING IMAGES!');
        disp(fn(imnoexist));
    end

    npixels     = 2;
    stim.name = imnames;
    stim.data = cell(size(fn));
    allim = cellfun(@imread, fn, 'Unif', false);
    allim = cellfun(@imresize, allim, repmat({[750 1000]}, nim, 1), 'Unif', false);

    % begin photo loop
    for p = 1:nim

        im = allim{p};
        % add border
        im(:,1:npixels,:) = 250;
        im(1:npixels,:,:) = 250;
        im(:,end-(npixels-1):end,:) = 250;
        im(end-(npixels-1):end,:,:) = 250;

        % create new image, add in resized photo
        sc(226:975,301:1300,:) = im;

        stim.data{p} = imresize(sc,def.screenres([2 1]));

        % resize & save image
        % imwrite(imresize(sc,stimresolution), out{p});

    end


