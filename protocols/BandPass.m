function fh = BandPass
  fh.requires = @requires;
  fh.init     = @init;
  fh.process  = @process;
  fh.finish   = @finish;
end

% REQUIREMENTS FOR PROTOCOL
function r = requires()
    r.devicetype = "NIRS";
    % required window min and max durations
    r.window.mins = 1.0;
    r.window.maxs = 10.0;
    % requires at least one HbO channel
    r.channels(1).type = "HbO";
    r.channels(1).unit = "μmol/L";
    r.channels(1).min = 1;
    r.channels(1).max = 64;
    % HbR is optional
    r.channels(2).type = "HbR";
    r.channels(2).unit = "μmol/L";
    r.channels(2).min = 0;
    r.channels(2).max = 64;
end

% EXECUTED ONCE ON START
function init()
    global FilterA
    global FilterB
    global mysession
    order = 3;
    cutoff = [0.01 0.5];
    samplerate = mysession.srate;
    [FilterB, FilterA]= butter(order, (cutoff*2)/samplerate,'bandpass');
end

% EXECUTED FOR EACH SLIDING WINDOW
function r = process(...
    marker, samplerate, samplenum, data, SSdata, ...
    windownum, window, SSwindow, isfullwindow, ...
    prevfeedback, prevmarker)

    % IMPORTANT: 
    %   Your algorithm must take less than (1/samplerate) seconds 
    %   in average or else you fall behind schedule and get a drift.
    %   If you're algorithm requires more time than that then
    %   run your calculation on every n-th window only and 
    %   repeat your previous feedback for all other windows.
    global CounterRS
    global DataRS 
    global RestValue
    global Correction
    global FilterA
    global FilterB

    % CONSTANTS
    EXPECTED_AMPLITUDE =  0.1;
    EXPECTED_MIN_DIFF  = -0.4;
    EXPECTED_MAX_DIFF  =  0.4;
    
    r    = 0.5;   % default return
    tick = tic(); % start time of execution
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if marker == 2
        %% RESTING PHASE
        
        % reset on switch
        if prevmarker ~= 2
           CounterRS = 0;
           DataRS = [];
        end

        % saving the HbO values of the last sample   
        CounterRS = CounterRS + 1;
        DataRS(CounterRS,:) = window.HbO(end,:);

        % 5 frames before 30 seconds of rest (to avoid final delays)
        if CounterRS == floor(samplerate*30)-5
            %% CALCULATE CORRECTION FACTOR USING AMPLITUDE
            % (1) Extract last ~15s of HbO channels of resting phase
            % (2) Filter each HbO channel
            % (3) Create average HbO channel from all filtered HbO channels
            % (4) Sort average HbO channel
            % (5) Calculate amplitude using mean of highest and lowest
            filtered = DataRS(floor(samplerate*15):end,:);
            for ch = 1:size(filtered,2) 
                filtered(:,ch) = filter(FilterB, FilterA,  filtered(:,ch));
            end
            mean_hbo   = mean(filtered,2);
            mean_hbo   = sort(mean_hbo);
            mean_top25 = mean(mean_hbo(end-35:end-10));
            mean_low25 = mean(mean_hbo(10:35));
            amplitude  = abs(mean_top25 - mean_low25);
            Correction = EXPECTED_AMPLITUDE / amplitude;
            %disp("Amplitude:  " + sprintf('%.3f', amplitude));
            %disp("Correction: " + sprintf('%.3f', Correction));

            %% AVERAGE OF HBO OF LAST ~5S OF RESTING PHASE
            DataFilt = DataRS(floor(samplerate*25):end,:);
            for ch = 1:size(DataFilt,2) 
                DataFilt(:,ch) = filter(FilterB, FilterA,  DataFilt(:,ch)); 
            end
            RestValue = mean(mean(DataFilt,2));
            %disp("Rest Average: " + sprintf('%.3f', RestValue));
        end

    elseif marker == 3
        %% CONCENTRATION PHASE

        % filter each HbO channel in current sliding window
        for ch = 1:size(window.HbO,2)
            DataFilt(:,ch) = filter(FilterB, FilterA,  window.HbO(:,ch));            
        end

        % calculate mean HbO channel and mean HbO over time
        mean_hbo = mean(mean(DataFilt,1));

        % feedback is difference in HbO scaled by correction
        feedback = mean_hbo - RestValue;
        feedback = feedback * Correction;
        
        % convert from expected range to [0,1] using
        % r = (((X-a)*(d-c)) / (b-a)) + c 
        % (a, b) = initial interval 
        % (c, d) = final interval
        r = (((feedback-EXPECTED_MIN_DIFF)*(1.0-0.0)) / ...
            (EXPECTED_MAX_DIFF-EXPECTED_MIN_DIFF)) + 0.0;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % time spent
    span = toc(tick);
    
    % create debug output
    output = ...
        "| sample="   + sprintf('%05d', samplenum) + " " + ...
        "| window="   + sprintf('%05d', windownum) + " " + ...
        "| marker="   + sprintf('%02d', marker)    + " " + ...
        "| duration=" + sprintf('%.3f', span)+"s"  + " " + ...
        "| feedback=" + sprintf('%.3f', r)         + " ";
    
    % add values for marker=3
    if marker == 3
        output = output + ...
            "| restavg="    + sprintf('%.3f', RestValue)  + " " + ...
            "| wndavg="     + sprintf('%.3f', mean_hbo)   + " " + ...
            "| correction=" + sprintf('%.3f', Correction) + " ";
    end
    
    % show debug output
    disp(output + "|");
end

% EXECUTED AT THE END OF THE SESSION
function finish(session)
    ploth = figure('Name', 'Session Plot');
    ploth.NumberTitle = 'off';
    
    nplot  = 1; % Current one
    nplots = 3; % HbO, Feedback, Marker
    if isfield(session.data, "HbR")
        nplots = 4; % + HbR
    end
    
    % Plotting unfiltered HbO mean channel
    subplot(nplots,1,nplot);
    plot(mean(session.data.HbO,2),'r');
    title('HbO [μmol/L]');
    
    % Plotting unfiltered HbR mean channel (optional)
    if isfield(session.data, "HbR")
        nplot  = nplot + 1;
        subplot(nplots,1,nplot);
        plot(mean(session.data.HbR,2),'b');
        title('HbR [μmol/L]');
    end

    % Plotting Feedback values
    nplot = nplot + 1;
    subplot(nplots,1,nplot);
    plot(session.feedback(:,1));
    title('Feedback');
    
    % Plotting Marker Values
    nplot = nplot + 1;
    subplot(nplots,1,nplot);
    plot(session.markers(:,1));
    title('Marker');
end
