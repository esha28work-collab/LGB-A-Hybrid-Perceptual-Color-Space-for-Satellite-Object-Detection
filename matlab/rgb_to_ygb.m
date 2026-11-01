% rgb_to_ygb.m
% Replaces the R channel with the YCbCr luminance channel Y.
%
% THEORY (DIP):
% Y is a weighted linear combination of R, G, B:
%   Y = 0.299*R + 0.587*G + 0.114*B
%
% The weights come from ITU-R BT.601 and reflect human cone sensitivity —
% our eyes are most sensitive to green, then red, then blue.
% Satellite images are sRGB encoded, so this is applied in gamma space
% (same as BT.601 standard practice for standard-gamut imagery).
%
% For SIMD: The Y channel extracts the structural brightness signal
% from overhead vehicle images — roof texture, shadow edges, and shape
% outlines — without the color noise introduced by ground material variation.
%
% Input:  img_rgb — H x W x 3 uint8  (sRGB)
% Output: ygb     — H x W x 3 uint8  [Y | G | B]

function ygb = rgb_to_ygb(img_rgb)
    img = im2double(img_rgb);       % uint8 [0,255] → double [0.0, 1.0]
                                    % MUST do this before weighted sum —
                                    % uint8 arithmetic clips at 255

    R = img(:,:,1);
    G = img(:,:,2);
    B = img(:,:,3);

    % Weighted luminance — produces a 2D matrix (single channel)
    Y = 0.299*R + 0.587*G + 0.114*B;

    % cat(3,...) stacks three 2D matrices into H x W x 3
    % Y goes into position 1 (replaces R), G and B stay identical
    ygb = cat(3, Y, G, B);

    ygb = im2uint8(ygb);            % double [0,1] → uint8 [0,255]
end