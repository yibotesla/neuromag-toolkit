function save_figures(filename, fig_handles, varargin)
    % save_figures - Save MATLAB figures to PNG and/or PDF format
    %
    % Syntax:
    %   save_figures(filename, fig_handles)
    %   save_figures(filename, fig_handles, 'Format', format)
    %   save_figures(filename, fig_handles, 'Format', format, 'Resolution', dpi)
    %
    % Inputs:
    %   filename    - Output file path (without extension) or cell array of paths
    %   fig_handles - Figure handle(s) to save (scalar or vector)
    %   
    % Optional Name-Value Pairs:
    %   'Format'     - Output format: 'png', 'pdf', or 'both' (default: 'both')
    %   'Resolution' - DPI for PNG output (default: 300)
    %   'PaperSize'  - Paper size for PDF: 'letter', 'a4', 'auto' (default: 'auto')
    %
    % Examples:
    %   save_figures('figure1', gcf)
    %   save_figures('figure1', gcf, 'Format', 'png')
    %   save_figures({'fig1', 'fig2'}, [fig1, fig2], 'Resolution', 600)
    %
    % Requirements: 7.5
    
    % Parse input arguments
    p = inputParser;
    addRequired(p, 'filename');
    addRequired(p, 'fig_handles');
    addParameter(p, 'Format', 'both', @(x) ismember(lower(x), {'png', 'pdf', 'both'}));
    addParameter(p, 'Resolution', 300, @(x) isnumeric(x) && x > 0);
    addParameter(p, 'PaperSize', 'auto', @(x) ismember(lower(x), {'letter', 'a4', 'auto'}));
    
    parse(p, filename, fig_handles, varargin{:});
    
    format_type = lower(p.Results.Format);
    resolution = p.Results.Resolution;
    paper_size = lower(p.Results.PaperSize);
    
    % Validate figure handles
    if ~all(isgraphics(fig_handles, 'figure'))
        error('MEG:SaveFigures:InvalidHandle', ...
            'All handles must be valid figure handles.');
    end
    
    % Convert filename to cell array if needed
    if ischar(filename) || isstring(filename)
        if length(fig_handles) == 1
            filenames = {char(filename)};
        else
            % Multiple figures, one filename - append numbers
            [filepath, name, ~] = fileparts(filename);
            filenames = cell(1, length(fig_handles));
            for i = 1:length(fig_handles)
                filenames{i} = fullfile(filepath, sprintf('%s_%d', name, i));
            end
        end
    elseif iscell(filename)
        filenames = filename;
        if length(filenames) ~= length(fig_handles)
            error('MEG:SaveFigures:LengthMismatch', ...
                'Number of filenames must match number of figure handles.');
        end
    else
        error('MEG:SaveFigures:InvalidFilename', ...
            'Filename must be a string or cell array of strings.');
    end
    
    % Save each figure
    for i = 1:length(fig_handles)
        fig = fig_handles(i);
        base_filename = filenames{i};
        
        % Remove extension if present
        [filepath, name, ~] = fileparts(base_filename);
        
        % Create directory if it doesn't exist
        if ~isempty(filepath) && ~exist(filepath, 'dir')
            mkdir(filepath);
        end
        
        % Prepare figure for export
        prepare_figure_for_export(fig, paper_size);
        
        % Save PNG
        if strcmp(format_type, 'png') || strcmp(format_type, 'both')
            png_filename = fullfile(filepath, [name, '.png']);
            try
                print(fig, png_filename, '-dpng', sprintf('-r%d', resolution));
                fprintf('Figure saved to: %s\n', png_filename);
            catch ME
                warning('MEG:SaveFigures:PNGFailed', ...
                    'Failed to save PNG: %s', ME.message);
            end
        end
        
        % Save PDF
        if strcmp(format_type, 'pdf') || strcmp(format_type, 'both')
            pdf_filename = fullfile(filepath, [name, '.pdf']);
            try
                print(fig, pdf_filename, '-dpdf', '-bestfit');
                fprintf('Figure saved to: %s\n', pdf_filename);
            catch ME
                warning('MEG:SaveFigures:PDFFailed', ...
                    'Failed to save PDF: %s', ME.message);
            end
        end
    end
end

function prepare_figure_for_export(fig, paper_size)
    % Prepare figure properties for high-quality export
    
    % Set paper properties for PDF
    fig.PaperPositionMode = 'auto';
    
    switch paper_size
        case 'letter'
            fig.PaperSize = [8.5 11];
            fig.PaperUnits = 'inches';
        case 'a4'
            fig.PaperSize = [8.27 11.69];
            fig.PaperUnits = 'inches';
        case 'auto'
            % Use figure's current size
            fig.PaperUnits = 'inches';
            fig_pos = fig.Position;
            fig.PaperSize = [fig_pos(3)/96, fig_pos(4)/96];  % Convert pixels to inches (96 DPI)
    end
    
    % Set renderer for better quality
    fig.Renderer = 'painters';  % Vector graphics for PDF
    
    % Ensure background is white
    fig.Color = 'white';
end
