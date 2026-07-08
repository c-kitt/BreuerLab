%% hasel_phase.m
% Alternative view of the 9 graphs, with the two voltages properly ALIGNED.
%
% The problem with plotting raw time: the 4000 V and 5000 V runs were
% recorded separately, so they don't share a start time and drift apart.
%
% The fix here: instead of plotting against clock time, we plot against
% "position within one drive cycle" (0 to 100% of a cycle). Because we know
% the drive frequency, every sample can be placed at its point in the cycle.
% We then average all the cycles together into one clean cycle per signal.
% The peaks line up because they are at the same point in the cycle -- no
% manual shifting, nothing made up.
%
% Result: 9 graphs (one per frequency/weight), both voltages overlaid,
% showing one clean averaged cycle. Same subplot layout (input on top,
% sense on bottom) and same colors as hasel_9plots.m.
%
% BEFORE RUNNING: run hasel_load.m first so the table "T" exists.

if ~exist('T','var')
    error('Please run hasel_load.m first (it creates the table T).');
end

freqList   = [0.5 0.75 1];
weightList = [0 50 100];
voltList   = [4000 5000];

% colors: Ch1 = blue, Ch2 = red ; 4000 V light/dashed, 5000 V dark/solid
ch1color = [0.20 0.40 0.85];
ch2color = [0.85 0.30 0.20];

nBins = 200;   % how many points to divide one cycle into (smoothness)

for f = freqList
    for w = weightList

        figure
        sgtitle(sprintf('f = %.2f Hz   Weight = %d g   (aligned by cycle)', f, w))

        for v = voltList
            row = find(T.freq==f & T.weight==w & T.volt==v & T.trial==1, 1);
            if isempty(row), continue; end
            d = T.allData{row};

            % time in seconds, starting at 0
            t = seconds(d.Time - d.Time(1));

            % ---- place each sample at its position within one cycle -----
            % one cycle lasts 1/f seconds. mod(...) gives 0..1 across a cycle.
            cyclePos = mod(t * f, 1);          % 0 = start of cycle, 1 = end

            % line style / shade for this voltage
            if v == 4000
                sty = '--';  fade = 0.5;
            else
                sty = '-';   fade = 1.0;
            end
            c1 = 1 - fade*(1 - ch1color);
            c2 = 1 - fade*(1 - ch2color);

            % ---- average each signal into one clean cycle ---------------
            % (averageInBins is defined at the bottom of this file)
            [xAxis, ch1V_avg] = averageInBins(cyclePos, d.Ch1_V,          nBins);
            [~,     ch2V_avg] = averageInBins(cyclePos, d.Ch2_V,          nBins);
            [~,     ch1S_avg] = averageInBins(cyclePos, detrend(d.Ch1_S), nBins);
            [~,     ch2S_avg] = averageInBins(cyclePos, detrend(d.Ch2_S), nBins);

            % ---- TOP: input voltage ----
            subplot(2,1,1); hold on
            plot(xAxis, ch1V_avg, sty, 'Color', c1, ...
                'DisplayName', sprintf('Ch1 V, %d V', v))
            plot(xAxis, ch2V_avg, sty, 'Color', c2, ...
                'DisplayName', sprintf('Ch2 V, %d V', v))

            % ---- BOTTOM: sense ----
            subplot(2,1,2); hold on
            plot(xAxis, ch1S_avg, sty, 'Color', c1, ...
                'DisplayName', sprintf('Ch1 S, %d V', v))
            plot(xAxis, ch2S_avg, sty, 'Color', c2, ...
                'DisplayName', sprintf('Ch2 S, %d V', v))
        end

        % label the plots
        subplot(2,1,1)
        xlabel('Position in cycle (0 to 1)'); ylabel('Input [V]')
        legend('Location','eastoutside'); set(gca,'FontSize',14); hold off

        subplot(2,1,2)
        xlabel('Position in cycle (0 to 1)'); ylabel('Sense [V]')
        legend('Location','eastoutside'); set(gca,'FontSize',14); hold off

    end
end

fprintf('Made 9 aligned graphs (one averaged cycle per condition).\n');


%% ---- helper: average y-values within each slice of the cycle ----------
function [binCenters, yAvg] = averageInBins(x, y, nBins)
% x runs 0..1 (position in cycle). Split into nBins slices and average the
% y-values that fall in each slice, giving one smooth cycle.
    edges = linspace(0, 1, nBins+1);
    bin   = discretize(x, edges);
    yAvg  = accumarray(bin, y, [nBins 1], @mean, NaN);

    % fill any empty slices by simple interpolation (rarely needed)
    if any(isnan(yAvg))
        good = ~isnan(yAvg);
        yAvg(~good) = interp1(find(good), yAvg(good), find(~good), ...
                              'linear', 'extrap');
    end

    binCenters = (edges(1:end-1) + diff(edges)/2)';   % middle of each slice
end