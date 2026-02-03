function save_processed_data(filename, varargin)
    % save_processed_data - Save processed MEG data structures to MAT file
    %
    % Syntax:
    %   save_processed_data(filename, data1, data2, ...)
    %   save_processed_data(filename, 'VarName1', data1, 'VarName2', data2, ...)
    %
    % Inputs:
    %   filename - Output MAT file path (string)
    %   varargin - Variable number of arguments:
    %              - Data structures to save (MEGData, ProcessedData, TrialData, AnalysisResults)
    %              - Name-value pairs: 'VarName', data_structure
    %
    % Examples:
    %   save_processed_data('output.mat', meg_data, processed_data)
    %   save_processed_data('output.mat', 'raw', meg_data, 'filtered', processed_data)
    %
    % Requirements: 7.5
    
    % Validate filename
    if ~ischar(filename) && ~isstring(filename)
        error('MEG:SaveData:InvalidFilename', ...
            'Filename must be a string or character array.');
    end
    
    % Ensure .mat extension
    [filepath, name, ext] = fileparts(filename);
    if isempty(ext)
        filename = fullfile(filepath, [name, '.mat']);
    elseif ~strcmpi(ext, '.mat')
        warning('MEG:SaveData:ExtensionOverride', ...
            'File extension changed to .mat');
        filename = fullfile(filepath, [name, '.mat']);
    end
    
    % Create directory if it doesn't exist
    if ~isempty(filepath) && ~exist(filepath, 'dir')
        mkdir(filepath);
    end
    
    % Parse input arguments
    save_struct = struct();
    
    if isempty(varargin)
        error('MEG:SaveData:NoData', ...
            'No data provided to save.');
    end
    
    % Check if using name-value pairs or positional arguments
    if mod(length(varargin), 2) == 0 && all(cellfun(@(x) ischar(x) || isstring(x), varargin(1:2:end)))
        % Name-value pairs
        for i = 1:2:length(varargin)
            var_name = varargin{i};
            var_data = varargin{i+1};
            
            % Validate variable name
            if ~isvarname(var_name)
                error('MEG:SaveData:InvalidVarName', ...
                    'Invalid variable name: %s', var_name);
            end
            
            % Convert object to struct for saving
            save_struct.(var_name) = convert_to_saveable(var_data);
        end
    else
        % Positional arguments - auto-generate names
        for i = 1:length(varargin)
            var_data = varargin{i};
            
            % Generate variable name based on class
            if isa(var_data, 'MEGData')
                var_name = sprintf('meg_data_%d', i);
            elseif isa(var_data, 'ProcessedData')
                var_name = sprintf('processed_data_%d', i);
            elseif isa(var_data, 'TrialData')
                var_name = sprintf('trial_data_%d', i);
            elseif isa(var_data, 'AnalysisResults')
                var_name = sprintf('analysis_results_%d', i);
            else
                var_name = sprintf('data_%d', i);
            end
            
            % Convert object to struct for saving
            save_struct.(var_name) = convert_to_saveable(var_data);
        end
    end
    
    % Add metadata
    save_struct.metadata = struct();
    save_struct.metadata.save_date = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    save_struct.metadata.matlab_version = version;
    save_struct.metadata.variable_names = fieldnames(rmfield(save_struct, 'metadata'));
    
    % Save to file
    try
        save(filename, '-struct', 'save_struct', '-v7.3');
        fprintf('Data successfully saved to: %s\n', filename);
    catch ME
        error('MEG:SaveData:SaveFailed', ...
            'Failed to save data to %s: %s', filename, ME.message);
    end
end

function saveable_data = convert_to_saveable(data)
    % Convert object to struct for saving
    % Handles MEGData, ProcessedData, TrialData, AnalysisResults objects
    
    if isobject(data)
        % Convert object to struct
        saveable_data = struct();
        props = properties(data);
        for i = 1:length(props)
            saveable_data.(props{i}) = data.(props{i});
        end
        % Add class information for reconstruction
        saveable_data.original_class = class(data);
    else
        % Already a struct or other data type
        saveable_data = data;
    end
end
