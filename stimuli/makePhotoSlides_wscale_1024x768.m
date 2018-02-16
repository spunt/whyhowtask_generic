% MAKE SLIDES 
% -----------------------------------------------------
clear all; 

npixels     = 2;
basedir     = '/Users/bobspunt/Drive/Research/Caltech/LOI_FACE_ER/task/stimuli';

% get scale
sc          = imread('scale_short.jpg');

% get photo filenames
photodir    = fullfile(basedir, 'production', '1200x900');
outputdir   = basedir;
[imp,imn]   = files(fullfile(photodir, '*jpg'));
out         = fullfile(outputdir, imn); 
im          = cellfun(@imread, imp, 'Unif', false);
im          = cellfun(@imresize, im, repmat({[750 1000]}, length(im), 1), 'Unif', false);
imout       = im; 
% begin photo loop
for p = 1:length(im)
    
    % read in photo
    op = im{p};
    
    % add border
    op(:,1:npixels,:) = 250;
    op(1:npixels,:,:) = 250;
    op(:,end-(npixels-1):end,:) = 250;
    op(end-(npixels-1):end,:,:) = 250;

    % create new image, add in resized photo
    sc(226:975,301:1300,:) = op;

    % resize & save image
    imwrite(imresize(sc,[768 1024]), out{p}); 

        
end









    