function run_task1(test_tag)
    % RUN_TASK  Run LOI
    %
    %   USAGE: run_task([test_tag])
    %
    % test_tag = 1:runs only first block, then saves attempts email after
    %            0:runs full experiment (this is default)
    %
    if nargin<1, test_tag = 0; end

    DEVELOPMENT_MODE = 1;

    if DEVELOPMENT_MODE
        Screen('Preference', 'SkipSyncTests', 1);
        fprintf('\n\nWARNING! RUNNING IN DEVELOPMENT MODE!\n\n');
    end

    %% Check for Psychtoolbox %%
    try
        PsychtoolboxVersion;
    catch
        url = 'https://psychtoolbox.org/PsychtoolboxDownload';
        fprintf('\n\t!!! WARNING !!!\n\tPsychophysics Toolbox does not appear to on your search path!\n\tSee: %s\n\n', url);
        return
    end

    %% Print Title %%
    script_name='----------- Photo Judgment Test -----------'; boxTop(1:length(script_name))='=';
    fprintf('\n%s\n%s\n%s\n',boxTop,script_name,boxTop)

    %% DEFAULTS %%
    KbName('UnifyKeyNames');
    defaults = task_defaults;
    trigger = KbName(defaults.trigger);

    %% Load Design and Setup Seeker Variable %%
    design = load(fullfile(defaults.path.design, 'design1.mat'))
    blockSeeker = design.blockSeeker;
    trialSeeker = design.trialSeeker;
    trialSeeker(:,6:9) = 0;
    nTrialsBlock = length(unique(trialSeeker(:,2)));
    BOA  = diff([blockSeeker(:,3); design.totalTime]);
    maxBlockDur = defaults.cueDur + defaults.firstISI + (nTrialsBlock*defaults.maxDur) + (nTrialsBlock-1)*defaults.ISI;
    BOA   = BOA + (maxBlockDur - min(BOA));
    eventTimes          = cumsum([defaults.prestartdur; BOA]);
    blockSeeker(:,3)    = eventTimes(1:end-1);
    numTRs              = ceil(eventTimes(end)/defaults.TR);
    totalTime           = defaults.TR*numTRs;

    %% Print Defaults %%
    fprintf('Test Duration:         %d secs (%d TRs)', totalTime, numTRs);
    fprintf('\nTrigger Key:           %s', defaults.trigger);
    fprintf(['\nValid Response Keys:   %s' repmat(', %s', 1, length(defaults.valid_keys)-1)], defaults.valid_keys{:});
    fprintf('\nForce Quit Key:        %s\n', defaults.escape);
    fprintf('%s\n', repmat('-', 1, length(script_name)));

    %% Get Subject ID %%
    if ~test_tag
        subjectID = ptb_get_input_string('\nEnter Subject ID: ');
    else
        subjectID = 'TEST';
    end

    %% Setup Input Device(s) %%
    switch upper(computer)
      case 'MACI64'
        inputDevice = ptb_get_resp_device;
      case {'PCWIN','PCWIN64'}
        % JMT:
        % Do nothing for now - return empty chosen_device
        % Windows XP merges keyboard input and will process external keyboards
        % such as the Silver Box correctly
        inputDevice = [];
      otherwise
        % Do nothing - return empty chosen_device
        inputDevice = [];
    end
    resp_set = ptb_response_set([defaults.valid_keys defaults.escape]); % response set

    %% Initialize Screen %%
    w = ptb_setup_screen(0,250,defaults.font.name,defaults.font.size1);

    %% Initialize Logfile (Trialwise Data Recording) %%
    d=clock;
    logfile=fullfile(defaults.path.data, sprintf('logfile_socns_loi2_design1_sub%s.txt', subjectID));
    fprintf('\nA running log of this session will be saved to %s\n',logfile);
    fid=fopen(logfile,'a');
    if fid<1,error('could not open logfile!');end
    fprintf(fid,'Started: %s %2.0f:%02.0f\n',date,d(4),d(5));

    %% Make Images Into Textures %%
    DrawFormattedText(w.win,sprintf('LOADING\n\n0%% complete'),'center','center',w.white,defaults.font.wrap);
    Screen('Flip',w.win);
    slideName = cell(length(design.qim), 1);
    slideTex = slideName;
    for i = 1:length(design.qim)
        slideName{i} = design.qim{i,2};
        tmp1 = imread([defaults.path.stim filesep 'loi2' filesep slideName{i}]);
        slideTex{i} = Screen('MakeTexture',w.win,tmp1);
        DrawFormattedText(w.win,sprintf('LOADING\n\n%d%% complete', ceil(100*i/length(design.qim))),'center','center',w.white,defaults.font.wrap);
        Screen('Flip',w.win);
    end
    instructTex = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'loi2_instruction.jpg']));
    fixTex = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'fixation.jpg']));
    reminderTex = Screen('MakeTexture', w.win, imread([defaults.path.stim filesep 'motion_reminder.jpg']));

    %% Get Cues %%
    ordered_questions  = design.preblockcues(blockSeeker(:,4));
    firstclause = {'Is the person ' 'Is the photo ' 'Is it a result of ' 'Is it going to result in '};
    pbc1 = design.preblockcues;
    pbc2 = pbc1;
    for i = 1:length(firstclause)
        tmpidx = ~isnan(cellfun(@mean, regexp(design.preblockcues, firstclause{i})));
        pbc1(tmpidx) = cellstr(firstclause{i}(1:end-1));
        pbc2 = regexprep(pbc2, firstclause{i}, '');
    end
    pbc1 = strcat(pbc1, repmat('\n', 1, defaults.font.linesep));

    %% Get Coordinates for Centering ISI Cues
    isicues_xpos = zeros(length(design.isicues),1);
    isicues_ypos = isicues_xpos;
    for q = 1:length(design.isicues), [isicues_xpos(q), isicues_ypos(q)] = ptb_center_position(design.isicues{q},w.win); end

    %% Test Button Box %%
    if defaults.testbuttonbox, ptb_bbtester(inputDevice, w.win); end

    %==========================================================================
    %
    % START TASK PRESENTATION
    %
    %==========================================================================

    %% Present Instruction Screen %%
    Screen('DrawTexture',w.win, instructTex); Screen('Flip',w.win);

    %% Wait for Trigger to Start %%
    % DisableKeysForKbCheck([]);
    secs=KbTriggerWait(trigger, inputDevice);
    anchor=secs;
    RestrictKeysForKbCheck([resp_set defaults.escape]);

    %% Present Motion Reminder %%
    if defaults.motionreminder
        Screen('DrawTexture',w.win,reminderTex)
        Screen('Flip',w.win);
        WaitSecs('UntilTime', anchor + blockSeeker(1,3) - 2);
    end

    try

        if test_tag, nBlocks = 1; totalTime = ceil(totalTime/(size(blockSeeker, 1))); % for test run
        else nBlocks = length(blockSeeker); end
        %======================================================================
        % BEGIN BLOCK LOOP
        %======================================================================
        for b = 1:nBlocks

            %% Present Fixation Screen %%
            Screen('DrawTexture',w.win, fixTex); Screen('Flip',w.win);

            %% Get Data for This Block (While Waiting for Block Onset) %%
            tmpSeeker   = trialSeeker(trialSeeker(:,1)==b,:);
            line1       = pbc1{blockSeeker(b,4)};  % line 1 of question cue
            pbcue       = pbc2{blockSeeker(b,4)};  % line 2 of question cue
            isicue      = design.isicues{blockSeeker(b,4)};  % isi cue
            isicue_x    = isicues_xpos(blockSeeker(b,4));  % isi cue x position
            isicue_y    = isicues_ypos(blockSeeker(b,4));  % isi cue y position

            %% Prepare Question Cue Screen (Still Waiting) %%
            Screen('TextSize',w.win, defaults.font.size1); Screen('TextStyle', w.win, 0);
            DrawFormattedText(w.win,line1,'center','center',w.white, defaults.font.wrap);
            Screen('TextStyle',w.win, 1); Screen('TextSize', w.win, defaults.font.size2);
            DrawFormattedText(w.win,pbcue,'center','center', w.white, defaults.font.wrap);

            %% Present Question Screen and Prepare First ISI (Blank) Screen %%
            WaitSecs('UntilTime',anchor + blockSeeker(b,3)); Screen('Flip', w.win);
            Screen('FillRect', w.win, w.black);

            %% Present Blank Screen Prior to First Trial %%
            WaitSecs('UntilTime',anchor + blockSeeker(b,3) + defaults.cueDur); Screen('Flip', w.win);

            %==================================================================
            % BEGIN TRIAL LOOP
            %==================================================================
            for t = 1:nTrialsBlock

                %% Prepare Screen for Current Trial %%
                Screen('DrawTexture',w.win,slideTex{tmpSeeker(t,5)})
                if t==1, WaitSecs('UntilTime',anchor + blockSeeker(b,3) + defaults.cueDur + defaults.firstISI);
                else WaitSecs('UntilTime',anchor + offset_dur + defaults.ISI); end

                %% Present Screen for Current Trial & Prepare ISI Screen %%
                Screen('Flip',w.win);
                onset = GetSecs; tmpSeeker(t,6) = onset - anchor;
                if t==nTrialsBlock % present fixation after last trial of block
                    Screen('DrawTexture', w.win, fixTex);
                else % present question reminder screen between every block trial
                    Screen('DrawText', w.win, isicue, isicue_x, isicue_y);
                end

                %% Look for Button Press %%
                [resp, rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, defaults.maxDur, defaults.ignoreDur);
                offset_dur = GetSecs - anchor;

               %% Present ISI, and Look a Little Longer for a Response if None Was Registered %%
                Screen('Flip', w.win);
                norespyet = isempty(resp);
                if norespyet, [resp, rt] = ptb_get_resp_windowed_noflip(inputDevice, resp_set, defaults.ISI*0.90); end
                if ~isempty(resp)
                    if strcmpi(resp, defaults.escape)
                        ptb_exit; rmpath(defaults.path.utilities)
                        fprintf('\nESCAPE KEY DETECTED\n'); return
                    end
                    tmpSeeker(t,8) = find(strcmpi(KbName(resp_set), resp));
                    tmpSeeker(t,7) = rt + (defaults.maxDur*norespyet);
                end
                tmpSeeker(t,9) = offset_dur;

            end % END TRIAL LOOP

            %% Store Block Data & Print to Logfile %%
            trialSeeker(trialSeeker(:,1)==b,:) = tmpSeeker;
            for t = 1:size(tmpSeeker,1), fprintf(fid,[repmat('%d\t',1,size(tmpSeeker,2)) '\n'],tmpSeeker(t,:)); end

        end % END BLOCK LOOP

        %% Present Fixation Screen Until End of Scan %%
        WaitSecs('UntilTime', anchor + totalTime);

    catch

        ptb_exit;
        rmpath(defaults.path.utilities);
        psychrethrow(psychlasterror);

    end

    %% Create Results Structure %%
    result.blockSeeker  = blockSeeker;
    result.trialSeeker  = trialSeeker;
    result.qim          = design.qim;
    result.qdata        = design.qdata;
    result.preblockcues = design.preblockcues;
    result.isicues      = design.isicues;

    %% Save Data to Matlab Variable %%
    d=clock;
    outfile=sprintf('socns_loi2_design1_%s_%s_%02.0f-%02.0f.mat',subjectID,date,d(4),d(5));
    try
        save([defaults.path.data filesep outfile], 'subjectID', 'result', 'slideName', 'defaults');
    catch
        fprintf('couldn''t save %s\n saving to socns_loi2.mat\n',outfile);
        save socns_loi2.mat
    end

    %% End of Test Screen %%
    DrawFormattedText(w.win,'TEST COMPLETE\n\nPlease wait for further instructions.','center','center',w.white,defaults.font.wrap);
    Screen('Flip', w.win);
    ptb_any_key;

    %% Exit & Attempt Backup %%
    ptb_exit;

    try
        disp('Backing up data... please wait.');
        if test_tag
            emailto = {'bobspunt@gmail.com'};
            emailsubject = '[TEST RUN] Conte Social/Nonsocial LOI2 Behavioral Data';
        else
            emailto = {'bobspunt@gmail.com','conte3@caltech.edu'};
            emailsubject = 'Conte Social/Nonsocial LOI2 Behavioral Data';
        end
        emailbackup(emailto, emailsubject, 'See attached.', [defaults.path.data filesep outfile]);
        disp('All done!');
    catch
        disp('Could not email data... internet may not be connected.');
    end

