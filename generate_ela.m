function ela = generate_ela(originalFilename, tamperedFilename, qf)

clc;

% Validate inputs
if nargin ~= 3
    error('Usage: generate_ela(originalFilename, tamperedFilename, qf)');
end

if ~isnumeric(qf) || ~isscalar(qf) || ~isfinite(qf) || qf < 0 || qf > 100 || qf ~= floor(qf)
    error('JPEG quality must be an integer between 0 and 100.');
end

% Check input files
if ~isfile(originalFilename)
    error('Original image file not found: %s', originalFilename);
end

if ~isfile(tamperedFilename)
    error('Tampered image file not found: %s', tamperedFilename);
end

% Read original and tampered images
orig = imread(originalFilename);
tampered = imread(tamperedFilename);

% Convert images to RGB format
if size(orig,3) == 1
    orig = repmat(orig,1,1,3);
elseif size(orig,3) == 4
    orig = orig(:,:,1:3);
end

if size(tampered,3) == 1
    tampered = repmat(tampered,1,1,3);
elseif size(tampered,3) == 4
    tampered = tampered(:,:,1:3);
end

orig = im2uint8(orig);
tampered = im2uint8(tampered);

% Check image dimensions
if ~isequal(size(orig),size(tampered))
    error('Original and tampered images must have the same dimensions.');
end

% Display original image
figure;
imshow(orig);
title('Original Image');

% Display tampered image
figure;
imshow(tampered);
title('Tampered Image');

% Display image information
info = imfinfo(tamperedFilename);
disp(info);
disp(['Image Size: ',num2str(info.FileSize/1024),' KB']);

% JPEG recompression of tampered image
tempfile = [tempname(tempdir),'.jpg'];

imwrite(tampered,tempfile,'jpeg','Quality',qf);
temp = imread(tempfile);
delete(tempfile);

% Error Level Analysis
idiff = uint8(abs(double(tampered)-double(temp))*30);

me = double(max(idiff(:)));

if me > 0
    idiff = uint8(double(idiff)*255/me);
else
    idiff = zeros(size(idiff),'uint8');
end

% Display ELA image
figure;
imshow(idiff);
title('ELA Difference Image');

% Wiener filtering
k = wiener2(im2double(rgb2gray(idiff)),[5 5]);

figure;
imshow(k);
title('Filtered ELA Image');

% Morphological processing
se = strel('disk',3);

grayOrig = im2double(rgb2gray(orig));

contrastfiltered = ...
    (grayOrig + imtophat(grayOrig,se)) - imbothat(grayOrig,se);

Ml = mat2gray(contrastfiltered);

figure;
imshow(Ml);
title('Morphological Processing');

% Suspicious region detection
BW2 = imbinarize(k,graythresh(k));

BW2 = bwareaopen(BW2,20);
BW2 = imclose(BW2,se);

% Connected component analysis
cc = bwconncomp(BW2,8);
disp(cc);

eul = bweuler(BW2,8);
disp(['Euler Number: ',num2str(eul)]);

figure;
imshow(BW2);
title('Detected Suspicious Regions');

% Save output images
projectFolder = fileparts(mfilename('fullpath'));
destinationFolder = fullfile(projectFolder,'Results');

if ~exist(destinationFolder,'dir')
    mkdir(destinationFolder);
end

imwrite(orig,fullfile(destinationFolder,'0_Original.jpg'));
imwrite(tampered,fullfile(destinationFolder,'0_Tampered.jpg'));
imwrite(idiff,fullfile(destinationFolder,'1_ELA.jpg'));
imwrite(k,fullfile(destinationFolder,'2_Filtered_ELA.jpg'));
imwrite(Ml,fullfile(destinationFolder,'3_Morphological.jpg'));
imwrite(BW2,fullfile(destinationFolder,'4_Tampering_Mask.jpg'));

disp('All six output images saved successfully.');

ela = idiff;

end
