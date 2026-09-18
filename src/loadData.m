function data = loadData(filepath)
% Loads candidate station sites from CSV
    data = readtable(filepath);
    fprintf('Loaded %d candidate sites.\n', height(data));
    disp(data);
end