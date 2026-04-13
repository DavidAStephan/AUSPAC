%% diagnose_pac_fields.m
% Inspect oo_.pac structure to find actual field names for h-vectors.
cd('c:\Users\david\french_model\dynare');
addpath('C:\dynare\6.5\matlab');

dynare au_pac noclearall nograph;

fid = fopen('log_pac_diagnosis.txt', 'w');
fprintf(fid, '=== PAC STRUCTURE DIAGNOSIS ===\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now));

% Check if oo_.pac exists
if isfield(oo_, 'pac')
    fprintf(fid, 'oo_.pac EXISTS\n');
    fprintf(fid, 'Fields: ');
    fnames = fieldnames(oo_.pac);
    for i = 1:length(fnames)
        fprintf(fid, '%s ', fnames{i});
    end
    fprintf(fid, '\n\n');

    % Drill into each field
    for i = 1:length(fnames)
        fprintf(fid, '--- oo_.pac.%s ---\n', fnames{i});
        sub = oo_.pac.(fnames{i});
        if isstruct(sub)
            subfields = fieldnames(sub);
            for j = 1:length(subfields)
                val = sub.(subfields{j});
                if isnumeric(val) && numel(val) <= 20
                    fprintf(fid, '  .%s = [%s] (size %dx%d)\n', subfields{j}, num2str(val(:)', '%.6f '), size(val,1), size(val,2));
                elseif isnumeric(val)
                    fprintf(fid, '  .%s = numeric (%dx%d)\n', subfields{j}, size(val,1), size(val,2));
                elseif ischar(val)
                    fprintf(fid, '  .%s = ''%s''\n', subfields{j}, val);
                else
                    fprintf(fid, '  .%s = %s\n', subfields{j}, class(val));
                end
            end
        else
            fprintf(fid, '  (not a struct, class=%s)\n', class(sub));
        end
        fprintf(fid, '\n');
    end
else
    fprintf(fid, 'oo_.pac DOES NOT EXIST\n\n');
    fprintf(fid, 'Top-level oo_ fields:\n');
    fnames = fieldnames(oo_);
    for i = 1:length(fnames)
        fprintf(fid, '  %s\n', fnames{i});
    end
end

% Also check M_.pac — Dynare 6.5 may store PAC info there
fprintf(fid, '\n=== M_.pac ===\n');
if isfield(M_, 'pac')
    fprintf(fid, 'M_.pac EXISTS\n');
    fnames = fieldnames(M_.pac);
    for i = 1:length(fnames)
        fprintf(fid, '--- M_.pac.%s ---\n', fnames{i});
        sub = M_.pac.(fnames{i});
        if isstruct(sub)
            subfields = fieldnames(sub);
            for j = 1:length(subfields)
                val = sub.(subfields{j});
                if isnumeric(val) && numel(val) <= 20
                    fprintf(fid, '  .%s = [%s] (size %dx%d)\n', subfields{j}, num2str(val(:)', '%.6f '), size(val,1), size(val,2));
                elseif isnumeric(val)
                    fprintf(fid, '  .%s = numeric (%dx%d)\n', subfields{j}, size(val,1), size(val,2));
                elseif ischar(val)
                    fprintf(fid, '  .%s = ''%s''\n', subfields{j}, val);
                elseif iscell(val)
                    fprintf(fid, '  .%s = cell (%dx%d)\n', subfields{j}, size(val,1), size(val,2));
                else
                    fprintf(fid, '  .%s = %s\n', subfields{j}, class(val));
                end
            end
        end
        fprintf(fid, '\n');
    end
else
    fprintf(fid, 'M_.pac DOES NOT EXIST\n');
end

fclose(fid);
fprintf('Saved: log_pac_diagnosis.txt\n');
