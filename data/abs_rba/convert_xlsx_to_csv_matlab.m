%% convert_xlsx_to_csv_matlab.m — Convert ABS xlsx to CSV using COM with explicit range
% This avoids the R2019a xlsread hang by reading specific ranges only.
% Run this BEFORE estimate_phase4_abs.m if PowerShell conversion failed.

datadir = fileparts(mfilename('fullpath'));
if isempty(datadir), datadir = fullfile('c:\Users\david\french_model', 'data', 'abs_rba'); end

files = {
    'abs_5206_vol.xlsx', 'abs_5206_vol.csv', 'Data1';
    'abs_6416_rppi.xlsx', 'abs_6416_rppi.csv', 'Data1';
};

for k = 1:size(files, 1)
    xlsx_file = fullfile(datadir, files{k, 1});
    csv_file = fullfile(datadir, files{k, 2});
    sheet = files{k, 3};

    if ~exist(xlsx_file, 'file')
        fprintf('SKIP: %s not found\n', files{k, 1});
        continue;
    end
    if exist(csv_file, 'file')
        d = dir(csv_file);
        fprintf('SKIP: %s already exists (%d bytes)\n', files{k, 2}, d.bytes);
        continue;
    end

    fprintf('Converting %s -> %s...\n', files{k, 1}, files{k, 2});

    try
        % Use actxserver for direct COM control
        excel = actxserver('Excel.Application');
        excel.Visible = false;
        excel.DisplayAlerts = false;

        wb = excel.Workbooks.Open(xlsx_file);
        ws = wb.Sheets.Item(sheet);

        % Get used range dimensions
        ur = ws.UsedRange;
        nrows = ur.Rows.Count;
        ncols = ur.Columns.Count;
        fprintf('  Sheet: %d rows x %d cols\n', nrows, ncols);

        % Read in chunks to avoid COM timeout
        chunk_size = 50;
        fout = fopen(csv_file, 'w');

        for r = 1:chunk_size:nrows
            r_end = min(r + chunk_size - 1, nrows);
            range_str = sprintf('A%d:%s%d', r, xlscol(ncols), r_end);
            data = ws.Range(range_str).Value;

            if ~iscell(data)
                data = {data};
            end

            for ri = 1:size(data, 1)
                for ci = 1:size(data, 2)
                    v = data{ri, ci};
                    if isempty(v) || (isnumeric(v) && isnan(v))
                        % empty
                    elseif isnumeric(v)
                        fprintf(fout, '%g', v);
                    elseif ischar(v)
                        % Escape commas in CSV
                        if contains(v, ',') || contains(v, '"')
                            fprintf(fout, '"%s"', strrep(v, '"', '""'));
                        else
                            fprintf(fout, '%s', v);
                        end
                    end
                    if ci < size(data, 2)
                        fprintf(fout, ',');
                    end
                end
                fprintf(fout, '\n');
            end

            if mod(r, 200) == 1
                fprintf('  Read rows %d-%d of %d\n', r, r_end, nrows);
            end
        end

        fclose(fout);
        wb.Close(false);
        excel.Quit();
        delete(excel);

        d = dir(csv_file);
        fprintf('  OK: %s (%d bytes)\n', files{k, 2}, d.bytes);

    catch ME
        fprintf('  ERROR: %s\n', ME.message);
        try, wb.Close(false); catch, end
        try, excel.Quit(); catch, end
        try, delete(excel); catch, end
    end
end

fprintf('Done.\n');

function col_str = xlscol(n)
    % Convert column number to Excel column letter (1->A, 27->AA, etc.)
    col_str = '';
    while n > 0
        n = n - 1;
        col_str = [char(mod(n, 26) + 'A'), col_str];
        n = floor(n / 26);
    end
end
