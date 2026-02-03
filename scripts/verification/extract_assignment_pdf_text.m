function out_path = extract_assignment_pdf_text(varargin)
%EXTRACT_ASSIGNMENT_PDF_TEXT 从“⼤作业题目.pdf”提取文本并写入 docs/
%
% 用法:
%   out_path = extract_assignment_pdf_text();
%   out_path = extract_assignment_pdf_text('PdfPath', '大作业题目.pdf');
%   out_path = extract_assignment_pdf_text('PdfPath', '大作业题目.pdf', ...
%       'OutputPath', fullfile('docs', 'ASSIGNMENT_REQUIREMENTS_EXTRACTED.txt'));
%
% 说明:
% - 优先使用 MATLAB 的 extractFileText（若可用）。
% - 若 extractFileText 不可用/失败，则尝试调用系统命令 pdftotext（需要已安装并加入 PATH，例如 Poppler）。
% - 若 PDF 为扫描图片而非可复制文本，上述两种方式可能无法得到有效结果，此时需 OCR（本脚本会给出提示）。
%
% 输出:
%   out_path: 写出的文本文件路径（默认 docs/ASSIGNMENT_REQUIREMENTS_EXTRACTED.txt）

p = inputParser;
addParameter(p, 'PdfPath', '大作业题目.pdf', @(x) ischar(x) || isstring(x));
addParameter(p, 'OutputPath', fullfile('docs', 'ASSIGNMENT_REQUIREMENTS_EXTRACTED.txt'), @(x) ischar(x) || isstring(x));
addParameter(p, 'ForcePdftotext', false, @islogical);
parse(p, varargin{:});

pdf_path = char(p.Results.PdfPath);
out_path = char(p.Results.OutputPath);
force_pdftotext = p.Results.ForcePdftotext;

if exist(pdf_path, 'file') ~= 2
    error('未找到 PDF 文件: %s', pdf_path);
end

out_dir = fileparts(out_path);
if ~isempty(out_dir) && exist(out_dir, 'dir') ~= 7
    mkdir(out_dir);
end

txt = '';
used_method = '';

% 方法1：MATLAB extractFileText（若存在且不强制使用 pdftotext）
if ~force_pdftotext && exist('extractFileText', 'file') == 2
    try
        txt = extractFileText(pdf_path);
        used_method = 'extractFileText';
    catch ME
        txt = '';
        used_method = sprintf('extractFileText(失败: %s)', ME.message);
    end
end

% 方法2：系统 pdftotext（Poppler），写入文件
if isempty(txt)
    cmd = sprintf('pdftotext -layout "%s" "%s"', pdf_path, out_path);
    [status, cmdout] = system(cmd);
    if status == 0
        used_method = 'pdftotext';
        try
            txt = fileread(out_path);
        catch
            txt = '';
        end
    else
        if isempty(used_method)
            used_method = sprintf('pdftotext(失败: %s)', strtrim(cmdout));
        else
            used_method = sprintf('%s; pdftotext(失败: %s)', used_method, strtrim(cmdout));
        end
    end
end

% 若已经得到文本但尚未写出（extractFileText 路径）
if ~isempty(txt)
    fid = fopen(out_path, 'w', 'n', 'UTF-8');
    if fid < 0
        error('无法写入输出文件: %s', out_path);
    end
    cleanup = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', txt);
end

fprintf('PDF 文本提取完成。方法: %s\n输出: %s\n', used_method, out_path);

if isempty(txt)
    warning(['未能提取到有效文本。若 PDF 为扫描图片，请考虑使用 OCR 工具（例如 tesseract）先将其转为可选文本，', ...
        '或将题目要求以纯文本粘贴到仓库中以便进一步自动对齐。']);
end
end

