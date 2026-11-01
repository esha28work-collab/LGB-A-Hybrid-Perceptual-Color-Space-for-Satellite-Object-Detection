clc; clear; close all;

src_train_img = 'SSL_RGB/train/images/';
src_train_lbl = 'SSL_RGB/train/labels/';
src_val_img   = 'SSL_RGB/val/images/';
src_val_lbl   = 'SSL_RGB/val/labels/';
src_test_img   = 'SSL_RGB/test/images/';
src_test_lbl   = 'SSL_RGB/test/labels/';

train_imgs = dir(fullfile(src_train_img, '*.jpg'));
train_lbls = dir(fullfile(src_train_lbl, '*.txt'));
val_imgs   = dir(fullfile(src_val_img,   '*.jpg'));
val_lbls   = dir(fullfile(src_val_lbl,   '*.txt'));
test_imgs   = dir(fullfile(src_val_img,   '*.jpg'));
test_lbls   = dir(fullfile(src_val_lbl,   '*.txt'));

fprintf('=== SSL Dataset File Counts ===\n');
fprintf('Train images : %d  \n', numel(train_imgs));
fprintf('Train labels : %d  \n', numel(train_lbls));
fprintf('Val   images : %d  \n', numel(val_imgs));
fprintf('Val   labels : %d  \n', numel(val_lbls));
fprintf('test   images : %d  \n', numel(test_imgs));
fprintf('test  labels : %d  \n', numel(test_lbls));

% Verify every image has a matching label file
fprintf('\n=== Checking image-label pairing ===\n');
mismatch = 0;
for i = 1:numel(val_imgs)
    img_name = val_imgs(i).name;
    lbl_name = strrep(img_name, '.jpg', '.txt');  % same stem, .txt extension
    lbl_path = fullfile(src_val_lbl, lbl_name);
    if ~isfile(lbl_path)
        fprintf('  MISSING LABEL: %s\n', img_name);
        mismatch = mismatch + 1;
    end
end
if mismatch == 0
    fprintf('  All train image-label pairs matched.\n');
else
    fprintf('  %d missing labels — fix before continuing!\n', mismatch);
end

%% ── 2. Sample image properties ───────────────────────────────────────────

fprintf('\n=== Image properties (10 random samples) ===\n');
idx = randperm(numel(val_imgs), 10);

widths = zeros(1,10); heights = zeros(1,10); channels = zeros(1,10);
for i = 1:10
    info = imfinfo(fullfile(src_val_img, val_imgs(idx(i)).name));
    widths(i)   = info.Width;
    heights(i)  = info.Height;
    channels(i) = info.NumberOfSamples;
    fprintf('  %s — %dx%d ch:%d\n', val_imgs(idx(i)).name, ...
        info.Width, info.Height, info.NumberOfSamples);
end

% Check for non-standard sizes — SSL should be uniformly 1024x768
if isscalar(unique(widths)) && isscalar(unique(heights))
%if numel(unique(widths)) == 1 && numel(unique(heights)) == 1
    fprintf('  All sampled images are %dx%d — consistent.\n', widths(1), heights(1));
else
    fprintf('  WARNING: Mixed resolutions detected!\n');
end

%% ── 3. Deep-read one image — pixel statistics ────────────────────────────

fprintf('\n=== Pixel statistics for one sample image ===\n');
img = imread(fullfile(src_val_img, val_imgs(1).name));
fprintf('  Data type  : %s\n',   class(img));       % should be uint8
fprintf('  Size       : %dx%dx%d\n', size(img,1), size(img,2), size(img,3));
fprintf('  R — min:%3d  max:%3d  mean:%.1f\n', ...
    min(img(:,:,1),[],'all'), max(img(:,:,1),[],'all'), mean2(img(:,:,1)));
fprintf('  G — min:%3d  max:%3d  mean:%.1f\n', ...
    min(img(:,:,2),[],'all'), max(img(:,:,2),[],'all'), mean2(img(:,:,2)));
