function fh = Gauss
  fh.requires = @requires;
  fh.init     = @init;
  fh.process  = @process;
  fh.finish   = @finish;
end

% REQUIREMENTS FOR PROTOCOL
function r = requires()
    r.devicetype = "NIRS";
    r.markers = [1, 2, 3];
    % requires at least one HbO channel
    r.channels(1).type = "HbO";
    r.channels(1).unit = "μmol/L";
    r.channels(1).min = 1;
    r.channels(1).max = 64;
    % HbR is optional
    %r.channels(2).type = "HbR";
    %r.channels(2).unit = "μmol/L";
    %r.channels(2).min = 0;
    %r.channels(2).max = 64;
end

% EXECUTED ONCE ON START
function init()
    global Filter
    ordine = 15;
    cutoff = 0.022;
    Filter = gaussfir(cutoff, ordine);
end

% EXECUTED FOR EACH SLIDING WINDOW
function r = process(...
    marker, samplerate, samplenum, data, ...
    windownum, window, isfullwindow, ...
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
    global Filter

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
        %disp(CounterRS)

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
                filtered(:,ch) = conv(filtered(:,ch), Filter, 'same'); 
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
                DataFilt(:,ch) = conv(DataFilt(:,ch), Filter, 'same'); 
            end
            RestValue = mean(mean(DataFilt,2));
            %disp("Rest Average: " + sprintf('%.3f', RestValue));
        end

    elseif marker == 3
        %% CONCENTRATION PHASE

        % filter each HbO channel in current sliding window
        for ch = 1:size(window.HbO,2)
            DataFilt(:,ch) = conv(window.HbO(:,ch), Filter, 'same'); 
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
    
    %nchannels = size(session.channels, 2)/4; % total number of channels (NF+Correction) 
    nchannels = size(session.channels, 2); % total number of channels (NF+Correction) 
    disp("FINISH: " + nchannels);
    
    %nchannels_NF = nchannels - session.SizeCHSS; % only Feedback channels
    %nchannels_NF = nchannels; % only Feedback channels

    % Choice 1: Plotting Channel Signal
%   iW2 = 1;
%   for i = 1:nchannels
%       subplot(nchannels+2,1,i);   
%       plot(session.data(:,nchannels*2+i),'r'); % HbO
%       hold on 
%       plot(session.data(:,nchannels*3+i),'b'); % HbR
%       title('Concentration Changes [uM]: Channel ' + string(session.channels(iW2)-1));
%       iW2 = iW2 + 1;
%   end
%   % Plotting Feedback values
%   subplot(nchannels+2,1,nchannels+1);
%   plot(session.feedback(:,1));
%   title('Feedback');
%   % Plotting Marker Values
%   subplot(nchannels+2,1,nchannels+2);
%   plot(session.markers(:,1));
%   title('Marker');

    % Choice 2: Plotting Channel Average
    NF = mean(session.data.HbO,2); % average of NF channels HbO

    %NF = mean(session.data(:,2*nchannels+1:2*nchannels+nchannels_NF),2); % average of NF channels HbO
    %CC = mean(session.data(:,2*nchannels+nchannels_NF+1:3*nchannels),2); % average of channels for correction HbO
    %NF_HbR = mean(session.data(:,3*nchannels+1:3*nchannels+nchannels_NF),2); % average of NF channels HbR
    %CC_HbR = mean(session.data(:,3*nchannels+nchannels_NF+1:4*nchannels),2); % average of channels for correction HbR
    
    subplot(4,1,1);   
    plot(NF,'r'); % HbO
    %hold on 
    %plot(NF_HbR,'b'); % HbR           
    title('Concentration Changes [uM]: Average of Neurofeedback Channels ');
    %subplot(4,1,2);   
    %plot(CC,'r'); % HbO
    %hold on 
    %plot(CC_HbR,'b'); % HbR           
    %title('Concentration Changes [uM]: Average of Channels for correction');            
    
    % Plotting Feedback values
    subplot(4,1,3);
    plot(session.feedback(:,1));
    title('Feedback');
    
    % Plotting Marker Values
    subplot(4,1,4);
    plot(session.markers(:,1));
    title('Marker');
end
