function validate_inputs(varargin)
% VALIDATE_INPUTS Comprehensive input validation utility for MEG processing
%
% Syntax:
%   validate_inputs('param_name', value, 'type', validation_type, ...)
%
% Description:
%   Provides standardized input validation across all MEG processing functions.
%   Validates file existence, data formats, parameter ranges, and data structures.
%
% Validation Types:
%   'file_exists'     - Check if file exists
%   'positive'        - Check if value is positive
%   'non_negative'    - Check if value is non-negative
%   'in_range'        - Check if value is in specified range [min, max]
%   'numeric_scalar'  - Check if value is a numeric scalar
%   'numeric_vector'  - Check if value is a numeric vector
%   'numeric_matrix'  - Check if value is a numeric matrix
%   'string'          - Check if value is a string or char
%   'struct'          - Check if value is a structure
%   'meg_data'        - Check if value is valid MEGData object or struct
%   'processed_data'  - Check if value is valid ProcessedData object
%   'trial_data'      - Check if value is valid TrialData object
%
% Requirements: 8.5
%
% Example:
%   validate_inputs('file_path', path, 'type', 'file_exists');
%   validate_inputs('sampling_rate', fs, 'type', 'positive');
%   validate_inputs('lambda', 0.995, 'type', 'in_range', 'range', [0.99, 1.0]);

% Parse input arguments
p = inputParser;
p.KeepUnmatched = true;

% Process validation requests
i = 1;
while i <= length(varargin)
    if i+1 <= length(varargin) && ischar(varargin{i})
        param_name = varargin{i};
        param_value = varargin{i+1};
        
        % Look for 'type' specification
        if i+3 <= length(varargin) && strcmp(varargin{i+2}, 'type')
            validation_type = varargin{i+3};
            
            % Perform validation based on type
            switch validation_type
                case 'file_exists'
                    validate_file_exists(param_name, param_value);
                    i = i + 4;
                    
                case 'positive'
                    validate_positive(param_name, param_value);
                    i = i + 4;
                    
                case 'non_negative'
                    validate_non_negative(param_name, param_value);
                    i = i + 4;
                    
                case 'in_range'
                    % Look for range specification
                    if i+5 <= length(varargin) && strcmp(varargin{i+4}, 'range')
                        range_val = varargin{i+5};
                        validate_in_range(param_name, param_value, range_val);
                        i = i + 6;
                    else
                        error('MEG:Validation:MissingRange', ...
                            'Range specification required for in_range validation');
                    end
                    
                case 'numeric_scalar'
                    validate_numeric_scalar(param_name, param_value);
                    i = i + 4;
                    
                case 'numeric_vector'
                    validate_numeric_vector(param_name, param_value);
                    i = i + 4;
                    
                case 'numeric_matrix'
                    validate_numeric_matrix(param_name, param_value);
                    i = i + 4;
                    
                case 'string'
                    validate_string(param_name, param_value);
                    i = i + 4;
                    
                case 'struct'
                    validate_struct(param_name, param_value);
                    i = i + 4;
                    
                case 'meg_data'
                    validate_meg_data(param_name, param_value);
                    i = i + 4;
                    
                case 'processed_data'
                    validate_processed_data(param_name, param_value);
                    i = i + 4;
                    
                case 'trial_data'
                    validate_trial_data(param_name, param_value);
                    i = i + 4;
                    
                otherwise
                    error('MEG:Validation:UnknownType', ...
                        'Unknown validation type: %s', validation_type);
            end
        else
            i = i + 2;
        end
    else
        i = i + 1;
    end
end

end

%% Helper validation functions

function validate_file_exists(param_name, file_path)
    if ~ischar(file_path) && ~isstring(file_path)
        error('MEG:Validation:InvalidType', ...
            '%s must be a string or char array', param_name);
    end
    
    if ~exist(file_path, 'file')
        error('MEG:Validation:FileNotFound', ...
            'File not found: %s\nParameter: %s\nPlease check the file path.', ...
            file_path, param_name);
    end
