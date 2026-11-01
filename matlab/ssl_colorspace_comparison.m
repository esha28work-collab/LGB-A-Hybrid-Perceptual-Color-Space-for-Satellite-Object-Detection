%% Visual comparison of RGB, YGB, and LGB color spaces on sample SSL images
%
% Produces a figure in the same layout as your SIMD figure: one row per
% sample image, six columns per row (RGB | YGB | LGB | R channel |
% Y channel | L channel), with the single-channel columns shown as
% grayscale.
%
% Fill in sample_paths below with 3 (or however many) SSL image paths.

clear; clc; close all;

%% ---- CONFIGURATION ----
sample_paths = {
    'C:\Users\DELL\Desktop\c\SSL_RGB\train\images\sample_00003.jpg'
    'C:\Users\DELL\Desktop\c\SSL_RGB\train\images\sample_00800.jpg'
    'C:\Users\DELL\Desktop\c\SSL_RGB\train\images\sample_01032.jpg'
};

col_titles = {'RGB', 'YGB', 'LGB', 'R Channel', 'Y Channel', 'L Channel'};
n_rows = numel(sample_paths);
n_cols = numel(col_titles);

fig = figure('Color', 'w', 'Position', [100, 100, 1400, 230 * n_rows]);
tl = tiledlayout(fig, n_rows, n_cols, 'TileSpacing', 'compact', 'Padding', 'compact');

%% ---- MAIN LOOP ----
for row = 1:n_rows
    rgb = imread(sample_paths{row});

    % MATLAB's imread returns RGB order directly (unlike cv2.imread, which
    % is BGR) -- no channel swap needed here.
    R = double(rgb(:, :, 1));
    G = double(rgb(:, :, 2));
    B = double(rgb(:, :, 3));

    % --- YGB: Y (luma) replaces R, matching the paper's Eq. 1 ---
    Y = 0.299 * R + 0.587 * G + 0.114 * B;
    ygb = cat(3, uint8(Y), uint8(G), uint8(B));

    % --- LGB: L (CIE L*) from Lab color space replaces R ---
    lab = rgb2lab(rgb);                 % L in [0, 100], a/b roughly [-128, 127]
    L = lab(:, :, 1) * (255 / 100);     % rescale L to 0-255 for an 8-bit image
    lgb = cat(3, uint8(L), uint8(G), uint8(B));

    % --- Single-channel grayscale panels ---
    R_panel = uint8(R);
    Y_panel = uint8(Y);
    L_panel = uint8(L);

    panels = {rgb, ygb, lgb, R_panel, Y_panel, L_panel};

    for col = 1:n_cols
        ax = nexttile(tl, (row - 1) * n_cols + col);
        imshow(panels{col}, 'Parent', ax);
        ax.XAxis.Visible = 'on';
            xlable(ax, col_titles{col}, 'FontSize', 11, 'FontWeight', 'normal');
        end
end

%% ---- SAVE ----
exportgraphics(fig, 'ssl_colorspace_comparison.png', 'Resolution', 300);
exportgraphics(fig, 'ssl_colorspace_comparison.pdf', 'ContentType', 'vector');
disp('Saved: ssl_colorspace_comparison.png and .pdf');
