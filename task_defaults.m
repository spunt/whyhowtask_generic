function defaults = task_defaults
% DEFAULTS  Defines defaults for RUN_TASK.m

% Screen Resolution
%==========================================================================
defaults.screenres      = [1200 900];   % primarily used to set the resolution
                        % of the slides constructed when initially loading
                        % the trial_definition spreadsheet

% Timing (all in seconds)
%==========================================================================
defaults.preblockquestionDur = 2.25;   % dur of preblock question presentation
defaults.maxDur         = 2;      % (max) dur of every response trial
defaults.inblockreminderDur  = .50;   % dur of reminder cue presented prior to every trial
                                      % except the first within each block
defaults.firstISI       = 0.15;   % dur of interval between preblock question and
                                  % first trial of each block
defaults.endduration    = 8;      % dur of fixation period after last trial of last block
defaults.ignoreDur      = 0.15;   % dur after trial presentation in which
                                  % button presses are ignored (this is
                                  % useful when participant provides a late
                                  % response to the previous trial)
                                  % DEFAULT VALUE = 0.15
defaults.TR             = 1;      % Your TR (in secs)


% Paths
%==========================================================================
defaults.path.base      = fileparts(mfilename('fullpath'));
defaults.path.data      = fullfile(defaults.path.base, 'data');
defaults.path.rawimages = fullfile(defaults.path.base, 'raw_stimuli');
% defaults.path.rawimages = '/Users/bobspunt/Github/research-projects/conte-renewal-lois/stimuli';
defaults.path.stim      = fullfile(defaults.path.base, 'slides');
defaults.path.design    = fullfile(defaults.path.base, 'design');


% Response Keys
%==========================================================================
defaults.escape         = 'ESCAPE'; % escape key (to exit early)
defaults.trigger        = '5%'; % task trigger key (to start task)
defaults.valid_keys     = {'1!' '2@' '3#' '4$'}; % valid response keys
% These correspond to the keys that the participant can use to make their
% responses during task performance. The key in the first position (e.g.,
% '1!') will be numerically coded as a 1 in the output data file; the key
% in the second position as a 3; and so on. Given that the subject is
% making a binary choice on each trial, you will need to specify AT LEAST
% two keys. If the subject is using a button box, it may be desirable to
% include all buttons on the box in case the subject winds up having their
% fingers on the wrong keys.

% Text Display Parameters
%==========================================================================
defaults.font.name      = 'Arial'; % default font
defaults.font.size1     = 42; % default font size (smaller)
defaults.font.size2     = 46; % default font size (bigger)
defaults.font.wrap      = 42; % default font wrapping (arg to DrawFormattedText)
defaults.font.linesep   = 3;  % spacing between first and second lines of question cue

% Misc
%==========================================================================
defaults.testbuttonbox  = false; % set to either true or false
defaults.motionreminder = false; % set to either true or false




end
