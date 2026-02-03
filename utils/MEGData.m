classdef MEGData
    % MEGData - Core data structure for MEG signal data
    % 
    % Properties:
    %   meg_channels    - 64×N double, MEG channel data
    %   ref_channels    - 3×N double, reference sensor data
    %   stimulus        - 1×N double, stimulus signal
    %   trigger         - 1×N double, trigger signal
    %   time            - 1×N double, time axis
    %   fs              - scalar, sampling rate (Hz)
    %   gain            - scalar, gain conversion factor (V to T)
    %   channel_labels  - 64×1 cell, channel labels
    %   bad_channels    - 1×M double, bad channel indices
    
    properties
        meg_channels    % 64×N double
        ref_channels    % 3×N double
        stimulus        % 1×N double
        trigger         % 1×N double
        time            % 1×N double
        fs              % scalar
        gain            % scalar
        channel_labels  % 64×1 cell
        bad_channels    % 1×M double
    end
    
    methods
        function obj = MEGData()
            % Constructor - initialize empty MEGData structure
            obj.meg_channels = [];
            obj.ref_channels = [];
            obj.stimulus = [];
            obj.trigger = [];
            obj.time = [];
            obj.fs = [];
            obj.gain = [];
            obj.channel_labels = cell(64, 1);
            obj.bad_channels = [];
        end
        
        function obj = set_channel_labels(obj)
            % Generate default channel labels
            for i = 1:64
                obj.channel_labels{i} = sprintf('MEG%03d', i);
            end
        end
    end
end
