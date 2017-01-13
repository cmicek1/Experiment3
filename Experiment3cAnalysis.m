%%% Experiment 3c Preliminary analysis
%%%
%%% Author: Chris Micek
%%%
%%% Utility to analyze OpenBCI output. Ensure that the current directory
%%% is a folder with all data to be used.
%%% Double comments indicate the start of each section; use CTRL + ENTER to
%%% run each.
%%%
%%% A note for the user: A lot of this code is recycled from a past
%%% iteration of this experiment, when there were no "idle states" before
%%% eye movements. As such, some of the older pieces of code still make
%%% mention of "saccades", but include data for both the idle states before
%%% the saccades, as well as the saccades themselves. I have tried in most
%%% newer sections to eliminate any confusion by referring to both the idle
%%% states and eye movements collectively as "transitions", but in some
%%% cases, like subject fields and some other data, the previous moniker
%%% persists. If you want eye movement data from these, please make sure to
%%% look at even-numbered rows/columns.

%% Initialize Variables (Section 1)
% DO THIS FIRST!

% Load data files

% Globals below:
% Number of trials
numTrials = 5;

% Number of transitions (from idle state to eye saccade and vice versa)
numTrans = 4;

% Find files in current directory
files = dir('*.txt');

% Store subjects as a MATLAB struct with relevant fields
subjects(length(files)).name = NaN;
for file = 1:length(files)
    % File names
    subjects(file).name = files(file).name;
    
    % EEG data
    subjects(file).data = csvread(files(file).name, 5, 0);
    
    % Control data
    subjects(file).Control = cell(numTrials, 1);
    
    % Experimental data
    subjects(file).Experimental = cell(numTrials, 1);
    
    % Sum of Ch1 and Ch2 Control condition
    subjects(file).CtrlSum = cell(numTrials, 1);
    
    % Sum of Ch1 and Ch2 Experimental Condition
    subjects(file).ExpSum = cell(numTrials, 1);
    
    % Data for saccades of Control condition
    subjects(file).CtrlSaccades = cell(numTrials, 1);
    
    % Data for saccades of Experimental condition
    subjects(file).ExpSaccades = cell(numTrials, 1);
    
    % 3D matrix of saccade times (in seconds):
    % sz1 = numSaccades
    % sz2 = numConditions
    % sz3 = numTrials
    subjects(file).SaccTimes = NaN(numTrans, 2, numTrials);
    
    % Mean RMS of all saccades
    subjects(file).SaccMeanRMS = NaN(1, 2);
    
    % Average delays between saccade signal and saccade detection
    subjects(file).AvgDelays = NaN(1, 2);
    
    % Average RMS of saccades summed with idle states
    subjects(file).AvgRMS = NaN(1, 2);
    
    % Data indices of each change of state
    subjects(file).indices = NaN(numTrials * numTrans * 2 + 2, 2);
    
    % Subject RMS threshold
    subjects(file).thresh = NaN;
    
    for trial = 1:numTrials
        subjects(file).CtrlSaccades{trial} = cell(numTrans, 1);
        subjects(file).ExpSaccades{trial} = cell(numTrans, 1);
    end
end


%% Separate experimental conditions (Section 2)

% Iterate through the data of each file line-by-line, and separate
% according to state.

% DO THIS SECOND!

% NOTE: This will take a long time; it iterates through hundreds of
% thousands of lines of data, and needs to put them in structures of
% variable length, since the amount of data points is not known.

for sub = 1:size(subjects, 2)
    ind = 1;
    prev = 0;
    for i = 1:size(subjects(sub).data, 1)
        state = subjects(sub).data(i, 1);
        
        if prev == 0 && state == 1
            ind = 1;
            subjects(sub).indices(ind, 1) = i;
            subjects(sub).indices(ind, 2) = state;
            ind = ind + 1;
            prev = state;
            
        elseif state == 4
            subjects(sub).indices(ind, 1) = i;
            subjects(sub).indices(ind, 2) = state;
            break
            
        elseif state > 200 && state < 300
            trial = idivide(int8(state - 200), 10);
            subjects(sub).Control{trial} = ...
                [subjects(sub).Control{trial};
                subjects(sub).data(i, :)];
            
        elseif state > 300 && state < 400
            trial = idivide(int8(state - 300), 10);
            subjects(sub).Experimental{trial} = ...
                [subjects(sub).Experimental{trial};
                subjects(sub).data(i, :)];
        end
        
        if prev ~= state % When the state changes, store the index of the
                         % first occurrence.
            
            % Realllly obscure condition: If some other program hijacks
            % computing time while experimenting, skip states that have a
            % last digit of 0
            if mod(mod(state, 100), 10) ~= 0
                % Store indices of condition changes
                subjects(sub).indices(ind, 1) = i;
                subjects(sub).indices(ind, 2) = state;
                ind = ind + 1;
            end
            prev = state;
        end
    end
end


%% Feature extraction and comparison (Section 3)

% Deprecated; not necessary anymore (but if you can still get it to work,
% will probably make some cool graphs).

fs = 250; % Sampling frequency (Hz)
T = 1/fs; % Period
cutoff = 20; % Cutoff frequency (for lowpass filter)
order = 3;
[b, a] = butter(order, cutoff/(fs/2)); % Generate filter coefficients

