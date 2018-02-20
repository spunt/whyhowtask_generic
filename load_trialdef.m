
clear all
inputfile = 'trial_definition.xlsx';
[trialSeeker,~,df] = xlsread(inputfile);
cols = df(1,:);
cellprint(cols)
data = df(2:end,:);
defaults = task_defaults;
 % 1 - block
 % 2 - trial
 % 3 - cond
 % 4 - answer (1:yes, 2:no)
 % 5 - onset
 % 6 - image
 % 7 - question
 % 8 - isicue
ntrials = length(unique(trialSeeker(:,2)));
nblocks = length(unique(trialSeeker(:,1)));
stimcols = data(:,6:8);
blockidx = trialSeeker(:,2)==1;
preblockcues = stimcols(blockidx,2);
isicues = stimcols(blockidx,3);
qim = stimcols(blockidx,[2 1]);
blockSeeker = trialSeeker(blockidx,[1 3 5]);
pretrial1dur = defaults.preblockquestionDur + defaults.firstISI;
blockSeeker(:,end) = blockSeeker(:,end) - pretrial1dur;
blockSeeker(:,end+1) = 1:nblocks;

trialons = reshape(trialSeeker(:,end), ntrials, nblocks);
diffons = diff(trialons);
minsoa = defaults.maxDur + defaults.inblockreminderDur;
tooshortidx = diffons < minsoa;
if any(tooshortidx)
    fprintf('The following blocks have trials with onsets spaced shorter than the min stim onset asynchrony of %2.2f secs:', minsoa)
    disp(find(any(tooshortidx))');
    return
end

minboa = pretrial1dur + ((defaults.maxDur + defaults.inblockreminderDur)*(ntrials-1));
blockdiffons = diff(blockSeeker(:,3));
tooshortidx = blockdiffons < minboa;
if any(tooshortidx)
    fprintf('The following block''s onsets occur shorter than the min block onset asynchrony of %2.2f secs:', minboa)
    disp(find(tooshortidx));
    return
end

trialSeeker(:,end+1) = trialSeeker(:,end);
trialSeeker(:,end-1) = 1:size(trialSeeker,1);

save('design.mat', 'trialSeeker', 'blockSeeker', 'qim', 'preblockcues', 'isicues');

% trialSeeker
%      0    1    2    3     4
% 0  1.0  1.0  2.0  1.0  55.0
% 1  1.0  2.0  2.0  2.0  63.0
% 2  1.0  3.0  2.0  1.0  56.0
% 3  1.0  4.0  2.0  2.0  60.0
% 4  1.0  5.0  2.0  2.0  61.0
% blockSeeker
%      0    1       2     3
% 0  1.0  2.0   5.000   7.0
% 1  2.0  5.0  26.532  25.0
% 2  3.0  4.0  48.277  19.0
% 3  4.0  1.0  71.457   1.0
% 4  5.0  2.0  93.040   8.0