% ===================================== %
% END MAIN FUNCTION
% ===================================== %

function w = ptb_setup_screen(background_color, font_color, font_name, font_size, screen_res)
    % PTB_SETUP_SCREEN Psychtoolbox utility for setting up screen
    %
    % USAGE: w = ptb_setup_screen(background_color,font_color,font_name,font_size,screen_res)
    %
    % INPUTS
    %  background_color = color to setup screen with
    %  font_color = default font color
    %  font_name = default font name (e.g. 'Arial','Times New Roman','Courier')
    %  font_size = default font size
    %  screen_res = desired screen resolution (width x height)
    %
    % OUTPUTS
    %   w = structure with the following fields:
    %       win = window pointer
    %       res = window resolution
    %       oldres = original window resolution
    %       xcenter = x center
    %       ycenter = y center
    %       white = white index
    %       black = black index
    %       gray = between white and black
    %       color = background color
    %       font.name = default font
    %       font.color = default font color
    %       font.size = default font size
    %       font.wrap = default wrap for font
    %

    if nargin<5, screen_res = []; end
    if nargin<4, display('USAGE: w = ptb_setup_screen(background_color,font_color,font_name,font_size, screen_res)'); return; end
    % start
    AssertOpenGL;
    screenNum = max(Screen('Screens'));
    oldres = Screen('Resolution',screenNum);
    if ~isempty(screen_res) & ~isequal([oldres.width oldres.height], screen_res)
        Screen('Resolution',screenNum,screen_res(1),screen_res(2));
    end
    [w.win w.res] = Screen('OpenWindow', screenNum, background_color);
    [width height] = Screen('WindowSize', w.win);
    % text
    Screen('TextSize', w.win, font_size);
    Screen('TextFont', w.win, font_name);
    Screen('TextColor', w.win, font_color);
    % this bit gets the default font wrap
    text = repmat('a',1000,1);
    [normBoundsRect offsetBoundsRect]= Screen('TextBounds', w.win, text);
    wscreen = w.res(3);
    wtext = normBoundsRect(3);
    wchar = floor(wtext/length(text));
    % output variable
    w.xcenter = width/2;
    w.ycenter = height/2;
    w.white = WhiteIndex(w.win);
    w.black = BlackIndex(w.win);
    w.gray = round(((w.white-w.black)/2));
    w.color = background_color;
    w.font.name = font_name;
    w.font.color = font_color;
    w.font.size = font_size;
    w.font.wrap = floor(wscreen/wchar) - 4;
    % flip up screen
    HideCursor;
    Screen('FillRect', w.win, background_color);

