% rgb_passthrough.m
% Returns the image unchanged.
% Exists so all three pipelines share the same calling interface.
% Input/output: H x W x 3 uint8

function out = rgb_passthrough(img_rgb)
    out = img_rgb;
end