names = fieldnames(subjects); % Struct field names; useful for plotting
for sub = 1:length(subjects)
    for trial = 1:numTrials
        for condition = 3:4
            for chan = 3:4
                x = subjects(sub).(names{condition}){trial}(:, chan);
                t = (0:length(x) - 1) * T;
                
                % Plot raw data
                
                %                 figure;
                %                 plot(t, x)
                %                 title({[subjects(i).name, ' Trial ', num2str(j),...
                %                     ' Channel ', num2str(h-2), ' Raw Data'],...
                %                     [names{k}, ' Condition']}, 'interpreter', 'none')
                %                 xlabel('Time (s)')
                %                 ylabel('Amplitude (uV)')
                
                % Use Butterworth lowpass filter
                x = detrend(x);
                filteredData = filtfilt(b, a, x);
                % Zero-phase filtering; eliminates any phase shifting/edge
                % effects from the filtering method
                
                % Plot filtered data
                
                %                 figure;
                %                 plot(t, filteredData)
                %                 title({[subjects(i).name, ' Trial ', num2str(j),...
                %                     ' Channel ', num2str(h-2), ' Filtered Data'],...
                %                     [names{k}, ' Condition']}, 'interpreter', 'none')
                %                 xlabel('Time (s)')
                %                 ylabel('Relative Amplitude (uV)')
                
                % Plot FFT of each condition per trial
                
                % For all future FFT cases, window = x seconds / period (T)
                window = 15 / T;
                m = length(x(1:window)); % Window length
                n = pow2(nextpow2(m)); % Transform length
                y = fft(x(1:window), n); % DFT
                f = (0:n-1)*(fs/n); % Frequency range
                amp = abs(y)/n; % Amplitude
                %                 figure;
                %                 plot(f, amp)
                %                 title({[subjects(sub).name, ' Trial ', num2str(trial),...
                %                     ' Channel ', num2str(chan-2), ' FFT'],...
                %                     [names{condition}, ' Condition']}, 'interpreter', 'none')
                %                 xlabel('Frequency (Hz)')
                %                 ylabel('Amplitude (uV/sample)')
                %                 xlim([5, 13])
            end
        end
    end
end



%% Average Trial FFTs (Section 4)
% DO THIS THIRD! (if wou want, to see SSVEP)

