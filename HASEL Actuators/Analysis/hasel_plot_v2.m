%% hasel_9plots_v2.m
% Updated 9-graph plot based on feedback:
%   1. Show only the first 10 drive cycles (not all 25).
%   2. Only the 4000 V data (drop 5000 V).
%   3. Every graph starts at (0,0) rising, like a normal sine wave. We find
%      where the input signal first crosses zero going up, and shift BOTH the
%      input and the sensing signal by that same amount so they stay lined up
%      sample-for-sample.
%   4. Cleaner y-axes: real voltage with clear labels, and the sensing plot
%      gets its own tight scale (its signal is much smaller than the input).
%
% Makes 9 graphs: one per frequency (3) x weight (3).
% BEFORE RUNNING: run hasel_load.m first so the table "T" exists.

if ~exist('T','var')
    error('Please run hasel_load.m first (it creates the table T).');
end

freqList   = [0.5 0.75 1];
weightList = [0 50 100];
volt       = 4000;          % only 4000 V now
nCyclesShow = 10;           % how many cycles to display

ch1color = [0.20 0.40 0.85];   % blue = Ch1
ch2color = [0.85 0.30 0.20];   % red  = Ch2

for f = freqList
    for w = weightList

        % find the matching file (4000 V, trial 1)
        row = find(T.freq==f & T.weight==w & T.volt==volt & T.trial==1, 1);
        if isempty(row), continue; end
        d = T.allData{row};

        % time in seconds, starting at 0
        t = seconds(d.Time - d.Time(1));

        % ---- pull the four signals ----
        ch1V = d.Ch1_V;
        ch2V = d.Ch2_V;
        ch1S = detrend(d.Ch1_S);   % detrend centers the sensing signal at 0
        ch2S = detrend(d.Ch2_S);

        % ---- STEP 3: find the bottom of a cycle to start from ----
        % The input is unipolar (0 up to ~1.2 V, never negative), so a "normal
        % sine start" means beginning at the bottom of the wave (the minimum)
        % and rising up. We look for the first low point of Ch1_V after things
        % have settled, then start there. Both signals are shifted the same way.
        %
        % Method: find where the input is near its minimum AND about to rise.
        loVal = min(ch1V) + 0.1*(max(ch1V)-min(ch1V));   % "near the bottom"
        startIdx = 1;
        for k = 2:length(ch1V)-1
            if ch1V(k) < loVal && ch1V(k+1) >= ch1V(k)   % at a low point, rising
                startIdx = k;
                break
            end
        end

        % ---- keep only 10 cycles' worth of samples from that start ----
        Fs = 1/mean(diff(t));                 % sample rate (Hz)
        samplesToShow = round(nCyclesShow / f * Fs);
        lastIdx = min(startIdx + samplesToShow - 1, length(t));
        idx = startIdx:lastIdx;

        % new time axis that starts at 0
        tPlot = t(idx) - t(startIdx);

        % ---- plot ----
        figure
        sgtitle(sprintf('f = %.2f Hz   Weight = %d g   (4000 V, 10 cycles)', f, w))

        % TOP: input voltage
        subplot(2,1,1)
        plot(tPlot, ch1V(idx), 'Color', ch1color, 'DisplayName','Ch1 input'); hold on
        plot(tPlot, ch2V(idx), 'Color', ch2color, 'DisplayName','Ch2 input'); hold off
        xlabel('Time [s]')
        ylabel('Input [V]')
        xlim([0 tPlot(end)])
        legend('Location','eastoutside')
        set(gca,'FontSize',14)

        % BOTTOM: sensing signal (its own tight y-scale)
        subplot(2,1,2)
        plot(tPlot, ch1S(idx), 'Color', ch1color, 'DisplayName','Ch1 sense'); hold on
        plot(tPlot, ch2S(idx), 'Color', ch2color, 'DisplayName','Ch2 sense'); hold off
        xlabel('Time [s]')
        ylabel('Sense [V] (detrended)')
        xlim([0 tPlot(end)])

        % fit the y-limits to the sensing data so it fills the plot nicely,
        % with a little padding, and keep it symmetric around 0
        senseMax = max(abs([ch1S(idx); ch2S(idx)]));
        ylim([-1.1*senseMax, 1.1*senseMax])

        legend('Location','eastoutside')
        set(gca,'FontSize',14)

    end
end

fprintf('Made 9 graphs (4000 V, first 10 cycles, aligned to start at 0).\n');