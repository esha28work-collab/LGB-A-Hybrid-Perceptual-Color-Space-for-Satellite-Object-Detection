% S3_verify_conversions.m
% Visual and numerical verification of all three conversion functions.
% Run on a handful of SIMD images BEFORE building the full datasets.

clc; clear; close all;

src_dir = 'SIMDfulldataset/train/images/';
files   = dir(fullfile(src_dir, '*.jpg'));

% Pick 3 images to check: one with many cars, one sparse, one mixed
check_idx = [1, round(numel(files)/2), numel(files)];

for k = 1:3
    img = imread(fullfile(src_dir, files(check_idx(k)).name));

    rgb = rgb_passthrough(img);
    ygb = rgb_to_ygb(img);
    lgb = rgb_to_lgb(img);

    % ── Figure A: Channel 1 comparison ───────────────────────────────────
    figure('Name', sprintf('Sample %d — Channel 1 comparison', k));
    subplot(1,3,1); imshow(rgb(:,:,1));
    title('R channel (RGB)'); axis off;

    subplot(1,3,2); imshow(ygb(:,:,1));
    title('Y channel (YGB)'); axis off;

    subplot(1,3,3); imshow(lgb(:,:,1));
    title('L channel (LGB)'); axis off;
    % What to expect for SIMD:
    % R  — may show false bright patches from red-reflective surfaces
    % Y  — clean brightness map, vehicle roofs visible as light regions
    % L  — similar to Y but with smoother perceptual gradients

    % ── Figure B: Full reconstructed images ──────────────────────────────
    figure('Name', sprintf('Sample %d — Full image comparison', k));
    subplot(1,3,1); imshow(rgb);  title('RGB');        axis off;
    subplot(1,3,2); imshow(ygb);  title('YGB');        axis off;
    subplot(1,3,3); imshow(lgb);  title('LGB');        axis off;
    % YGB and LGB will look cyan-shifted because R is replaced —

    % this is CORRECT and expected.

    % ── Figure C: Channel 1 intensity histograms ─────────────────────────
    figure('Name', sprintf('Sample %d — Ch1 histograms', k));
    subplot(1,3,1);
    histogram(double(rgb(:,:,1)),'NumBins',64,'FaceColor',[0.8 0.2 0.2],'EdgeColor','none');
    title('R (RGB)'); xlabel('Intensity 0-255'); ylabel('Pixel count');

    subplot(1,3,2);
    histogram(double(ygb(:,:,1)),'NumBins',64,'FaceColor',[0.3 0.4 0.8],'EdgeColor','none');
    title('Y (YGB)'); xlabel('Intensity 0-255');

    subplot(1,3,3);
    histogram(double(lgb(:,:,1)),'NumBins',64,'FaceColor',[0.2 0.7 0.5],'EdgeColor','none');
    title('L (LGB)'); xlabel('Intensity 0-255');
    % L should show a more spread/uniform histogram than Y.
    % Both should be more centered than R.
end

% ── Numerical summary ─────────────────────────────────────────────────────
fprintf('=== Channel 1 statistics across 3 sample images ===\n');
fprintf('%-8s  %-8s  %-8s  %-8s\n', 'Image', 'R mean', 'Y mean', 'L mean');
for k = 1:3
    img = imread(fullfile(src_dir, files(check_idx(k)).name));
    ygb = rgb_to_ygb(img);
    lgb = rgb_to_lgb(img);
    fprintf('%-8d  %-8.1f  %-8.1f  %-8.1f\n', k, ...
        mean2(img(:,:,1)), mean2(ygb(:,:,1)), mean2(lgb(:,:,1)));
end