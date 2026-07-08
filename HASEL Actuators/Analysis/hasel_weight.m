%% hasel_weight.m
% Compares the three weights directly: each graph has 3 lines, one per weight
% (0, 50, 100 g), so you can see how load changes the signal.
%
% Makes 3 graphs -- one per frequency (0.5, 0.75, 1.0 Hz).
% Each graph:  input on top, sense on bottom, Ch1 only, at 4000 V.
% Same as the other plots: first 10 cycles, aligned to start at the bottom
% of the wave (like a normal sine).
%
% The top (input) lines will look nearly identical -- that is expected, since
% load barely affects the drive. The bottom (sense) is where the load effect
% shows up.
%
% BEFORE RUNNING: run hasel_load.m first so the table "T" exists.

if ~exist('T','var')
    error('Please run hasel_load.m first (it creates the table T).');
end

freqList    = [0.5 0.75 1];
weightList  = [0 50 100];
volt        = 4000;         % 4000 V only
nCyclesShow = 10;

% one distinct color per weight
weightColors = [0.20 0.40 0.85;    % 0 g   -> blue
                0.90 0.60 0.10;    % 50 g  -> orange
                0.80 0.20 0.20];   % 100 g -> red

for f = freqList

    figure
    sgtitle(sprintf('f = %.2f Hz   (Ch1, 4000 V, 10 cycles)', f))

    for iw = 1:numel(weightList)
        w = weightList(iw);

        % find the matching file (this freq/weight, 4000 V, trial 1)
        row = find(T.freq==f & T.weight==w & T.volt==volt & T.trial==1, 1);
        if isempty(row), continue; end
        d = T.allData{row};

        t = seconds(d.Time - d.Time(1));
        ch1V = d.Ch1_V;
        ch1S = detrend(d.Ch1_S);

        % ---- align: start at the bottom of a cycle (rising), like a sine ----
        loVal = min(ch1V) + 0.1*(max(ch1V)-min(ch1V));
        startIdx = 1;
        for k = 2:length(ch1V)-1
            if ch1V(k) < loVal && ch1V(k+1) >= ch1V(k)
                startIdx = k;
                break
            end
        end

        % ---- keep 10 cycles from that start ----
        Fs = 1/mean(diff(t));
        samplesToShow = round(nCyclesShow / f * Fs);
        lastIdx = min(startIdx + samplesToShow - 1, length(t));
        idx = startIdx:lastIdx;
        tPlot = t(idx) - t(startIdx);

        c = weightColors(iw,:);

        % TOP: input
        subplot(2,1,1)
        plot(tPlot, ch1V(idx), 'Color', c, 'LineWidth', 1.2, ...
            'DisplayName', sprintf('%d g', w)); hold on

        % BOTTOM: sense
        subplot(2,1,2)
        plot(tPlot, ch1S(idx), 'Color', c, 'LineWidth', 1.2, ...
            'DisplayName', sprintf('%d g', w)); hold on
    end

    % finish TOP
    subplot(2,1,1); hold off
    xlabel('Time [s]'); ylabel('Input [V]')
    legend('Location','eastoutside'); set(gca,'FontSize',14)

    % finish BOTTOM
    subplot(2,1,2); hold off
    xlabel('Time [s]'); ylabel('Sense [V] (detrended)')
    legend('Location','eastoutside'); set(gca,'FontSize',14)

end

fprintf('Made 3 weight-comparison graphs (one per frequency).\n');