function chosen_device = ptb_get_resp_device(prompt)
    % PTB_GET_RESPONSE Psychtoolbox utility for acquiring responses
    %
    % USAGE: chosen_device = ptb_get_resp_device(prompt)
    %
    % INPUTS
    %  prompt = to display to user
    %
    % OUTPUTS
    %  chosen_device = device number
    %

    if nargin<1, prompt = 'Which device?'; end
    chosen_device = [];
    numDevices=PsychHID('NumDevices');
    devices=PsychHID('Devices');
    candidate_devices = [];
    boxTop(1:length(prompt))='-';
    keyboard_idx = GetKeyboardIndices;
    fprintf('\n%s\n%s\n%s\n',boxTop,prompt,boxTop)
    if length(keyboard_idx)==1
        fprintf('Defaulting to one found keyboard: %s, %s\n',devices(keyboard_idx).usageName,devices(keyboard_idx).product)
        chosen_device = keyboard_idx;
    else
        for i=1:length(keyboard_idx), n=keyboard_idx(i); fprintf('%d - %s, %s\n',i,devices(n).usageName,devices(n).product); candidate_devices = [candidate_devices i]; end
        prompt_string = sprintf('\nChoose a keyboard (%s): ',num2str(candidate_devices));
        while isempty(chosen_device)
            chosen_device = input(prompt_string);
            if isempty(chosen_device)
                fprintf('Invalid Response!\n')
                chosen_device = [];
            elseif isempty(find(candidate_devices == chosen_device))
                fprintf('Invalid Response!\n')
                chosen_device = [];
            end
        end
        chosen_device = keyboard_idx(chosen_device);
    end

