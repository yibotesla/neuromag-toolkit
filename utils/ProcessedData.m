classdef ProcessedData
    % ProcessedData - Data structure for processed MEG signals
    %
    % Properties:
    %   data            - N_channels × N_samples, processed data
    %   time            - 1×N_samples, time axis
    %   fs              - scalar, sampling rate (Hz)
    %   channel_labels  - N_channels×1 cell, channel labels
    %   processing_log  - cell array, processing steps record
    
    properties
        data            % N_channels × N_samples
        time            % 1×N_samples
        fs              % scalar
        channel_labels  % N_channels×1 cell
        processing_log  % cell array
    end
    
    methods
        function obj = ProcessedData()
            % Constructor - initialize empty ProcessedData structure
            obj.data = [];
            obj.time = [];
            obj.fs = [];
            obj.channel_labels = {};
            obj.processing_log = {};
        end
        
        function obj = add_processing_step(obj, step_description)
            % Add a processing step to the log
            % Input:
            %   step_description - string describing the processing step
            timestamp = datetime('now');
            log_entry = sprintf('[%s] %s', ...
                datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                step_description);
            obj.processing_log{end+1} = log_entry;
        end
    end
end