fprintf('  B — min:%3d  max:%3d  mean:%.1f\n', ...
    min(img(:,:,3),[],'all'), max(img(:,:,3),[],'all'), mean2(img(:,:,3)));

%% ── 4. Read and parse one label file ─────────────────────────────────────
% YOLO format: each row = [class_id  cx  cy  w  h]  all values in [0,1]

fprintf('\n=== Label file content (first image) ===\n');
lbl_file = strrep(val_imgs(1).name, '.jpg', '.txt');
labels   = readmatrix(fullfile(src_val_lbl, lbl_file));
% readmatrix parses space-delimited floats cleanly

class_names = {'airplane','boat','car','ship'};

fprintf('  Objects in this image: %d\n', size(labels, 1));
for r = 1:size(labels, 1)
    cid = labels(r,1) + 1;    % YOLO class IDs are 0-based; MATLAB is 1-based
    fprintf('  Row %d: class=%s  cx=%.4f  cy=%.4f  w=%.4f  h=%.4f\n', ...
        r, class_names{cid}, labels(r,2), labels(r,3), labels(r,4), labels(r,5));
end

%% ── 5. Class distribution across full training set ───────────────────────
% This takes a few minutes but is essential for understanding class balance.
% Imbalanced classes affect how you interpret detection sensitivity metrics.

fprintf('\n=== Class distribution (full Val set — may take ~2 min) ===\n');
class_counts = zeros(1, 4);

for i = 1:numel(val_lbls)
    lbl_path = fullfile(src_val_lbl, val_lbls(i).name);
    if isfile(lbl_path) && (dir(lbl_path).bytes > 0)
        data = readmatrix(lbl_path);
        if ~isempty(data)
            for r = 1:size(data,1)
                cid = data(r,1) + 1;
                if cid >= 1 && cid <= 4
                    class_counts(cid) = class_counts(cid) + 1;
                end
            end
        end
    end
    if mod(i, 1000) == 0
        fprintf('  Scanned %d / %d label files...\n', i, numel(val_lbls));
    end
end

fprintf('\n  Class | Name            | Count  | Percent\n');
fprintf('  ------|-----------------|--------|--------\n');
total_objs = sum(class_counts);
for c = 1:4
    fprintf('  %2d    | %-15s | %6d | %.1f%%\n', ...
        c-1, class_names{c}, class_counts(c), 100*class_counts(c)/total_objs);
end
fprintf('  TOTAL objects: %d\n', total_objs);

%% ── 6. Visual inspection ─────────────────────────────────────────────────

fprintf('\n=== Opening visual inspection figure ===\n');
img  = imread(fullfile(src_val_img, val_imgs(1).name));
lbl_file = strrep(val_imgs(1).name, '.jpg', '.txt');
lbls = readmatrix(fullfile(src_val_lbl, lbl_file));

[H, W, ~] = size(img);

figure('Name', 'SSL — Sample image with annotations');
imshow(img); hold on; title('Sample SSL image — ground truth boxes');

colors = lines(15);   % 15 distinct colors, one per class
for r = 1:size(lbls, 1)
    cid = lbls(r,1) + 1;
    cx  = lbls(r,2) * W;   % convert normalized coords to pixel coords
    cy  = lbls(r,3) * H;
    bw  = lbls(r,4) * W;
    bh  = lbls(r,5) * H;
    x1  = cx - bw/2;
    y1  = cy - bh/2;

    % Draw bounding box
    rectangle('Position', [x1, y1, bw, bh], ...
        'EdgeColor', colors(cid,:), 'LineWidth', 1.5);

    % Label above box
    text(x1, y1-2, class_names{cid}, ...
        'Color', colors(cid,:), 'FontSize', 7, 'FontWeight', 'bold');
end
hold off;

fprintf('Inspection complete. Review the figure before proceeding.\n');