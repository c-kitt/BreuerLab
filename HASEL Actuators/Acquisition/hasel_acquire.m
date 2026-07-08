function hasel_acquire(f_list, a_list, weight, nTrials)
% HASEL_ACQUIRE  Batch data acquisition from the Artimus HASEL amplifier
%                using an NI USB-6341 DAQ.
%
% Loops over: frequency -> amplitude -> trial number, driving the actuators
% via the Python amplifier pattern and recording four analog inputs
% (Ch1_V, Ch1_S, Ch2_V, Ch2_S) per trial. Weight is a manual input: place
% the physical weight, then call the function once for that weight.
%
% INPUTS
%   f_list  : excitation frequencies to sweep (Hz), e.g. [0.5 0.75 1]
%   a_list  : excitation amplitudes to sweep (V),  e.g. [4000 5000]
%   weight  : weight placed over the actuator (g) -- label only, set by hand
%   nTrials : number of repeat trials at each (freq, amp)
%
% USAGE
%   hasel_acquire([0.5 0.75 1], [4000 5000], 0, 3)
%   % ... physically change the weight, then:
%   hasel_acquire([0.5 0.75 1], [4000 5000], 50, 3)
%   hasel_acquire([0.5 0.75 1], [4000 5000], 100, 3)
%
% Pedro Ormonde, Dipan Deb & Casey Kittredge

%% Python Configuration  --- EDIT THESE PATHS PER MACHINE ---
% pythonExe : full path to the python.exe that has the 'ardi' package installed
% pyScript  : full path to amplifier_pattern.py
%
% Dipan PC example:
%   pythonExe = 'C:\Program Files\Python39\python.exe';
%   pyScript  = 'C:\Users\ddeb\Downloads\ARDI_Projects\ARDI_Projects\amplifier_pattern.py';
% Pedro PC example:
%   pythonExe = 'C:\Users\pcostaor\AppData\Local\Python\pythoncore-3.14-64\python.exe';
%   pyScript  = 'G:\My Drive\BFS\ARDI_Projects\amplifier_pattern.py';
pythonExe = 'C:\Program Files\Python39\python.exe';
pyScript  = 'C:\Users\ddeb\Downloads\ARDI_Projects\ARDI_Projects\amplifier_pattern.py';

%% Output Folder  --- EDIT PER MACHINE ---
% Must be a path that exists (or whose parent exists) on this machine.
% The Google Drive path below is the shared location; if the G: drive is not
% mounted here, point this at a local folder and copy to Drive afterward.
dir_out = "C:\Users\ddeb\Downloads\ARDI_Projects\new_data";
% Shared drive (use only if G: is mounted on this machine):
% dir_out = "G:\Shared drives\Breuer Lab\Flume\BFS\Artimus\bench_tests\Air_test\Two_actuators";

%% Hasel Actuator Parameters
Channel_h = {"1","2"};     % HV amplifier channels driven (ch1, ch2)
num_Hasel = {"5","4"};     % Hasel actuator serial numbers
Phi_h = 0;                 % phase offset applied to ch2 (deg)
% Note: only ch1/ch2 are driven in these two-actuator tests; ch3/ch4 phases
% (PHI_3, PHI_4 in the Python) stay at 0 and are not set here.

%% Trigger Parameters
triggerVoltage = 2.5;      % V  (PTU trigger pulse level)
pulseDuration  = 0.1;      % s  (trigger pulse width)

%% Fail-Safe Voltage Check
if any(a_list > 5000)
    error('Maximum amplitude is 5000 V.');
end

fprintf('=====================================\n');
fprintf('Batch run | Weight = %.2f g\n', weight);
fprintf('Frequencies: %s Hz\n', mat2str(f_list));
fprintf('Amplitudes : %s V\n', mat2str(a_list));
fprintf('Trials each : %d\n', nTrials);
fprintf('Total runs  : %d\n', numel(f_list)*numel(a_list)*nTrials);
fprintf('=====================================\n\n');

