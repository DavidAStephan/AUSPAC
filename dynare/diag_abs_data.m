%% Quick diagnostic for ABS IPD data extraction
addpath('C:\dynare\6.5\matlab');
datadir = 'c:\Users\david\french_model\data\abs_rba';
fid = fopen(fullfile(datadir, 'diag_log.txt'), 'w');

[~, ~, raw] = xlsread(fullfile(datadir, 'abs_5206_ipd.xlsx'), 'Data1');
fprintf(fid, 'IPD sheet size: %d x %d\n', size(raw, 1), size(raw, 2));

% Show first column header
fprintf(fid, '\nRow 1 (headers):\n');
for j = 1:min(10, size(raw, 2))
    if ischar(raw{1, j})
        fprintf(fid, '  Col %d: %s\n', j, raw{1, j}(1:min(80, length(raw{1, j}))));
    else
        fprintf(fid, '  Col %d: (not char) class=%s\n', j, class(raw{1, j}));
    end
end

% Show rows 9-13 to see data start
fprintf(fid, '\nRows 9-13 (col 1 and col 7):\n');
for r = 9:min(13, size(raw, 1))
    fprintf(fid, '  Row %d: col1=%s (class %s), col7=', r, num2str(raw{r, 1}), class(raw{r, 1}));
    if isnumeric(raw{r, 7})
        fprintf(fid, '%.4f', raw{r, 7});
    else
        fprintf(fid, '%s', num2str(raw{r, 7}));
    end
    fprintf(fid, '\n');
end

% Test date conversion
fprintf(fid, '\nDate conversion test (row 11-15):\n');
for r = 11:min(15, size(raw, 1))
    d = raw{r, 1};
    if isnumeric(d) && d > 10000
        dt = datetime(d, 'ConvertFrom', 'excel');
        fprintf(fid, '  Row %d: excel=%d -> %s (Y=%d Q=%d)\n', r, d, datestr(dt), year(dt), quarter(dt));
    else
        fprintf(fid, '  Row %d: value=%s class=%s\n', r, num2str(d), class(d));
    end
end

% Check column 7 data availability
fprintf(fid, '\nColumn 7 data sample (rows 11-20):\n');
for r = 11:min(20, size(raw, 1))
    v = raw{r, 7};
    fprintf(fid, '  Row %d: %s (class %s)\n', r, num2str(v), class(v));
end

% Compare with base_dates
T = readtable('c:\Users\david\french_model\dataset.csv');
bd = datetime(T.date, 'InputFormat', 'yyyy-MM-dd');
fprintf(fid, '\nBase dates sample:\n');
for t = 1:5
    fprintf(fid, '  %s -> Y=%d Q=%d\n', datestr(bd(t)), year(bd(t)), quarter(bd(t)));
end

fclose(fid);
type(fullfile(datadir, 'diag_log.txt'));
