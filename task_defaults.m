function defaults = task_defaults
% DEFAULTS  Defines defaults for RUN_TASK.m

% Screen Resolution
%==========================================================================
defaults.screenres      = [1280 960];   % recommended screen resolution (if
                                        % not supported by monitor, will
                                        % default to current resolution)

% Response Keys
%==========================================================================
defaults.trigger        = '5%'; % trigger key (to start ask)
defaults.valid_keys     = {'1!' '2@' '3#' '4$'}; % valid response keys
defaults.escape         = 'ESCAPE'; % escape key (to exit early)
defaults.testbuttonbox  = false; % set to either true or false
defaults.motionreminder = false; % set to either true or false

% Timing (specify in seconds)
%==========================================================================
defaults.TR             = 1;      % Your TR (in secs)
defaults.preblockquestionDur         = 2.10;   % dur of preblock question presentation
defaults.maxDur         = 2;   % (max) dur of trial
defaults.inblockreminderDur            = .50;   % dur of interval between trials
defaults.endduration    = 4;      % duration of fixation period after last trial of last block

% Paths
%==========================================================================
defaults.path.base      = pwd;
defaults.path.data      = fullfile(defaults.path.base, 'data');
defaults.path.stim      = fullfile(defaults.path.base, 'stimuli');
defaults.path.design    = fullfile(defaults.path.base, 'design', 'design_order1.mat');

% Text
%==========================================================================
defaults.font.name      = 'Helvetica'; % default font
defaults.font.size1     = 42; % default font size (smaller)
defaults.font.size2     = 46; % default font size (bigger)
defaults.font.wrap      = 42; % default font wrapping (arg to DrawFormattedText)
defaults.font.linesep   = 3;  % spacing between first and second lines of question cue




defaults.firstISI       = 0.15;   % dur of interval between preblock question and
                                  % first trial of each block


defaults.ignoreDur      = 0.15;   % dur after trial presentation in which
                                  % button presses are ignored (this is
                                  % useful when participant provides a late
                                  % response to the previous trial)
                                  % DEFAULT VALUE = 0.15
end
