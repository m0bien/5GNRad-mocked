function setup()
repoRoot = fileparts(mfilename('fullpath'));

fprintf('-------- 5G NR Radar --------\n');
fprintf('Repo root:\n\t%s\n', repoRoot);

srcPath = fullfile(repoRoot,'src');
addpath(srcPath);

mockPath = fullfile(repoRoot,'mock_toolboxes');
if isfolder(mockPath)
    addpath(mockPath);
end

expPath = fullfile(repoRoot,'experiments');
if isfolder(expPath)
    addpath(expPath);
end

rehash;
end