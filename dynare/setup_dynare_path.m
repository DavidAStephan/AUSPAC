function setup_dynare_path()
%% setup_dynare_path — Ensure Dynare 6.5 is on the MATLAB path.
% Resolution order:
%   1. already on path (no-op)
%   2. DYNARE_PATH environment variable
%   3. OS-specific default install locations

if ~isempty(which('dynare'))
    return;
end

envpath = getenv('DYNARE_PATH');
if ~isempty(envpath) && exist(envpath, 'dir')
    addpath(envpath);
    return;
end

if ispc
    candidates = { ...
        'C:\dynare\6.5\matlab', ...
        'C:\Program Files\Dynare\6.5\matlab'};
elseif ismac
    candidates = { ...
        '/Applications/Dynare/6.5-x86_64/matlab', ...
        '/Applications/Dynare/6.5-arm64/matlab'};
else
    candidates = { ...
        '/usr/lib/dynare/matlab', ...
        '/usr/share/dynare/matlab'};
end

for k = 1:numel(candidates)
    if exist(candidates{k}, 'dir')
        addpath(candidates{k});
        return;
    end
end

error('setup_dynare_path:notfound', ...
    ['Dynare 6.5 not found. Set the DYNARE_PATH environment variable ' ...
     'or install Dynare at a standard location.']);
end