function [resp_set, old_set] = ptb_response_set(keys)
    % PTB_RESPONSE_SET Psychtoolbox utility for building response set
    %
    % USAGE: resp_set = ptb_response_set(keys)
    %
    % INPUTS
    %  keys = cell array of strings for key names
    %
    % OUTPUTS
    %  resp_set = array containing key codes for key names
    %

    if nargin<1, disp('USAGE: resp_set = ptb_response_set(keys)'); return; end
    if ischar(keys), keys = cellstr(keys); end
    KbName('UnifyKeyNames');
    resp_set    = cell2mat(cellfun(@KbName, keys, 'Unif', false));
    old_set     = RestrictKeysForKbCheck(resp_set);

function [resp,rt] = ptb_get_resp_windowed_noflip(resp_device, resp_set, resp_window, ignore_dur)
    % PTB_GET_RESP_WINDOWED Psychtoolbox utility for acquiring responses
    %
    % USAGE: [resp rt] = ptb_get_resp_windowed_noflip(resp_device, resp_set, resp_window, ignore_dur)
    %
    % INPUTS
    %  resp_device = device #
    %  resp_set = array of keycodes (from KbName) for valid keys
    %  resp_window = response window (in secs)
    %  ignore_dur = dur after onset in which to ignore button presses
    %
    % OUTPUTS
    %  resp = name of key press (empty if no response)
    %  rt = time of key press (in secs)
    %

    if nargin < 4, ignore_dur = 0; end
    onset = GetSecs;
    noresp = 1;
    resp = [];
    rt = [];
    if ignore_dur, WaitSecs('UntilTime', onset + ignore_dur); end
    while noresp && GetSecs - onset < resp_window
        [keyIsDown, secs ,keyCode] = KbCheck(resp_device);
        keyPressed = find(keyCode);
        if keyIsDown & ismember(keyPressed, resp_set)
            rt = secs - onset;
            resp = KbName(keyPressed);
            noresp = 0;
        end
    end

