% rgb_to_lgb.m
% Replaces the R channel with OKLab perceptual lightness L.
%
% THEORY (DIP + Color Science):
% OKLab (Ottosson, 2020) is a perceptually uniform color space.
% "Perceptually uniform" means equal numerical steps produce equal
% perceived differences — something RGB and YCbCr does NOT guarantee.
%
% The pipeline has 4 steps:
%   1. Remove sRGB gamma  → linear light values
%   2. Linear RGB → LMS-like cone space  (matrix M1)
%   3. Cube root compression  → approximates human log-response
%   4. LMS-like → OKLab  (matrix M2)  → extract L
%
% For SIMD: Satellite images have subtle reflectance differences between
% vehicle rooftops and background. OKLab's L channel should preserve these
% perceptual boundaries more cleanly than either R or Y, because it is
% calibrated to match actual human contrast sensitivity.
%
% Input:  img_rgb — H x W x 3 uint8  (sRGB)
% Output: lgb     — H x W x 3 uint8  [L | G | B]

function lgb = rgb_to_lgb(img_rgb)
    img = im2double(img_rgb);

    R = img(:,:,1);
    G = img(:,:,2);
    B = img(:,:,3);

    %  Step 1Remove sRGB gamma 
    % sRGB encodes light with a gamma curve for display efficiency.
    % Color math must be done in linear light — this undoes the gamma.
    % (DIPnote: this is the same linearization step used before any
    %  physically-based image operation, correct image compositing)
    R_lin = srgb_to_linear(R);
    G_lin = srgb_to_linear(G);
    B_lin = srgb_to_linear(B);

    % step 2: Linear RGB → LMS-like intermediate (M1 matrix)
    % This rotates the RGB color cube toward a cone-response representation.
    % Coefficients are from the OKLab specification (oklab.org).
    l = 0.4122214708*R_lin + 0.5363325363*G_lin + 0.0514459929*B_lin;
    m = 0.2119034982*R_lin + 0.6806995451*G_lin + 0.1073969566*B_lin;
    s = 0.0883024619*R_lin + 0.2817188376*G_lin + 0.6299787005*B_lin;

    % Step 3: Cube root compression
    % Weber's Law: humans perceive relative differences, not absolute ones
    % Cube root is a computationally simple approximation of the log response
    % real() protects against tiny negative values from floating-point 
    % (a value like -1e-15 would produce NaN without it)
    l_ = real(l .^ (1/3));
    m_ = real(m .^ (1/3));
    s_ = real(s .^ (1/3));

    % Step 4: Apply M2 matrix → get L
    % We only compute L (the lightness axis). a and b (chroma axes) are
    % discarded — we keep the original G and B from sRGB instead.
    L_oklab = 0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_;

    % Step 5: Assemble LGB
    % L replaces R. G and B from the ORIGINAL sRGB image are kept unchanged,
    % exactly as YGB keeps its G and B. This makes the two conversions
    % structurally symmetric — only Ch1 differs between YGB and LGB.
    lgb = cat(3, L_oklab, G, B);
    lgb = max(0, min(1, lgb));      % clamp — cube root can drift slightly
    lgb = im2uint8(lgb);
end

% Helper function
function out = srgb_to_linear(c)
    % IEC 61966-2-1 inverse gamma (standard sRGB linearization)
    % Two-segment: linear for low values, power curve for the rest
    out          = zeros(size(c), 'double');
    mask         = c <= 0.04045;
    out( mask)   = c(mask) / 12.92;
    out(~mask)   = ((c(~mask) + 0.055) / 1.055) .^ 2.4;
end