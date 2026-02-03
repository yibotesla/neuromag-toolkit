function data_out = remove_dc(data_in)
    % REMOVE_DC 从脑磁图通道数据中去除直流分量
    %
    % 语法:
    %   data_out = remove_dc(data_in)
    %
    % 输入:
    %   data_in - N_channels × N_samples的脑磁图数据矩阵
    %
    % 输出:
    %   data_out - N_channels × N_samples的去除直流分量后的矩阵
    %
    % 描述:
    %   独立地从每个通道中去除直流分量(均值)。
    %   对于每个通道,从所有采样点中减去该通道的均值。
    %
    % 需求: 1.3
    %
    % 示例:
    %   meg_data_clean = remove_dc(meg_data_raw);
    
    % 验证输入
    if isempty(data_in)
        error('MEG:Preprocessor:EmptyInput', 'Input data is empty');
    end
    
    if ~isnumeric(data_in)
        error('MEG:Preprocessor:InvalidInput', 'Input data must be numeric');
    end
    
    % 从每个通道中去除直流分量
    % 从每一行(通道)中减去该行的均值
    data_out = data_in - mean(data_in, 2);
    
end
