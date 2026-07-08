%% hasel_load.m
% Loads all the HASEL .mat data files from a folder so they can be plotted.
%
% Each .mat file contains a 50000x4 timetable called "data" with these
% columns:  Ch1_V  Ch1_S  Ch2_V  Ch2_S   (V = input voltage, S = sensing)
%
% The experiment conditions (frequency, voltage, weight, trial) are stored
% in the file name, for example:
%   Ch1-2_Hasel5-4_f0.50_Amp4000_Phi000_Weight100_trial1.mat
%
% This script reads every file, pulls those numbers out of the name, and
% stores everything in one big table called "T" that the plotting script
% (hasel_9plots.m) then uses.
%
% HOW TO USE:
%   1. Set dataFolder below to the folder with your .mat files.
%   2. Run this script.  It creates a table "T" in your workspace.

clear
clc

%% ---- SET THIS: folder containing the .mat files ----
dataFolder = '/Users/ckitt/Library/CloudStorage/GoogleDrive-casey_kittredge@brown.edu/Shared drives/Breuer Lab/Flume/BFS/Artimus/bench_tests/Air_test/Two_actuators';

%% Get a list of all .mat files in that folder
files = dir(fullfile(dataFolder, '*.mat'));
fprintf('Found %d .mat files.\n', numel(files));

%% Prepare empty arrays to fill in as we read each file
fileName = strings(numel(files),1);   % the file name
freq     = zeros(numel(files),1);     % frequency (Hz)
volt     = zeros(numel(files),1);     % amplitude / voltage (V)
weight   = zeros(numel(files),1);     % weight (g)
trial    = zeros(numel(files),1);     % trial number
allData  = cell(numel(files),1);      % the timetable from each file

%% Loop through every file, one at a time
for i = 1:numel(files)

    % Full path to this file
    thisFile = fullfile(files(i).folder, files(i).name);
    fileName(i) = files(i).name;

    % --- Read the numbers out of the file name ---
    % sscanf looks for the pattern and grabs the numbers in order.
    % Pattern pieces: f<freq>_Amp<volt>_Phi000_Weight<weight>_trial<trial>
    nums = sscanf(files(i).name, ...
        'Ch1-2_Hasel5-4_f%f_Amp%f_Phi%*d_Weight%f_trial%f');
    freq(i)   = nums(1);
    volt(i)   = nums(2);
    weight(i) = nums(3);
    trial(i)  = nums(4);

    % --- Load the actual data (the timetable named "data") ---
    S = load(thisFile);        % load everything in the file
    allData{i} = S.data;       % keep just the timetable

end

%% Put it all in one table for easy searching later
T = table(fileName, freq, volt, weight, trial, allData);

fprintf('Done. Loaded everything into table "T".\n');
fprintf('Frequencies: %s Hz\n', mat2str(unique(freq)'));
fprintf('Voltages:    %s V\n',  mat2str(unique(volt)'));
fprintf('Weights:     %s g\n',  mat2str(unique(weight)'));
