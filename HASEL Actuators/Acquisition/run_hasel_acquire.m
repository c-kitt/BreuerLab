% run_hasel_acquire.m
% Main script to run a batch of HASEL actuator acquisitions at one weight.
% Set the weight to match the physical weight on the actuator, then run.
% Repeat for each weight (change 'weight' and re-run).

weight  = 0;                 % weight physically on the actuator (g)
f_list  = [0.5 0.75 1];      % excitation frequencies (Hz)
amp_list = [4000 5000];      % excitation amplitudes (V)
nTrials = 3;                 % repeats per (freq, amp)

hasel_acquire(f_list, amp_list, weight, nTrials)

% To sweep weights, change 'weight' above and re-run, e.g.:
%   weight = 25;  hasel_acquire(f_list, amp_list, 25, nTrials)
%   weight = 50;  hasel_acquire(f_list, amp_list, 50, nTrials)
%   weight = 100; hasel_acquire(f_list, amp_list, 100, nTrials)
