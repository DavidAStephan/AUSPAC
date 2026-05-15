function setup_dynare_path()
%% setup_dynare_path — Bootstrap MATLAB path for AUSPAC.
% Adds every dynare/scripts/* source directory to the MATLAB path, then
% ensures Dynare 6.5 is reachable.
%
% Usage: from a driver that has cd'd into dynare/ (or into the repo root):
%   setup_dynare_path();
%
% Dynare resolution order:
%   1. already on path (no-op)
%   2. DYNARE_PATH environment variable
%   3. OS-specific default install locations

% --- AUSPAC source path ---
here      = fileparts(mfilename('fullpath'));   % .../dynare
subdirs   = {'scripts/estimation', 'scripts/analysis', ...
             'scripts/figures',    'scripts/data_prep', ...
             'scripts/tests'};
for k = 1:numel(subdirs)
    p = fullfile(here, subdirs{k});
    if exist(p, 'dir')
        addpath(p);
    end
end

% --- Dynare ---
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
