% S4_build_datasets.m (All 4 Color Spaces)
% Builds SIMD_YGB, SIMD_LGB.

clc; clear;

%% ── Paths ────────────────────────────────────────────────────────────────
src_root = 'SIMDfulldataset';
out_dirs = {'SIMD_YGB', 'SIMD_LGB'};
splits   = {'test', 'train', 'val'};

%% ── Create directories ──────────────────────────────────────────────────
for d = 1:2
    for s = 1:3
        img_dir = fullfile(out_dirs{d}, splits{s}, 'images');
        lbl_dir = fullfile(out_dirs{d}, splits{s}, 'labels');
        if ~exist(img_dir,'dir'), mkdir(img_dir); end
        if ~exist(lbl_dir,'dir'), mkdir(lbl_dir); end
    end
end

%% ── Map variant index to conversion function ─────────────────────────────
convert_fns = {@rgb_to_ygb, @rgb_to_lgb};

%% ── Main conversion loop ─────────────────────────────────────────────────
for d = 1:2
    fn    = convert_fns{d};
    odir  = out_dirs{d};
    
    fprintf('\n[%s] Starting...\n', odir);

    for s = 1:3
        sp       = splits{s};
        src_idir = fullfile(src_root, sp, 'images');
        src_ldir = fullfile(src_root, sp, 'labels');
        dst_idir = fullfile(odir, sp, 'images');
        dst_ldir = fullfile(odir, sp, 'labels');

        img_files = dir(fullfile(src_idir, '*.jpg'));
        n         = numel(img_files);

        fprintf('  [%s / %s] %d images\n', odir, sp, n);
        tic;

        for i = 1:n
            fname = img_files(i).name;
            stem  = strrep(fname, '.jpg', '');

            % ── Convert and save image ────────────────────────────────────
            src_img = imread(fullfile(src_idir, fname));
            
            % Special handling for OKLab (returns two outputs)
            if d == 4
                % rgb_to_oklab_full returns [oklab_normalized, oklab_visual]
                % Use oklab_normalized for the dataset
                [dst_img, ~] = fn(src_img);
            else
                dst_img = fn(src_img);
            end
            
            out_path = fullfile(dst_idir, fname);
            imwrite(dst_img, out_path, 'Quality', 95);

            % ── Copy label ────────────────────────────────────────────────
            src_lbl = fullfile(src_ldir, [stem '.txt']);
            dst_lbl = fullfile(dst_ldir, [stem '.txt']);
            if isfile(src_lbl)
                copyfile(src_lbl, dst_lbl);
            end

            % Progress every 500 images
            if mod(i, 500) == 0
                elapsed = toc;
                eta     = elapsed / i * (n - i);
                fprintf('    %d/%d — %.1f img/s — ETA: %.0fs\n', ...
                    i, n, i/elapsed, eta);
            end
        end

        fprintf('  [%s / %s] Done in %.1fs\n', odir, sp, toc);
    end

    fprintf('[%s] Complete.\n', odir);
end

fprintf('\nAll datasets built successfully:\n');
fprintf('  - YGB\n');
fprintf('  - LGB\n');