%% Arm PTU once for the whole batch
input(sprintf(['Place %.0f g weight, arm the PTU, and press ENTER to ' ...
               'start the batch: '], weight),'s');

%% Main Loops
for f_h = f_list
    for A_h = a_list
        for nTrial = 1:nTrials

            fprintf('\n--- f=%.2f Hz | A=%.0f V | trial %d/%d ---\n', ...
                f_h, A_h, nTrial, nTrials);

            %% Run Python Amplifier Pattern
            setenv('F_IN',  num2str(f_h,   '%.10g'));
            setenv('A_IN',  num2str(A_h,   '%.10g'));
            setenv('PHI_2', num2str(Phi_h, '%.10g'));

            fprintf('Launching Python amplifier pattern...\n');
            cmd = sprintf('start "ardi" /wait cmd /c ""%s" "%s""', pythonExe, pyScript);
            status = system(cmd);
            if status ~= 0
                error('Python script failed (status %d).', status);
            end

            %% Discover NI Devices & Create DAQ Object
            daqreset
            devname = "Dev2";              % NI device ID (check with daqlist("ni"))
            dq = daq("ni");
            dq.Rate = 1000;                % sample rate (Hz)

            %% Analog Input Channels
            ch1V = addinput(dq,devname,"ai0","Voltage");
            ch1V.Name = "Ch1_V";  ch1V.TerminalConfig = "SingleEnded";
            ch1S = addinput(dq,devname,"ai1","Voltage");
            ch1S.Name = "Ch1_S";  ch1S.TerminalConfig = "SingleEnded";
            ch2V = addinput(dq,devname,"ai2","Voltage");
            ch2V.Name = "Ch2_V";  ch2V.TerminalConfig = "SingleEnded";
            ch2S = addinput(dq,devname,"ai3","Voltage");
            ch2S.Name = "Ch2_S";  ch2S.TerminalConfig = "SingleEnded";

            %% PIV trigger channel (analog output)
            trigAO = addoutput(dq,devname,"ao0","Voltage");

            %% Acquisition Parameters
            nCycles = 25;                          % drive cycles recorded
            nScans  = ceil(nCycles/f_h*dq.Rate);   % total samples

            %% Define & Preload Trigger Waveform
            aoData = zeros(nScans, 1);
            pulseScans = round(pulseDuration * dq.Rate);
            aoData(1:pulseScans) = triggerVoltage; % single pulse at the start
            preload(dq, aoData);

            %% Start Acquisition
            fprintf('Starting hardware-synchronized AI/AO operation...\n');
            start(dq);
            while dq.Running
                pause(0.1);
            end
            fprintf('Acquisition complete.\n');

            %% Read Data
            data = read(dq,"all");   %#ok<NASGU>  (saved below via save())

            %% Build Output Filename
            name_out = sprintf( ...
                "Ch%s-%s_Hasel%s-%s_f%2.2f_Amp%4.0f_Phi%03.0f_Weight%03.0f_trial%1d.mat", ...
                Channel_h{1},Channel_h{2}, ...
                num_Hasel{1},num_Hasel{2}, ...
                f_h,A_h,Phi_h,weight,nTrial);
            fullName = fullfile(dir_out,name_out);

            %% Create Directory If Needed
            [folderPath,~,~] = fileparts(fullName);
            if ~exist(folderPath,'dir')
                mkdir(folderPath);
                fprintf('Created directory: %s\n',folderPath);
            end

            %% Overwrite Check
            if exist(fullName,'file')
                response = input( ...
                    sprintf('File already exists:\n%s\nOverwrite? (y/n): ', fullName),'s');
                if ~strcmpi(response,'y')
                    fprintf('Save skipped.\n');
                    continue
                end
            end

            %% Save (stores the whole workspace, including 'data')
            save(fullName)
            fprintf('Data saved: %s\n', name_out);

        end
    end
end

%% Batch finished
fprintf('\n=== Batch complete for weight %.0f g ===\n', weight);
load gong;
sound(y, Fs);
end
