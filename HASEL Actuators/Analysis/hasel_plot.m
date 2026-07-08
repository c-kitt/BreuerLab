%% hasel_plot.m
% Makes 9 graphs from the HASEL data: one graph for each combination of
% frequency (3) and weight (3).  Both voltages (4000 V and 5000 V) are drawn
% on the same graph so we get 9 graphs instead of 18.
%
% Each graph has two stacked plots (like the professor's original code):
%   top    = input voltage over time    (Ch1_V and Ch2_V)
%   bottom = sensing signal over time   (Ch1_S and Ch2_S, detrended)
%
% BEFORE RUNNING THIS: run hasel_load.m first, so the table "T" exists.
% For each (frequency, weight) box we use trial 1 of each voltage.

%% Make sure the data is loaded
if ~exist('T','var')
    error('Please run hasel_load.m first (it creates the table T).');
end

%% The three frequencies and three weights we want a graph for
freqList   = [0.5 0.75 1];
weightList = [0 50 100];
voltList   = [4000 5000];    % both drawn on each graph

%% Loop over every frequency and weight -> one figure each (9 total)
for f = freqList
    for w = weightList

        % Start a new figure for this frequency/weight combination
        figure
        sgtitle(sprintf('f = %.2f Hz   Weight = %d g', f, w))  % title on top

        % ---- TOP PLOT: input voltage ----
        % Colors carry meaning so 4 lines are easy to tell apart:
        %   Ch1 = blue,  Ch2 = red
        %   4000 V = light & dashed,  5000 V = dark & solid
        ch1color = [0.20 0.40 0.85];   % blue
        ch2color = [0.85 0.30 0.20];   % red

        subplot(2,1,1)
        hold on                       % allow multiple lines on one plot
        for v = voltList
            % Find the row in T matching this freq, weight, voltage, trial 1
            row = find(T.freq==f & T.weight==w & T.volt==v & T.trial==1, 1);
            if isempty(row), continue; end   % skip if that file is missing
            d = T.allData{row};              % the timetable for this file

            % 4000 V -> dashed & lighter, 5000 V -> solid & full color
            if v == 4000
                sty = '--';  fade = 0.5;
            else
                sty = '-';   fade = 1.0;
            end
            c1 = 1 - fade*(1 - ch1color);   % fade toward white for 4000 V
            c2 = 1 - fade*(1 - ch2color);

            plot(d.Time, d.Ch1_V, sty, 'Color', c1, ...
                'DisplayName', sprintf('Ch1 V, %d V', v))
            plot(d.Time, d.Ch2_V, sty, 'Color', c2, ...
                'DisplayName', sprintf('Ch2 V, %d V', v))
        end
        hold off
        xlabel('Time')
        ylabel('Input [V]')
        legend('Location','eastoutside')
        set(gca, 'FontSize', 14)

        % ---- BOTTOM PLOT: sensing signal ----
        % Same color scheme as the top plot.
        subplot(2,1,2)
        hold on
        for v = voltList
            row = find(T.freq==f & T.weight==w & T.volt==v & T.trial==1, 1);
            if isempty(row), continue; end
            d = T.allData{row};

            if v == 4000
                sty = '--';  fade = 0.5;
            else
                sty = '-';   fade = 1.0;
            end
            c1 = 1 - fade*(1 - ch1color);
            c2 = 1 - fade*(1 - ch2color);

            % detrend() removes slow drift so the wiggle is centered at 0
            plot(d.Time, detrend(d.Ch1_S), sty, 'Color', c1, ...
                'DisplayName', sprintf('Ch1 S, %d V', v))
            plot(d.Time, detrend(d.Ch2_S), sty, 'Color', c2, ...
                'DisplayName', sprintf('Ch2 S, %d V', v))
        end
        hold off
        xlabel('Time')
        ylabel('Sense [V]')
        legend('Location','eastoutside')
        set(gca, 'FontSize', 14)

    end
end

fprintf('Made 9 graphs (one per frequency/weight, both voltages shown).\n');