% Calculate average FFT for all trials (to see SSFEP peak -- first step to
% making sure data looks as expected)
names = fieldnames(subjects); % Struct field names; useful for plotting
for sub = 1:length(subjects)
    for chan = 3:4
        for condition = 3:4
            
            % Store trials in a single new matrix
            fs = 250;
            T = 1/fs;
            
            % FFT window
            window = 15 / T;
            
            n = pow2(nextpow2(window));  % Transform length
            
            trials = NaN(n, numTrials);
            
            for trial = 1:length(subjects(sub).(names{condition}))
                x = subjects(sub).(names{condition}){trial}(:, chan);
                x = detrend(x); % Subtract mean and any linear trends
                
                y = fft(x(1:window), n); % DFT
                amp = abs(y)/n;          % Amplitude
                
                trials(:, trial) = amp;
            end
            
            % Average all trials, ignoring NaN elements
            Avgs = nanmean(trials, 2);
            
            % Plot FFT
            
            f = (0:n-1)*(fs/n);     % Frequency range
            
            % Relic from when there were three experiment conditions
            % (condition 5 doesn't exist anymore)
            if condition ~= 4
                figure;
            end
            if condition ~= 5
                hold on
                title({['Subject ', num2str(sub), ' Channel ', num2str(chan-2), ...
                    ' FFT'], [names{condition-1}, ' vs ' names{condition}, ...
                    ' Condition Averages']},...
                    'interpreter', 'none')
            end
            plot(f, Avgs)
            if condition == 4
                legend('Control', 'Experimental')
            end
            if condition == 5
                title({['Subject ', num2str(sub), ' Channel ', num2str(chan-2), ...
                    ' FFT'], [names{condition}, ...
                    ' Condition Averages']},...
                    'interpreter', 'none')
            end
            
            xlabel('Frequency (Hz)')
            ylabel('Amplitude (uV/sample)')
            xlim([5, 13])
        end
    end
end


%% Separate eye saccades (Section 5)

% Populates subject fields for saccade data for each condition, and the
% timing for each, starting at 0s. This code is somewhat robust to
% incorrect saccade/trial numbers sent to the BCI (necessitated by a
% previous error of mine

% DO THIS AFTER SECTION 2 (or 4)

for sub = 1:size(subjects, 2)
    count = 1; % Initial count of transitions
    
    start = true; % True if first experiment condition has not been seen
    
    trialStart = 0; % Initialize variable for storing index of the start
                    % of the trial.
    
    % Iterate line-by-line
    for i = 1:size(subjects(sub).data, 1)
        
        state = subjects(sub).data(i, 1);
        
        if start && state > 200 && state < 400 % Reached first state of
                                               % interest
            start = false;
            trialStart = i; % Keep track of index of first data point for
                            % the trial
            saccade = mod(mod(state, 100), 10); % Transition number
            condition = idivide(int32(state), 100) - 1; % Condition number
            trial = idivide(mod(int32(state), 100), 10); % Trial number
            subjects(sub).SaccTimes(count, condition, trial)...
                = 0; % Starting time
        end
        
        % Process Control condition
        if state > 200 && state < 300
            
            temp = mod(mod(state, 100), 10); % Get last digit of UDP
                                             % message
            if temp ~= saccade && temp ~= 0 % If different than before,
                saccade = temp; % replace the old stored digit with the
                                % current one
                count = count + 1; % Update the transition count
                
                if count == numTrans + 1 % If over the max, reset
                    count = 1;
                end
                
                % Repeat the same process as above
                condition = idivide(int32(state), 100) - 1;
                trial = idivide(mod(int32(state), 100), 10);
                if count == 1
                    subjects(sub).SaccTimes(count, condition, trial)...
                        = 0;
                    trialStart = i;
                else
                    subjects(sub).SaccTimes(count, condition, trial)...
                        = i - trialStart;
                end
            end
            
            % Store data in the subject struct
            trial = idivide(mod(int32(state), 100), 10);
            subjects(sub).CtrlSaccades{trial}{count} = ...
                [subjects(sub).CtrlSaccades{trial}{count};
                subjects(sub).data(i, :)];
            
        % Repeat for Experimental condition
        elseif state > 300 && state < 400
            
            temp = mod(mod(state, 100), 10);
            if temp ~= saccade
                saccade = temp;
                count = count + 1;
                
                if count == numTrans + 1
                    count = 1;
                end
                
                condition = idivide(int32(state), 100) - 1;
                trial = idivide(mod(int32(state), 100), 10);
                
                if count == 1
                    subjects(sub).SaccTimes(count, condition, trial)...
                        = 0;
                    trialStart = i;
                else
                    subjects(sub).SaccTimes(count, condition, trial)...
                        = i - trialStart;
                end
            end
            
            trial = idivide(mod(int32(state), 100), 10);
            subjects(sub).ExpSaccades{trial}{count} = ...
                [subjects(sub).ExpSaccades{trial}{count};
                subjects(sub).data(i, :)];
        end
    end
end


%% Filter eye saccades (Section 6)

% COMPLETELY OPTIONAL:
% Pass each saccade/transition through a bandpass filter, and plot the
% result.
%
% Requires Section 5 first

fs = 250; % Sampling frequency (Hz)
T = 1/fs; % Period

window = int32(2.8 / T); % Number of data points to plot (time / period)

cutoff = [1.5 10]; % Bandpass cutoff frequencies: [low high]
order = 2;
[b, a] = butter(order, cutoff/(fs/2)); % Generate filter coefficients

names = fieldnames(subjects);
for sub = 1:length(subjects)
    for trial = 1:numTrials
        for condition = 7:8
            for saccade = 1:numTrans
                %                 if mod(saccade, 2) == 0 % Include for
                %                                         % saccades only
                x = subjects(sub).(names{condition}){trial}{saccade}(:, 4);
                t = (0:length(x) - 1) * T;
                
                %                     x = detrend(x);
                filteredData = filtfilt(b, a, x);
                
                % Subtract the mean/linear trends and divide by the 
                % standard deviation for a mean zero and unit variance
                filteredData = detrend(filteredData) ./ std(filteredData);
                
                
                % Plot
                figure;
                t0 = (0:length(filteredData) - 1) * T;
                plot(t0(1:window), filteredData(1:window))
                title({[subjects(sub).name, ' Trial ', num2str(trial),...
                    ' Channel 2 Filtered Data'], [names{condition}, ' #', ...
                    num2str(saccade)]}, 'interpreter', 'none')
                xlabel('Time (s)')
                ylabel('Relative Amplitude (uV)')
                %                 end
            end
        end
    end
end


%% Average Trial Saccades (Section 7)

% Calculate RMS of each saccade, and average across all trials
% Could be better; experiment!

% DO THIS AFTER SECTION 5

names = fieldnames(subjects);

fs = 250; % Sampling frequency
T = 1/fs; % Period

window = 1 / T; % Amount of time to consider per saccade / period

cutoff = [1.5 10];
order = 3;
[b, a] = butter(order, cutoff/(fs/2));

for sub = 1:length(subjects)
    for condition = 7:8
        
        % Store trials in a single new matrix
        
        
        trials = NaN(1, numTrials);
        saccs = NaN(1, idivide(int32(numTrans), 2));
        
        for trial = 1:numTrials
            for saccade = 1:numTrans
                if mod(saccade, 2) == 0
                    x = subjects(sub).(names{condition}){trial}{saccade}(:, 4);
                    
                    filteredData = filtfilt(b, a, x);
                    
                    y = rms(filteredData(1:window));
                    
                    saccs(1, idivide(int32(saccade), 2)) = y;
                end
            end
            trials(1, trial) = mean(saccs);
        end
        
        % Find mean RMS necessary to see all saccades
        subjects(sub).SaccMeanRMS(1, condition - 6) = mean(trials);
    end
end

%% Isolate EOG per trial (Section 8)

% Slide a window across data for all trials, and calculate RMS of the data
% in the window. If the RMS is higher than a threshold value, mark the last
% point that entered as belonging to a saccade (EOG). If RMS is above a
% certain value, consider data a certain +/- distance from the current
% point a blink, and zero any saccade votes in the region.

% DO THIS AFTER SECTION 7

fs = 250;
T = 1/fs;


cutoff = [1.5 10];
order = 3;
[b, a] = butter(order, cutoff/(fs/2));


% Optional notch filter to remove 50 Hz utility frequency
% w0 = 50 / (250 / 2);
% bw = w0 / 50;
% [d, c] = iirnotch(w0, bw);



names = fieldnames(subjects);

% Initialize variables to hold subject RMS and EOG class votes.
RMS = cell(length(subjects), 1);
class = RMS;

for sub = 1:length(subjects)
    RMS{sub} = cell(numTrials, 2);
    class{sub} = RMS{sub};
end

for sub = 1:length(subjects)
    for trial = 1:numTrials
        for condition = 3:4
            
            % Generate window
            window = [1, 1 / T];
            
            x = subjects(sub).(names{condition}){trial}(:, 4);
            
            % Filter data
            filteredData = filtfilt(b, a, x);
            %             filteredData = filtfilt(d, c, filteredData);
            t = (0:length(filteredData) - 1) * T;
            
            % Initialize RMS and class cells for each trial/condition
            RMS{sub}{trial, condition - 2} = NaN(length(filteredData) -...
                window(2) - window(1) - 1, 1);
            % All class votes start at 0 (no EOG)
            class{sub}{trial, condition - 2} = ...
                zeros(length(RMS{sub}{trial, condition - 2}), 1);
            
            for time = 1:length(RMS{sub}{trial, condition - 2})
                % Calculate RMS of region in window
                RMS{sub}{trial, condition - 2}(time) = rms(filteredData(...
                    window(1):window(2)));
                
                % If RMS is above threshold (in this case, 0.6 * the mean
                % saccade RMS), mark as EOG
                if RMS{sub}{trial, condition - 2}(time) > ...12
                        0.6 * subjects(sub).SaccMeanRMS(1, condition - 2)
                    % Change vote to 1 (EOG present)
                    class{sub}{trial, condition - 2}(time) = 1;
                end
                
                % Increment window endpoints
                window(1) = window(1) + 1;
                window(2) = window(2) + 1;
            end
            
            % After voting, eliminate blink artifacts: If RMS is too high,
            % zero all votes at data points t +/- tau.
            for time = 1:length(RMS{sub}{trial, condition - 2})
                if RMS{sub}{trial, condition - 2}(time) > 35 % Hard-coded for now
                    tau = 75; % Number of data points before/after the
                              % current position to zero
                    t1 = time - tau;
                    t2 = time + tau;
                    
                    if t1 < 1
                        t1 = 1;
                    end
                    if t2 > length(RMS{sub}{trial, condition - 2})
                        t2 = length(RMS{sub}{trial, condition - 2});
                    end
                    
                    % Zero votes in blink region
                    class{sub}{trial, condition - 2}(t1:t2) = 0;
                end
            end
            
            % Want zero mean and unit variance
            filteredData = detrend(filteredData);
            filteredData = filteredData ./ std(filteredData);
            
%                        % Plot raw data
%                         figure;
%                         plot(t, filteredData)
%                         for saccade = 1:numTrans
%                             x1 = subjects(sub).SaccTimes(saccade, condition - 2, trial);
%                             x = [x1 x1] * T;
%                             y = get(gca,'ylim');
%                             if mod(saccade, 2) == 0
%                                 line(x, y, 'Color', 'g')
%                             else
%                                 line(x, y, 'Color', 'r')
%                             end
%                         end
%             
%                         title({['Subject ', num2str(sub), ' Trial ', num2str(trial),...
%                                 ' Channel 2 Full Trial'], [names{condition},...
%                                 ' Condition']}, 'interpreter', 'none')
%                             xlabel('Time (s)')
%                             ylabel('Relative Amplitude (uV/sample)')
%             
% %                         % Plot isolated EOG
%                         figure;
%                         
%                         % Vote vector not the same size as data, so
%                         % choose the first vote for the first few data
%                         % points.
%                         plot(t, filteredData .* [ones(length(filteredData) - ...
%                             length(class{sub}{trial, condition - 2}), 1)...
%                             .* class{sub}{trial, condition - 2}(1);...
%                             class{sub}{trial, condition - 2}])
%             
%                         for saccade = 1:numTrans
%                             x1 = subjects(sub).SaccTimes(saccade, condition - 2, trial);
%                             x = [x1 x1] * T;
%                             y = get(gca,'ylim');
%                             % Green = eye movement, red = idle state
%                             if mod(saccade, 2) == 0
%                                 line(x, y, 'Color', 'g')
%                             else
%                                 line(x, y, 'Color', 'r')
%                             end
%                         end
%             
%                         title({['Subject ', num2str(sub), ' Trial ', num2str(trial),...
%                             ' Channel 2 Isolated Saccades'], [names{condition},...
%                             ' Condition']}, 'interpreter', 'none')
%                         xlabel('Time (s)')
%                         ylabel('Relative Amplitude (uV/sample)')
            
%                         % Plot data RMS values
%                         figure;
%                         plot(t, [ones(length(filteredData) - ...
%                             length(class{sub}{trial, condition - 2}), 1)...
%                             .* RMS{sub}{trial, condition - 2}(1);...
%                             RMS{sub}{trial, condition - 2}])
%             
%                         for saccade = 1:numTrans
%                             x1 = subjects(sub).SaccTimes(saccade, condition - 2, trial);
%                             x = [x1 x1] * T;
%                             y = get(gca,'ylim');
%                             if mod(saccade, 2) == 0
%                                 line(x, y, 'Color', 'g')
%                             else
%                                 line(x, y, 'Color', 'r')
%                             end
%                         end
%             
%                         title({[subjects(sub).name, ' Trial ', num2str(trial),...
%                             ' Channel 2 RMS'], [names{condition},...
%                             ' Condition']}, 'interpreter', 'none')
%                         xlabel('Time (s)')
%                         ylabel('RMS')
            
        end
    end
end


%% Calculate Average Delay between Saccade Onset and Detection (Section 9)

% After EOG is isolated, calculate time between sound cue and EOG
% detection.

% DO THIS AFTER SECTION 8

for sub = 1:length(subjects)
    
    names = fieldnames(subjects);
    
    for condition = 3:4
        
        delays = NaN(numTrials, idivide(int32(numTrans), 2));
        
        for trial = 1:numTrials
            % Make vote list that is the same size as data vector
            totVotes = [ones(length(subjects(sub)...
                .(names{condition}){trial}(:, 4)) - ...
                length(class{sub}{trial, condition - 2}), 1)...
                .* class{sub}{trial, condition - 2}(1);...
                class{sub}{trial, condition - 2}];
            
            %Split votes by transition
            saccVotes = cell(1, numTrans);
            
            % Get start and stopping points for transitions along data
            % vector
            for saccTime = 1:numTrans
                start = subjects(sub).SaccTimes(...
                    saccTime, condition - 2, trial);
                if saccTime ~= numTrans
                    stop = subjects(sub).SaccTimes(...
                        saccTime + 1, condition - 2, trial);
                else
                    stop = length(totVotes);
                end
                % Populate saccade/transition votes
                saccVotes{saccTime} = totVotes((start + 1):stop);
            end
            
            for saccade = 1:numTrans
                if mod(saccade, 2) == 0
                    start = 1;
                    stop = length(saccVotes{saccade});
                    
                    % Keep count of number of data points visited until
                    % either a vote for EOG is seen, or the stopping point
                    % is reached.
                    while start ~= stop && saccVotes{saccade}(start) ~= 1
                        start = start + 1;
                    end
                    
                    delays(trial, idivide(int32(saccade), 2)) = start;
                end
            end
        end
        
        % Save delays in subject struct, convert to seconds
        subjects(sub).AvgDelays(1, condition - 2) = mean2(delays) * T;
        
    end
end


%% Sum Signals (Section 10)

% Just a test section to see how adding signals looked. Filter ch1 and ch2
% data using different bandpass filters, then add them together when their
% gradients match. This is done on a per-trial basis.

% Must be run after Section 8 to work.

fs = 250;
T = 1/fs;

names = fieldnames(subjects);

% Set initial filter parameters
ch1cutoff = [7 8];
ch2cutoff = [1.5 10];
order = 3;
[b, a] = butter(order, ch1cutoff/(fs/2));
[d, c] = butter(order, ch2cutoff/(fs/2));

for sub = 1:length(subjects)
    for trial = 1:numTrials
        for condition = 3:4
            subjects(sub).(names{condition + 2}){trial}...
                = NaN(length(subjects(sub)...
                .(names{condition}){trial}(:, 4)), 1);
            
            % Filter data
            ch1 = filtfilt(b, a, subjects(sub)...
                .(names{condition}){trial}(:, 3));
            ch2 = filtfilt(d, c, subjects(sub)...
                .(names{condition}){trial}(:, 4));
            
            ch2 = ch2 .* [ones(length(ch2) - length(...
                class{sub}{trial, condition - 2}), 1)...
                .* class{sub}{trial, condition - 2}(1);...
                class{sub}{trial, condition - 2}];
            
            % Calculate gradients
            ch1grad = gradient(ch1, T);
            ch2grad = gradient(ch2, T);
            
            for i = 1:length(ch1grad)
                % When gradients are the same, add; else keep ch1
                if sign(ch1grad(i)) == sign(ch2grad(i))
                    subjects(sub).(names{condition + 2}){trial}(i) = ch1(i) + ch2(i);
                else
                    subjects(sub).(names{condition + 2}){trial}(i) = ch1(i);
                end
            end
            
            x = subjects(sub).(names{condition + 2}){trial};
            t = (0:length(x) - 1) * T;
            
            % Plot
            figure;
            plot(t, detrend(x) ./ std(x))
            
            title({[subjects(sub).name, ' Trial ', num2str(trial)],...
                [names{condition}, ' Condition', ' Summed Signal']},...
                'interpreter', 'none')
            xlabel('Time (s)')
            ylabel('Relative Amplitude (uV)')
        end
    end
end


%% Filter, Split All Data (Section 11)

% Filters the entire data set at once, then splits it by transition, to
% test for edge effects (there were none, so no need to replicate)

% Must be run after Section 2 to work

fs = 250;
T = 1/fs;


cutoff = [1.5 10];
order = 2;
[b, a] = butter(order, cutoff/(fs/2));

for sub = 1:length(subjects)
    x = subjects(sub).data(:, 4);
    
    % Filter everything!
    filteredData = filtfilt(b, a, x);
    
    for i = 2:(2 * numTrials * numTrans + 1)
        % Split at transition indices
        trans = filteredData(subjects(sub).indices(i, 1):...
            (subjects(sub).indices(i + 1, 1) - 1));
        trans = detrend(trans) ./ std(trans);
        
        t = (0:length(trans) - 1) * T;
        
        % Plot
        % COMMENT OUT TO PREVENT ERRORS
%         figure;
%         plot(t, trans)
%         
%         title({[subjects(sub).name, ' State ', ...
%             num2str(subjects(sub).indices(i, 2)),...
%             ]}, 'interpreter', 'none')
%         xlabel('Time (s)')
%         ylabel('Relative Amplitude (uV)')
    end
end

%% Add Separated States, Compute Average RMS (Section 12)

% Add eye saccades to their respective idle states (SSVEP or no SSVEP),
% calculate RMS, and average to show that EOG added to SSVEP has a higher
% RMS than EOG added to no SSVEP.

% Must be run after Section 8 to work

fs = 250; % Sampling frequency
T = 1/fs; % Period

names = fieldnames(subjects);

% Initialize filter parameters
ch1cutoff = [7 8];
ch2cutoff = [1.5 10];
order = 3;
[b, a] = butter(order, ch1cutoff/(fs/2));
[d, c] = butter(order, ch2cutoff/(fs/2));

% Store average RMS for each eye movement, for each condition
allRMS = cell(1, length(subjects));
transRMS = NaN(numTrials * idivide(int32(numTrans), 2), 2);

for sub = 1:length(subjects)
    for trial = 1:numTrials
        for condition = 3:4
            for trans = 1:(numTrans - mod(numTrans, 2))
                if mod(trans, 2) == 1 % Filter idle state
                    ch1 = filtfilt(b, a, subjects(sub)...
                        .(names{condition + 4}){trial}{trans}(:, 3));
                else % Filter eye saccade, isolate EOG
                    ch2 = filtfilt(d, c, subjects(sub)...
                        .(names{condition + 4}){trial}{trans}(:, 4));
                    
                    % Make EOG vote vector the same size as data
                    votes = [ones(length(subjects(sub)...
                        .(names{condition}){trial}(:, 4)) - length(...
                        class{sub}{trial, condition - 2}), 1)...
                        .* class{sub}{trial, condition - 2}(1);...
                        class{sub}{trial, condition - 2}];
                    
                    % Choose data indices to select respective EOG votes
                    % from vote vector
                    start = subjects(sub).SaccTimes(...
                        trans, condition - 2, trial) + 1;
                    if trans ~= numTrans
                        stop = subjects(sub).SaccTimes(...
                            trans + 1, condition - 2, trial);
                    else
                        stop = length(votes);
                    end
                    
                    % Isolate EOG
                    ch2 = ch2 .* votes(start:stop);
                    
                    % Calculate gradients of both signals
                    ch1grad = gradient(ch1, T);
                    ch2grad = gradient(ch2, T);
                    
                    % Make length the same as shortest transition data, so
                    % indices are always within bounds
                    sigsum = NaN(min(length(ch1grad), length(ch2grad)), 1);
                    
                    for i = 1:length(sigsum)
                        % When gradients match, add; else keep ch1
                        if sign(ch1grad(i)) == sign(ch2grad(i))
                            sigsum(i) = ch1(i) + ch2(i);
                        else
                            sigsum(i) = ch1(i);
                        end
                    end
                    
                    % Plot the summed signals
%                     figure;
%                     t = (0:length(sigsum) - 1) .* T;
%                     plot(detrend(sigsum) ./ std(sigsum))
%                     
%                     title({[subjects(sub).name, ' Trial ', num2str(trial)...
%                         ' Saccade ', num2str(idivide(int32(trans), 2))],...
%                         [names{condition}, ' Condition', ' Summed Signal']},...
%                         'interpreter', 'none')
%                     xlabel('Time (s)')
%                     ylabel('Relative Amplitude (uV)')
                    
                    if idivide(int32(trans), 2) == 1
                        idx = 2 * trial - 1;
                    else
                        idx = 2 * trial;
                    end
                    
                    % Record RMS for the saccade
                    transRMS(idx, condition - 2) = rms(sigsum);
                    
                end
            end
        end
    end
    allRMS{sub} = transRMS;
    for i = 1:2
        % Average saccade RMS for each condition over all trials
        subjects(sub).AvgRMS(i) = mean(transRMS(:, i));
    end    
end

totMeanRMS = NaN(1, 2);

subRMS = NaN(length(subjects), 2);

% Average across all subjects
for sub = 1:length(subjects)
    subRMS(sub, 1) = subjects(sub).AvgRMS(1);
    subRMS(sub, 2) = subjects(sub).AvgRMS(2);
end

totMeanRMS(1) = mean(subRMS(:, 1)); % Control condition
totMeanRMS(2) = mean(subRMS(:, 2)); % Experimental condition

%% Synchronize Signals (Section 13)

% SIMULATES THE PROCESS IN REAL TIME!
% (No post-processing/adding whole trials)

% Outline of the process:
%
% Generate synchronized signals for all combinations of subjects
% Go trial-by-trial, data point-by-data point, and populate circular
% buffers of a certain window size, to be used when calculating
% phase-difference using FFT. Whenever the buffer is full, a new offset
% value is calculated. Then, shift signal 2 elementwise using
% PhaseFrequencyOffset object, and add if the signs of their respective
% gradients match. In addition, simultaneously isolate EOG using the RMS
% threshold, like before.
%
% All this is done using only data from the Experimental condition (SSVEP)
%
% This might be better if turned into a function with flags for using a
% phase shift or gradient matching.
%
% To see the benefit of a phase shift, run this section twice, both with
% and without the phase shift (by commenting/uncommenting the appropriate
% line), and after each, store rmsTotcomp as another variable or vector.
% Then, run >> [h p] = ttest(withShift, withoutShift) and see the results.
%
% RUN THIS AFTER SECTION 8

fs = 250; % Sampling frequency
T = 1/fs; % Period

% Initialize filter parameters
ch1cutoff = [7 8];
ch2cutoff = [1.5 10];
order = 3;
[b, a] = butter(order, ch1cutoff/(fs/2));
[d, c] = butter(order, ch2cutoff/(fs/2));

% Generate unique pairs of subjects to synchronize
choices = nchoosek(1:length(subjects), 2);

% Vector to store RMS values for all synchronizations, across all choices
rmsTotcomp = NaN(numTrials * length(choices), 1);

for sync = 1:size(choices, 1)
    % Pick two subjects
    sub1 = subjects(choices(sync, 1));
    sub2 = subjects(choices(sync, 2));
    
    % Vector to store RMS values for these subjects' synchronizations
    rmscomp = NaN(numTrials, 1);
    
    for trial = 1:numTrials
        % Filter and detrend Subject 1 ch1
        x1 = sub1.Experimental{trial}(:, 3);
        x1 = filtfilt(b, a, x1);
        x1 = detrend(x1);
        
        % Filter and detrend Subject 2 ch1
        x2 = sub2.Experimental{trial}(:, 3);
        x2 = filtfilt(b, a, x2);
        x2 = detrend(x2);
        
        % Filter Subject 1 ch2
        eog = subjects(choices(sync, 1)).Experimental{trial}(:, 4);
        filteredEOG = filtfilt(d, c, eog);
        
        % Make length the same as shortest transition data, so
        % indices are always within bounds
        sz = min([length(x1), length(x2), length(filteredEOG)]);
        syncSig = zeros(sz, 1);
        
        t = (0:sz - 1) .* T;
        
        % The number of data points used to calculate FFTs for x1 and x2,
        % and thus determine the phase difference between the two. A
        % smaller number will decrease resolution in the frequency domain,
        % but the phase will be recalculated more frequently, as the
        % buffers that fill with data points for the transform will fill
        % more quickly.
        window = 30; %round(1 / T); % # of elements, or time (seconds) / T
        
        % Sliding window to calculate RMS in Subject 1 ch2 for EOG
        % isolation
        ch2window = [1, 1 / T];
        
        RMS = NaN(sz - ch2window(2) - ch2window(1) - 1, 1);
        
        % Circular FFT buffers
        temp1 = NaN(window, 1);
        temp2 = temp1;
        
        % Gradient calculation buffers
        gradbuff1 = NaN(3, 1);
        gradbuff2 = gradbuff1;
        ch2gradbuff = gradbuff1;
        
        % Matlab PhaseFrequencyOffset object; initial phase delay = 0
        shifter = comm.PhaseFrequencyOffset('SampleRate', T);
        
        % Iterate the number of data points, + to to wait for the gradient
        % buffers to fill, + window to fill the FFT buffers
        for point = 1:sz + 2 + window
            % Shift gradient buffers up, so when gradient is calculated
            % ordering is preserved
            gradbuff1 = circshift(gradbuff1, [-1, 0]);
            gradbuff2 = circshift(gradbuff2, [-1, 0]);
            ch2gradbuff = circshift(ch2gradbuff, [-1, 0]);
            
            if point <= sz
                % We can fill the FFT buffer if there are still data points
                % available
                temp1(mod(point - 1, window) + 1) = x1(point);
                temp2(mod(point - 1, window) + 1) = x2(point);
                
                winlength = length(ch2window(1):ch2window(2));
                
                if point > winlength % RMS window is full
                    % Calculate window RMS
                    RMS(point - winlength) = rms(filteredEOG(...
                        ch2window(1):ch2window(2)));
                    % Increment window endpoints
                    ch2window = [ch2window(1) + 1, ch2window(2) + 1];
                end
                
                if mod(point - 1, window) + 1 == window % Window is full
                    
                    % Calculate ch1 FFT for both subjects
                    m1 = length(temp1); % Window length
                    n1 = pow2(nextpow2(m1)); % Transform length
                    y1 = fft(temp1(1:window), n1); % DFT
                    f1 = (0:n1-1)*(fs/n1); % Frequency range
                    
                    
                    m2 = length(temp2);
                    n2 = pow2(nextpow2(m2));
                    y2 = fft(temp2(1:window), n2);
                    f2 = (0:n2-1)*(fs/n2);
                    
                    % Cross-power spectrum for data
                    % CPS = [F1 x F2*] / |F1 x F2*|
                    % See A Survey of Image Registration Techniques by
                    % Lisa Gottesfeld Brown for details.
                    cps = (y1 .* conj(y2)) ./ (abs(y1 .* conj(y2)));
                    
                    % Angle of max peak of cps is (average) phase
                    % difference between x1 and x2
                    [ssvep, idx] = max(abs(cps));
                    phasediff = angle(cps(idx));
                    
                    % Offset for shifter must be in degrees
                    offset = (phasediff) * (180 / pi);
                    shifter.PhaseOffset = offset; % Comment this line to
                                                  % supress phase shift
                end
            end
            
            if point > window && point <= sz + window
                % FFT window full; shift x2 by calculated offset
                shift2 = real(step(shifter, x2(point - window)));
            end
            
            if point > 3 + window && point < sz + 2 + window
                % Calculate gradients of gradient buffers
                ch1grad = gradient(gradbuff1, T);
                shiftgrad = gradient(gradbuff2, T);
                ch2grad = gradient(ch2gradbuff, T);
                
                % Gradient check needs at least one point on either side of
                % the point-of-interest for accuracy, so only done on
                % middle element.
                % Make the condition below "true" to suppress gradient
                % matching
                if sign(ch1grad(2)) == sign(shiftgrad(2))
                    % Gradients match, add
                    syncSig(point - window - 2) = ...
                        syncSig(point - window - 2) + gradbuff2(2);
                else
                    % Currently, chooses data point with largest magnitude
                    % out of x1, x2, or the shifted sum to maximize RMS
                    tochoose = [gradbuff1(2), ...
                        x2(point - window - 2), gradbuff2(2)];
                    [data, idx] = max(abs(tochoose));
                    syncSig(point - window - 2) = ...
                        syncSig(point - window - 2) + tochoose(idx);
                end
                
                % Comment out the block below to suppress adding isolated
                % EOG to the synchronized signal
                
                if sign(ch2grad(2)) == sign(ch1grad(2))
                    if point > winlength + window + 2 ...
                            && RMS(point - window - winlength - 2) >...
                            0.6 * subjects(choices(sync, 1))...
                            .SaccMeanRMS(1, 2)
                        syncSig(point - window - 2) = ...
                            syncSig(point - window - 2) + ch2gradbuff(2);
                    elseif point <= winlength + 2
                        syncSig(point - window - 2) = ...
                            syncSig(point - window - 2);% + ch2gradbuff(2);
                    end
                end
            end
            
            % First and last point are special edge cases.
            if point == 1 + window || point == sz + window
                tochoose = [x1(point - window), x2(point - window),...
                    x1(point - window) + shift2];
                [data, idx] = max(abs(tochoose));
                syncSig(point - window) = tochoose(idx);
                
                % Comment out the block below to suppress adding isolated
                % EOG to synchronized signal
                
                if point == sz + window
                    if RMS(length(RMS)) > 0.6 * subjects(choices(sync, 1))...
                            .SaccMeanRMS(1, 2)
                        syncSig(point - window) = syncSig(point - window) +...
                            filteredEOG(point - window);
                    end
                else
                    if abs(syncSig(point - window) + ...
                            filteredEOG(point - window)) > ...
                            abs(syncSig(point - window))
                        syncSig(point - window) = syncSig(point - window) + ...
                            filteredEOG(point - window);
                    end
                end
            end
            
            % After FFT window is full, can synchronize with phase shift,
            % so start filling gradient buffers
            if point > window && point <= sz + window
                gradbuff1(1) = x1(point - window);
                gradbuff2(1) = x1(point - window) + shift2;
                ch2gradbuff(1) = filteredEOG(point - window);
                
                %                 tochoose = [x1(point), x2(point), x1(point) + shift2];
                %                 [data, idx] = max(abs(tochoose));
                %                 syncSig(point) = tochoose(idx);
            end
        end
        
        % Store RMS of synchronized signal for this trial
        rmscomp(trial) = rms(syncSig);
        
        % Plot x1, x2, and the synchronized signal
        figure;
        plot(t, x1(1:sz))
        hold on
        plot(t, x2(1:sz))
        plot(t, syncSig)
        hold off
        
        title({['Subjects ', num2str(choices(sync, 1)), ' & ',...
            num2str(choices(sync, 2)), ' Trial ', num2str(trial)],...
            'Summed Signal'},...
            'interpreter', 'none')
        xlabel('Time (s)')
        ylabel('Relative Amplitude (uV/sample)')
        
        legend(['Subject ', num2str(choices(sync, 1))],...
            ['Subject ', num2str(choices(sync, 2))], 'Sum')
    end
    % Store all RMS values for the synchronized signal for all subject
    % combinations
    rmsTotcomp(((sync - 1) * numTrials + 1):(sync * numTrials)) = ...
        rmscomp;
end