function [resp, rt] = ptb_get_resp_windowed(resp_device, resp_set, resp_window, window, color)
    % PTB_GET_RESP_WINDOWED Psychtoolbox utility for acquiring responses
    %
    % USAGE: [resp rt] = ptb_get_resp_windowed(resp_device,resp_set,resp_window,window,color)
    %
    % INPUTS
    %  resp_device = device #
    %  resp_set = array of keycodes (from KbName) for valid keys
    %  resp_window = response window (in secs)
    %  window = window to draw to
    %  color = color to flip once response is collected
    %
    % OUTPUTS
    %  resp = name of key press (empty if no response)
    %  rt = time of key press (in secs)
    %

    if nargin<5, disp('USAGE: [resp rt] = ptb_get_resp_windowed(resp_device,resp_set,resp_window,window,color)'); return; end

    onset = GetSecs;
    noresp = 1;
    resp = [];
    rt = [];
    while noresp && GetSecs - onset < resp_window

        [keyIsDown secs keyCode] = KbCheck(resp_device);
        keyPressed = find(keyCode);
        if keyIsDown & ismember(keyPressed, resp_set)

            rt = secs - onset;
            Screen('FillRect', window, color);
            Screen('Flip', window);
            resp = KbName(keyPressed);
            noresp = 0;

        end

    end
    WaitSecs('UntilTime', onset + resp_window)

function tex = ptb_im2tex(imfile, w)
    % PTB_IM2TEX
    %
    % USAGE: tex = ptb_im2tex(imfile, w)
    %
    % OUTPUTS
    %   im - structure with following fields
    %   w - window
    %   tex - pointer to image tex from Screen('MakeTexture',...)
    %

    if nargin < 1, disp('USAGE: tex = ptb_im2tex(imfile, w)'); return; end
    if iscell(imfile), imfile = char(imfile); end
    tex = Screen('MakeTexture', w, imread(imfile));

function doquit = ptb_get_force_quit(resp_device, resp_set, resp_window)
    % PTB_GET_FORCE_QUIT
    %
    % USAGE: ptb_get_force_quit(resp_device, resp_set, resp_window)
    %
    % INPUTS
    %  resp_device = device #
    %  resp_set = array of keycodes (from KbName) for valid keys
    %  resp_window = response window (in secs)
    %

    onset = GetSecs;
    noresp = 1;
    doquit = 0;
    while noresp && GetSecs - onset < resp_window

        [keyIsDown, ~, keyCode] = KbCheck(resp_device);
        keyPressed = find(keyCode);
        if keyIsDown && ismember(keyPressed, resp_set)
            noresp = 0; doquit = 1;
        end

    end

function [xpos, ypos] = ptb_center_position(string, window, y_offset)
    % PTB_CENTER_POSITION
    %
    % USAGE: [xpos ypos] = ptb_center_position(string, window, y_offset)
    %
    % INPUTS
    %  string = string being displayed
    %  window = window in which it will be displayed
    %  y_offset = (default = 0) offset on y-axis (pos = lower, neg = higher)
    %
    % OUTPUTS
    %   xpos = starting x coordinate
    %   ypos = starting y coordinate
    %

    if nargin<2, disp('USAGE: [xpos ypos] = ptb_center_position(string, window, y_offset)'); end
    if nargin<3, y_offset = 0; end
    text_size = Screen('TextBounds', window, string);
    [width height] = Screen('WindowSize', window);
    xcenter = width/2;
    ycenter = height/2;
    text_x = text_size(1,3);
    text_y = text_size(1,4);
    xpos = xcenter - (text_x/2);
    ypos = ycenter - (text_y/2) + y_offset;

