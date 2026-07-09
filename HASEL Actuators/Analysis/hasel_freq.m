%% hasel_freq_compare.m
% Compares the three frequencies: each graph has 3 lines, one per frequency
% (0.5, 0.75, 1.0 Hz), so you can see how frequency changes the signal.
%
% Makes 3 graphs -- one per weight (0, 50, 100 g).
% Each graph:  input on top, sense on bottom, one channel, 4000 V, 10 cycles.
%
%   - x-axis is in CYCLES (0 to 10), not seconds. Because every line is shown
%     over the same number of cycles, the different frequencies line up on a
%     common cycle axis even though they run at different speeds in real time.
%   - sense is referenced to zero (its lowest point sits at 0), not detrended.
%   - figures are saved as .fig and .svg.
%
% TO SWITCH CHANNELS: set channel = "Ch1" or "Ch2" below, and run again.
%
% BEFORE RUNNING: run hasel_load.m first so the table "T" exists.

if ~exist('T','var')
    error('Please run hasel_load.m first (it creates the table T).');
end

channel     = "Ch2";        % <-- set to "Ch1" or "Ch2"
freqList    = [0.5 0.75 1];
weightList  = [0 50 100];
volt        = 4000;
nCyclesShow = 10;
saveDir     = "figures";    % base folder; subfolders made per type/channel

vName = channel + "_V";
sName = channel + "_S";

% one distinct color per frequency
freqColors = [0.20 0.40 0.85;    % 0.5  Hz -> blue
              0.10 0.65 0.45;    % 0.75 Hz -> green
              0.80 0.20 0.20];   % 1.0  Hz -> red

for w = weightList

    fig = figure;
    sgtitle(sprintf('Weight = %d g   (%s, 4000 V, 10 cycles)', w, channel))

    for ifq = 1:numel(freqList)
        f = freqList(ifq);

        row = find(T.freq==f & T.weight==w & T.volt==volt & T.trial==1, 1);
        if isempty(row), continue; end
        d = T.allData{row};

        t   = seconds(d.Time - d.Time(1));
        vin = d.(vName);
        sig = d.(sName);

        % ---- align: start at the trough of the first cycle ----
        Fs = 1/mean(diff(t));
        oneCycle = round(Fs / f);
        searchEnd = min(round(1.5*oneCycle), length(vin));
        [~, startIdx] = min(vin(1:searchEnd));

        % ---- keep 10 cycles from that start ----
        samplesToShow = round(nCyclesShow / f * Fs);
        lastIdx = min(startIdx + samplesToShow - 1, length(t));
        idx = startIdx:lastIdx;

        % ---- x-axis in CYCLES ----
        xCycles = (t(idx) - t(startIdx)) * f;

        % ---- reference sense to zero ----
        sigZ = sig(idx) - min(sig(idx));

        c = freqColors(ifq,:);

        % TOP: input
        subplot(2,1,1)
        plot(xCycles, vin(idx), 'Color', c, 'LineWidth', 1.2, ...
            'DisplayName', sprintf('%.2f Hz', f)); hold on

        % BOTTOM: sense (referenced to zero)
        subplot(2,1,2)
        plot(xCycles, sigZ, 'Color', c, 'LineWidth', 1.2, ...
            'DisplayName', sprintf('%.2f Hz', f)); hold on
    end

    subplot(2,1,1); hold off
    xlabel('Cycles'); ylabel('Input [V]'); xlim([0 nCyclesShow])
    legend('Location','eastoutside'); set(gca,'FontSize',14)

    subplot(2,1,2); hold off
    xlabel('Cycles'); ylabel('Sense [V]'); xlim([0 nCyclesShow])
    legend('Location','eastoutside'); set(gca,'FontSize',14)

    % ---- save as .fig and .svg (in figures/frequencies/<channel>/) ----
    outDir = fullfile(saveDir, "frequencies", channel);
    if ~isfolder(outDir), mkdir(outDir); end
    fname = fullfile(outDir, sprintf('freqs_%s_w%03dg', channel, w));
    savefig(fig, fname + ".fig");
    print(fig, fname + ".svg", '-dsvg');
end

fprintf('Made 3 frequency-comparison graphs for %s (saved .fig and .svg).\n', channel);