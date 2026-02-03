function [frequencies, power] = compute_psd(data, fs, varargin)
% COMPUTE_PSD Compute power spectral density of signal
%
% Syntax:
%   [frequencies, power] = compute_psd(data, fs)
%   [frequencies, power] = compute_psd(data, fs, 'Name', Value, ...)
%
% Inputs:
%   data - Signal data (can be vector or matrix)
%          If matrix, each row is a channel
%   fs - Sampling rate (Hz)
%
% Optional Name-Value Pairs:
%   'Method' - 'pwelch' (default) or 'periodogram'
%   'Window' - Window length for pwelch (default: 2^nextpow2(fs))
%   'Overlap' - Overlap percentage for pwelch (default: 50)
%   'NFFT' - Number of FFT points (default: max(256, 2^nextpow2(window)))
%
% Outputs:
%   frequencies - Frequency vector (Hz), length NFFT/2+1
%   power - Power spectral density
%           If data is vector: power is vector of length NFFT/2+1
%           If data is matrix: power is matrix of size [n_channels, NFFT/2+1]
%
% Example:
%   [f, psd] = compute_psd(signal, 4800);
%   plot(f, 10*log10(psd));
%
% Requirements: 2.1
% Property 6: PSD Computation Format

% Parse inputs
p = inputParser;
addRequired(p, 'data', @isnumeric);
addRequired(p, 'fs', @(x) isscalar(x) && x > 0);
addParameter(p, 'Method', 'pwelch', @(x) ismember(x, {'pwelch', 'periodogram'}));
addParameter(p, 'Window', [], @(x) isempty(x) || (isscalar(x) && x > 0));
addParameter(p, 'Overlap', 50, @(x) isscalar(x) && x >= 0 && x < 100);
addParameter(p, 'NFFT', [], @(x) isempty(x) || (isscalar(x) && x > 0));
parse(p, data, fs, varargin{:});

method = p.Results.Method;
window_length = p.Results.Window;
overlap_pct = p.Results.Overlap;
nfft = p.Results.NFFT;

% Handle data dimensions
if isvector(data)
    data = data(:)';  % Ensure row vector
    n_channels = 1;
else
    n_channels = size(data, 1);
end

% Set default window length
if isempty(window_length)
    window_length = 2^nextpow2(fs);  % 1 second window
end

% Ensure window length doesn't exceed data length
n_samples = size(data, 2);
if window_length > n_samples
    window_length = n_samples;
end

% Set default NFFT
if isempty(nfft)
    nfft = max(256, 2^nextpow2(window_length));
end

% Calculate overlap in samples
overlap_samples = round(window_length * overlap_pct / 100);

% Compute PSD based on method
switch method
    case 'pwelch'
        % Use Welch's method for better noise reduction
        window = hamming(window_length);
        
        % Compute PSD for each channel
        power = zeros(n_channels, nfft/2 + 1);
        for ch = 1:n_channels
            [power(ch, :), frequencies] = pwelch(data(ch, :), window, ...
                overlap_samples, nfft, fs);
        end
        
    case 'periodogram'
        % Use periodogram for simple FFT-based PSD
        window = hamming(n_samples);
        
        % Compute PSD for each channel
        power = zeros(n_channels, nfft/2 + 1);
        for ch = 1:n_channels
            [power(ch, :), frequencies] = periodogram(data(ch, :), window, ...
                nfft, fs);
        end
end

% If single channel, return as vector
if n_channels == 1
    power = power(:);
end

% Ensure frequencies is column vector
frequencies = frequencies(:);

end
