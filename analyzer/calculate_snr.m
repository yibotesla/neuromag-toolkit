function [snr_db, signal_power, noise_power] = calculate_snr(data, fs, target_freq, varargin)
% CALCULATE_SNR Calculate signal-to-noise ratio at target frequency
%
% Syntax:
%   snr_db = calculate_snr(data, fs, target_freq)
%   snr_db = calculate_snr(data, fs, target_freq, 'Name', Value, ...)
%   [snr_db, signal_power, noise_power] = calculate_snr(...)
%
% Inputs:
%   data - Signal data (can be vector or matrix)
%          If matrix, each row is a channel
%   fs - Sampling rate (Hz)
%   target_freq - Target frequency for signal power calculation (Hz)
%
% Optional Name-Value Pairs:
%   'SignalBandwidth' - Bandwidth around target frequency for signal (Hz, default: 0.5)
%   'NoiseBandwidth' - Bandwidth for noise calculation on each side (Hz, default: 2.0)
%   'NoiseOffset' - Offset from signal band to noise band (Hz, default: 1.0)
%   'Method' - PSD method: 'pwelch' (default) or 'periodogram'
%
% Outputs:
%   snr_db - Signal-to-noise ratio in dB
%            If data is vector: scalar
%            If data is matrix: vector of length n_channels
%   signal_power - Signal power at target frequency
%   noise_power - Noise power from neighboring frequencies
%
% Example:
%   snr = calculate_snr(signal, 4800, 17);  % SNR at 17Hz
%   snr = calculate_snr(signal, 4800, 89, 'SignalBandwidth', 1.0);
%
% Algorithm:
%   1. Compute PSD of signal
%   2. Signal power = mean power in [target_freq - bw/2, target_freq + bw/2]
%   3. Noise power = mean power in neighboring bands:
%      - Lower band: [target_freq - signal_bw/2 - noise_offset - noise_bw, 
%                     target_freq - signal_bw/2 - noise_offset]
%      - Upper band: [target_freq + signal_bw/2 + noise_offset,
%                     target_freq + signal_bw/2 + noise_offset + noise_bw]
%   4. SNR (dB) = 10 * log10(signal_power / noise_power)
%
% Requirements: 2.2
% Property 7: SNR Calculation at Target Frequency

% Parse inputs
p = inputParser;
addRequired(p, 'data', @isnumeric);
addRequired(p, 'fs', @(x) isscalar(x) && x > 0);
addRequired(p, 'target_freq', @(x) isscalar(x) && x > 0 && x < fs/2);
addParameter(p, 'SignalBandwidth', 0.5, @(x) isscalar(x) && x > 0);
addParameter(p, 'NoiseBandwidth', 2.0, @(x) isscalar(x) && x > 0);
addParameter(p, 'NoiseOffset', 1.0, @(x) isscalar(x) && x > 0);
addParameter(p, 'Method', 'pwelch', @(x) ismember(x, {'pwelch', 'periodogram'}));
parse(p, data, fs, target_freq, varargin{:});

signal_bw = p.Results.SignalBandwidth;
noise_bw = p.Results.NoiseBandwidth;
noise_offset = p.Results.NoiseOffset;
method = p.Results.Method;

% Handle data dimensions
if isvector(data)
    data = data(:)';  % Ensure row vector
    n_channels = 1;
else
    n_channels = size(data, 1);
end

% Compute PSD
[frequencies, psd] = compute_psd(data, fs, 'Method', method);

% If single channel, ensure psd is column vector for consistent indexing
if n_channels == 1
    psd = psd(:)';
end

% Define frequency bands
signal_band_low = target_freq - signal_bw/2;
signal_band_high = target_freq + signal_bw/2;

noise_band_low_start = target_freq - signal_bw/2 - noise_offset - noise_bw;
noise_band_low_end = target_freq - signal_bw/2 - noise_offset;

noise_band_high_start = target_freq + signal_bw/2 + noise_offset;
noise_band_high_end = target_freq + signal_bw/2 + noise_offset + noise_bw;

% Ensure noise bands are within valid frequency range
noise_band_low_start = max(noise_band_low_start, frequencies(1));
noise_band_high_end = min(noise_band_high_end, frequencies(end));

% Find indices for signal band
signal_idx = (frequencies >= signal_band_low) & (frequencies <= signal_band_high);

% Find indices for noise bands
noise_idx_low = (frequencies >= noise_band_low_start) & (frequencies <= noise_band_low_end);
noise_idx_high = (frequencies >= noise_band_high_start) & (frequencies <= noise_band_high_end);
noise_idx = noise_idx_low | noise_idx_high;

% Check if we have valid indices
if sum(signal_idx) == 0
    error('MEG:Analyzer:InvalidSignalBand', ...
        'No frequency bins found in signal band [%.2f, %.2f] Hz', ...
        signal_band_low, signal_band_high);
end

if sum(noise_idx) == 0
    error('MEG:Analyzer:InvalidNoiseBand', ...
        'No frequency bins found in noise bands. Try adjusting bandwidth parameters.');
end

% Calculate signal and noise power for each channel
signal_power = zeros(n_channels, 1);
noise_power = zeros(n_channels, 1);
snr_db = zeros(n_channels, 1);

for ch = 1:n_channels
    % Signal power: mean power in signal band
    signal_power(ch) = mean(psd(ch, signal_idx));
    
    % Noise power: mean power in noise bands
    noise_power(ch) = mean(psd(ch, noise_idx));
    
    % SNR in dB
    if noise_power(ch) > 0
        snr_db(ch) = 10 * log10(signal_power(ch) / noise_power(ch));
    else
        snr_db(ch) = Inf;  % Perfect SNR if no noise
    end
end

% If single channel, return as scalars
if n_channels == 1
    snr_db = snr_db(1);
    signal_power = signal_power(1);
    noise_power = noise_power(1);
end

end