function rect = ptb_center_position_image(im, window, xy_offsets)
    % PTB_CENTER_POSITION
    %
    % USAGE: rect = ptb_center_position_image(im, window, xy_offsets)
    %
    % INPUTS
    %  im = image matrix to be displayed
    %  window = window in which it will be displayed
    %  xy_offsets = (default = [0 0]) offset on x and y-axes (pos = lower, neg = higher)
    %
    % OUTPUTS
    %   rect = coordinates for desination rectangle
    %

    if nargin<2, disp('USAGE: rect = ptb_center_position_image(im, window, xy_offsets)'); return; end
    if nargin<3, xy_offsets = [0 0]; end
    dims = size(im);
    [width height] = Screen('WindowSize', window);
    rect = [0 0 0 0];
    rect(1) = (width - dims(2))/2 + xy_offsets(1);
    rect(2) = (height - dims(1))/2 + xy_offsets(2);
    rect(3) = rect(1) + dims(2);
    rect(4) = rect(2) + dims(1);

function out = ptb_get_input_string(prompt)
    % PTB_GET_INPUT_STRING Psychtoolbox utility for getting valid user input string
    %
    % USAGE: out = ptb_get_input(prompt)
    %
    % INPUTS
    %  prompt = string containing message to user
    %
    % OUTPUTS
    %  out = input
    %

    if nargin<1, disp('USAGE: out = ptb_get_input(prompt)'); return; end
    out = input(prompt, 's');
    while isempty(out)
        disp('ERROR: You entered nothing. Try again.');
        out = input(prompt, 's');
    end

function emailbackup(to,subject,message,attachment)

    if nargin == 3, attachment = ''; end

    % set up gmail SMTP service
    setpref('Internet','E_mail','neurospunt@gmail.com');
    setpref('Internet','SMTP_Server','smtp.gmail.com');
    setpref('Internet','SMTP_Username','neurospunt@gmail.com');
    setpref('Internet','SMTP_Password','socialbrain');

    % gmail server
    props = java.lang.System.getProperties;
    props.setProperty('mail.smtp.auth','true');
    props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
    props.setProperty('mail.smtp.socketFactory.port','465');

    % send
    if isempty(attachment)
        sendmail(to,subject,message);
    else
        sendmail(to,subject,message,attachment)
    end

function ptb_disp_message(message,w,lspacing)
    % PTB_DISP_MESSAGE Psychtoolbox utility for displaying a message
    %
    % USAGE: ptb_disp_message(message,w,lspacing)
    %
    % INPUTS
    %  message = string to display
    %  w = screen structure (from ptb_setup_screen)
    %  lspacing = line spacing (default = 1)
    %

    if nargin<3, lspacing = 1; end
    if nargin<2, disp('USAGE: ptb_disp_message(message,w,lspacing)'); return; end
    DrawFormattedText(w.win,message,'center','center',w.font.color,w.font.wrap,[],[],lspacing);
    Screen('Flip',w.win);

function ptb_any_key(resp_device)

    if nargin<1, resp_device = -1; end
    oldkey = RestrictKeysForKbCheck([]);
    KbPressWait(resp_device);
    RestrictKeysForKbCheck(oldkey);

function ptb_exit
    % sca -- Execute Screen('CloseAll');
    % This is just a convenience wrapper that allows you
    % to save typing that long, and frequently needed,  command.
    % It also unhides the cursor if hidden, and restores graphics card gamma
    % tables if they've been altered.
    %

    % Release keys
    RestrictKeysForKbCheck([]);

    % Unhide the cursor if it was hidden:
    ShowCursor;
    for win = Screen('Windows')
        if Screen('WindowKind', win) == 1
            if Screen('GetWindowInfo', win, 4) > 0
                Screen('AsyncFlipEnd', win);
            end
        end
    end

    % Close all windows, release all Screen() ressources:
    Screen('CloseAll');

    % Restore (possibly altered) gfx-card gamma tables from backup copies:
    RestoreCluts;

    % Call Java cleanup routine to avoid java.lang.outOfMemory exceptions due
    % to the bugs and resource leaks in Matlab's Java based GUI:
    if ~IsOctave && exist('PsychJavaSwingCleanup', 'file')
        PsychJavaSwingCleanup;
    end
    Priority(0);
    return