end

function validate_positive(param_name, value)
    if ~isnumeric(value) || ~isscalar(value) || value <= 0
        error('MEG:Validation:NotPositive', ...
            '%s must be a positive numeric scalar, got: %s', ...
            param_name, mat2str(value));
    end
end

function validate_non_negative(param_name, value)
    if ~isnumeric(value) || ~isscalar(value) || value < 0
        error('MEG:Validation:NotNonNegative', ...
            '%s must be a non-negative numeric scalar, got: %s', ...
            param_name, mat2str(value));
    end
end

function validate_in_range(param_name, value, range)
    if ~isnumeric(value) || ~isscalar(value)
        error('MEG:Validation:NotScalar', ...
            '%s must be a numeric scalar', param_name);
    end
    
    if length(range) ~= 2
        error('MEG:Validation:InvalidRange', ...
            'Range must be a 2-element vector [min, max]');
    end
    
    if value < range(1) || value > range(2)
        error('MEG:Validation:OutOfRange', ...
            '%s must be in range [%.4f, %.4f], got: %.4f', ...
            param_name, range(1), range(2), value);
    end
end

function validate_numeric_scalar(param_name, value)
    if ~isnumeric(value) || ~isscalar(value)
        error('MEG:Validation:NotNumericScalar', ...
            '%s must be a numeric scalar', param_name);
    end
end

function validate_numeric_vector(param_name, value)
    if ~isnumeric(value) || ~isvector(value)
        error('MEG:Validation:NotNumericVector', ...
            '%s must be a numeric vector', param_name);
    end
end

function validate_numeric_matrix(param_name, value)
    if ~isnumeric(value) || ndims(value) > 2
        error('MEG:Validation:NotNumericMatrix', ...
            '%s must be a 2D numeric matrix', param_name);
    end
end

function validate_string(param_name, value)
    if ~ischar(value) && ~isstring(value)
        error('MEG:Validation:NotString', ...
            '%s must be a string or char array', param_name);
    end
end

function validate_struct(param_name, value)
    if ~isstruct(value)
        error('MEG:Validation:NotStruct', ...
            '%s must be a structure', param_name);
    end
end

function validate_meg_data(param_name, value)
    % Check if it's a MEGData object or valid structure
    if isa(value, 'MEGData')
        return;  % Valid MEGData object
    end
    
    if ~isstruct(value)
        error('MEG:Validation:InvalidMEGData', ...
            '%s must be a MEGData object or structure', param_name);
    end
    
    % Check required fields
    required_fields = {'meg_channels', 'time', 'fs'};
    for i = 1:length(required_fields)
        if ~isfield(value, required_fields{i})
            error('MEG:Validation:MissingField', ...
                '%s structure missing required field: %s', ...
                param_name, required_fields{i});
        end
    end
    
    % Validate field types
    if ~isnumeric(value.meg_channels) || ndims(value.meg_channels) > 2
        error('MEG:Validation:InvalidField', ...
            '%s.meg_channels must be a 2D numeric matrix', param_name);
    end
    
    if ~isnumeric(value.time) || ~isvector(value.time)
        error('MEG:Validation:InvalidField', ...
            '%s.time must be a numeric vector', param_name);
    end
    
    if ~isscalar(value.fs) || ~isnumeric(value.fs) || value.fs <= 0
        error('MEG:Validation:InvalidField', ...
            '%s.fs must be a positive numeric scalar', param_name);
    end
end

function validate_processed_data(param_name, value)
    if ~isa(value, 'ProcessedData')
        error('MEG:Validation:InvalidProcessedData', ...
            '%s must be a ProcessedData object', param_name);
    end
end

function validate_trial_data(param_name, value)
    if ~isa(value, 'TrialData')
        error('MEG:Validation:InvalidTrialData', ...
            '%s must be a TrialData object', param_name);
    end
end
