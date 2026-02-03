function [peak_detected, peak_freq, peak_power, peak_idx] = detect_peak_at_frequency(data, fs, target_freq, varargin)
% DETECT_PEAK_AT_FREQUENCY Detect spectral peak at target frequency
%
% Syntax:
%   peak_detected = detect_peak_at_frequency(data, fs, target_freq)
%   peak_detected = detect_peak_at_frequency(data, fs, target_freq, 'Name', Value, ...)
%   [peak_detected, peak_freq, peak_power, peak_idx] = detect_peak_at_frequency(...)
%
% Inputs:
%   data - Signal data (can be vector or matrix)
%          If matrix, each row is a channel
%   fs - Sampling rate (Hz)
%   target_freq - Target frequency to search for peak (Hz)
%
% Optional Name-Value Pairs:
%   'Tolerance' - Frequency tolerance (Hz, default: 0.5)
%   'MinPeakHeight' - Minimum peak height relative to mean (default: 2.0)
%   'MinPeakProminence' - Minimum peak prominence (default: [])
%   'Method' - PSD method: 'pwelch' (default) or 'periodogram'
%   'SearchBandwidth' - Bandwidth to search for peak (Hz, default: 2*Tolerance)
%
% Outputs:
%   peak_detected - Logical indicating if peak was detected
%                   If data is vector: scalar logical
%                   If data is matrix: logical vector of length n_channels
%   peak_freq - Frequency of detected peak (Hz)
%               If no peak detected, returns NaN
%   peak_power - Power at detected peak
%                If no peak detected, returns NaN
%   peak_idx - Index of peak in PSD frequency vector
%              If no peak detected, returns NaN
%
% Example:
%   % Detect 17Hz peak
%   detected = detect_peak_at_frequency(signal, 4800, 17);
%   
%   % Detect with custom tolerance
%   [detected, freq, power] = detect_peak_at_frequency(signal, 4800, 17, ...
%       'Tolerance', 1.0, 'MinPeakHeight', 3.0);
%
% Algorithm:
%   1. Compute PSD of signal
%   2. Define search region: [target_freq - tolerance, target_freq + tolerance]
%   3. Find local maxima in search region
%   4. Verify peak meets minimum height criteria
%   5. Select highest peak if multiple peaks found
%
% Requirements: 2.3
% Property 8: Peak Detection at 17Hz

% Parse inputs
p = inputParser;
addRequired(p, 'data', @isnumeric);
addRequired(p, 'fs', @(x) isscalar(x) && x > 0);
addRequired(p, 'target_freq', @(x) isscalar(x) && x > 0 && x < fs/2);
addParameter(p, 'Tolerance', 0.5, @(x) isscalar(x) && x > 0);
addParameter(p, 'MinPeakHeight', 2.0, @(x) isscalar(x) && x > 0);
addParameter(p, 'MinPeakProminence', [], @(x) isempty(x) || (isscalar(x) && x > 0));
addParameter(p, 'Method', 'pwelch', @(x) ismember(x, {'pwelch', 'periodogram'}));
addParameter(p, 'SearchBandwidth', [], @(x) isempty(x) || (isscalar(x) && x > 0));
parse(p, data, fs, target_freq, varargin{:});

tolerance = p.Results.Tolerance;
min_peak_height = p.Results.MinPeakHeight;
min_peak_prominence = p.Results.MinPeakProminence;
method = p.Results.Method;
search_bw = p.Results.SearchBandwidth;

% Set default search bandwidth
if isempty(search_bw)
    search_bw = 2 * tolerance;
end

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

% Define search region
search_low = target_freq - search_bw/2;
search_high = target_freq + search_bw/2;

% Find indices in search region
search_idx = (frequencies >= search_low) & (frequencies <= search_high);

if sum(search_idx) == 0
    error('MEG:Analyzer:InvalidSearchRegion', ...
        'No frequency bins found in search region [%.2f, %.2f] Hz', ...
        search_low, search_high);
end

% Initialize outputs
peak_detected = false(n_channels, 1);
peak_freq = nan(n_channels, 1);
peak_power = nan(n_channels, 1);
peak_idx = nan(n_channels, 1);

% Detect peaks for each channel
for ch = 1:n_channels
    % Extract PSD in search region
    psd_search = psd(ch, search_idx);
    freq_search = frequencies(search_idx);
    
    % Handle case where search region is too small
    if length(psd_search) < 3
        % If only 1-2 points, check if the maximum is within tolerance
        % and significantly higher than surrounding regions
        [max_power_in_search, max_loc_in_search] = max(psd_search);
        max_freq_in_search = freq_search(max_loc_in_search);
        
        % Check if within tolerance
        if abs(max_freq_in_search - target_freq) <= tolerance
            % Get broader context for comparison
            broader_low = max(1, find(search_idx, 1, 'first') - 10);
            broader_high = min(length(frequencies), find(search_idx, 1, 'last') + 10);
            broader_psd = psd(ch, broader_low:broader_high);
            baseline = median(broader_psd);
            
            % Check if peak is significant
            if max_power_in_search > min_peak_height * baseline
                peak_detected(ch) = true;
                peak_power(ch) = max_power_in_search;
                peak_freq(ch) = max_freq_in_search;
                search_indices = find(search_idx);
                peak_idx(ch) = search_indices(max_loc_in_search);
            end
        end
        continue;
    end
    
    % Calculate baseline for peak detection
    % Use median instead of mean to be more robust to outliers
    baseline = median(psd_search);
    
    % Use findpeaks to detect local maxima
    if ~isempty(min_peak_prominence)
        [peak_powers, peak_locs] = findpeaks(psd_search, ...
            'MinPeakHeight', min_peak_height * baseline, ...
            'MinPeakProminence', min_peak_prominence);
    else
        [peak_powers, peak_locs] = findpeaks(psd_search, ...
            'MinPeakHeight', min_peak_height * baseline);
    end
    
    if isempty(peak_powers)
        % No peaks found with findpeaks, try simple maximum approach
        [max_power_in_search, max_loc_in_search] = max(psd_search);
        max_freq_in_search = freq_search(max_loc_in_search);
        
        % Check if within tolerance and significant
        if abs(max_freq_in_search - target_freq) <= tolerance && ...
           max_power_in_search > min_peak_height * baseline
            peak_detected(ch) = true;
            peak_power(ch) = max_power_in_search;
            peak_freq(ch) = max_freq_in_search;
            search_indices = find(search_idx);
            peak_idx(ch) = search_indices(max_loc_in_search);
        end
        continue;
    end
    
    % Get frequencies of detected peaks
    peak_freqs = freq_search(peak_locs);
    
    % Filter peaks within tolerance of target frequency
    valid_peaks = abs(peak_freqs - target_freq) <= tolerance;
    
    if ~any(valid_peaks)
        % No peaks within tolerance
        continue;
    end
    
    % Select highest peak within tolerance
    valid_peak_powers = peak_powers(valid_peaks);
    valid_peak_freqs = peak_freqs(valid_peaks);
    valid_peak_locs = peak_locs(valid_peaks);
    
    [max_power, max_idx] = max(valid_peak_powers);
    
    % Store results
    peak_detected(ch) = true;
    peak_power(ch) = max_power;
    peak_freq(ch) = valid_peak_freqs(max_idx);
    
    % Convert local index to global index
    search_indices = find(search_idx);
    peak_idx(ch) = search_indices(valid_peak_locs(max_idx));
end

% If single channel, return as scalars
if n_channels == 1
    peak_detected = peak_detected(1);
    peak_freq = peak_freq(1);
    peak_power = peak_power(1);
    peak_idx = peak_idx(1);
end

end
