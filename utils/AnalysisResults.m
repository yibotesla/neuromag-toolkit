classdef AnalysisResults
    % AnalysisResults - Data structure for analysis results
    %
    % Properties:
    %   psd             - struct with fields: frequencies, power
    %   snr             - struct with fields: frequency, snr_db
    %   grand_average   - N_channels × N_samples_per_trial
    %   convergence     - struct with fields: n_trials, correlation
    
    properties
        psd             % struct
        snr             % struct
        grand_average   % N_channels × N_samples_per_trial
        convergence     % struct
    end
    
    methods
        function obj = AnalysisResults()
            % Constructor - initialize empty AnalysisResults structure
            obj.psd = struct('frequencies', [], 'power', []);
            obj.snr = struct('frequency', [], 'snr_db', []);
            obj.grand_average = [];
            obj.convergence = struct('n_trials', [], 'correlation', []);
        end
        
        function obj = set_psd(obj, frequencies, power)
            % Set PSD results
            % Inputs:
            %   frequencies - frequency vector
            %   power       - power vector
            obj.psd.frequencies = frequencies;
            obj.psd.power = power;
        end
        
        function obj = set_snr(obj, frequency, snr_db)
            % Set SNR results
            % Inputs:
            %   frequency - target frequency (Hz)
            %   snr_db    - SNR in dB
            obj.snr.frequency = frequency;
            obj.snr.snr_db = snr_db;
        end
        
        function obj = set_convergence(obj, n_trials, correlation)
            % Set convergence analysis results
            % Inputs:
            %   n_trials    - vector of trial numbers tested
            %   correlation - vector of correlation coefficients
            obj.convergence.n_trials = n_trials;
            obj.convergence.correlation = correlation;
        end
    end
end
