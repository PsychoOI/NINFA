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
    marker, samplerate, samplenum, ~, ...
    windownum, window, isfullwindow, prevfeedback)

    % IMPORTANT: 
    %   Your algorithm must take less than (1/samplerate) seconds 
    %   in average or else you fall behind schedule and get a drift.
    %   If you're algorithm requires more time than that then
    %   run your calculation on every n-th window only and 
    %   repeat your previous feedback for all other windows.
    global DataRS 
    global RestValue
    global CounterRS
    global MarkerPrevious
    global First
    global Amplitude 
    global Filter

    %nChLS = (size(window,2)/4)-0;
    nChLS = size(window,2);

    r    = 0.5;   % default return
    n    = 1;     % process every n-th window
    tick = tic(); % start time of execution
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if marker == 1
        %% waiting phase at the very beginng (first epoch)
        MarkerPrevious = 1;
        First = 0;

    elseif marker == 2
        %% RESTING PHASE
        if MarkerPrevious ~= 2
           CounterRS = 0;
           DataRS  = [];
           RestValue = [];
        end
        % return 0.5 until first full window
        if ~isfullwindow
            %r = 0.5;
            % calculate on every n-th window: Real-Time Preprocessing
        elseif mod(windownum, n) == 0

            %DataConc = window(:,(size(window,2)/2)+1:end); % concentration data HbO+HbR 
            DataConc = window; % concentration data HbO+HbR
            
            CounterRS = CounterRS + 1;
            % saving the value of the last frame   
            DataRS(CounterRS,1:nChLS)= DataConc(end,1:nChLS); % only HbO data of long channels
            
            disp(CounterRS)

            if CounterRS  == floor(samplerate*30)-5 % 5 frames before 30 seconds of rest (to avoid final delays)
                if First == 0 % only if it is the first Rest
                    First = 1; 
                    %% Performing the amplitude of the signal - 15 seconds before the start of the experiment
                    Rest_long = mean(DataRS(floor(samplerate*15):CounterRS,1:nChLS),2);
                    % 1 - Gaussian filtering 
                    Signal_Gauss = conv(Rest_long, Filter, 'same');
                    % sort data 
                    SortVector = sort( Signal_Gauss);
                    % the amplitude is the difference between the largest and the smallest
                    % value. The max is performed as the mean of the 25 largest samples and the
                    % min as the mean of the 25 smallest samples. (Ten samples were discarded
                    % above and at the bottom).
                    if mean(SortVector(end-35:end-10))>0 && mean(SortVector(10:35))<0
                        Amplitude = abs(mean(SortVector(end-35:end-10))-mean(SortVector(10:35)));
                    else
                        Amplitude = abs(abs(mean(SortVector(end-35:end-10)))-abs(mean(SortVector(10:35))));
                    end
                end

                disp('Rest Average')
                DataFilt = DataRS(floor(samplerate*25):CounterRS,1:nChLS); % only HbO
                disp(size(DataFilt))
                
                % Gaussian Filtering
                for s = 1:size(DataFilt,2) 
                    DataFiltGs(:,s) = conv(DataFilt(:,s), Filter, 'same'); 
                end
                    
                RestValue(1,1) = mean(mean(DataFiltGs,2));
                
                disp(RestValue)
            end
            MarkerPrevious = marker;
        else
            MarkerPrevious = marker;
            r = prevfeedback;
        end
        
    elseif marker == 3
        %% MAIN PHASE
        MarkerPrevious = marker;
        % return 0.5 until first full window
        if ~isfullwindow
            %r = 0.5;            
            % calculate on every n-th window: Real-Time Preprocessing
        elseif mod(windownum, n) == 0           
            
            %DataConc = window(:,(size(window,2)/2)+1:end); % concentration data HbO+HbR
            DataConc = window; % concentration data HbO+HbR
            
            size(DataConc)            
            DataConcHbO = DataConc(:,1:nChLS); % HbO LS channels
            
            % Gaussian Filtering
            for s = 1:nChLS
                DataFilt(:,s) = conv(DataConcHbO(:,s), Filter, 'same'); % 'same' restituisce un output della stessa lunghezza di x
            end
            
            saveY = mean(mean(DataFilt,1));

            %% Feedback
            feedback = (saveY - RestValue(1,1));
            Parameter = 0.1; % rescaling with respect to Rest. 0.1 is the amplitude that I want on rest, if it is not, then I rescaled.
            feedback1 = (feedback*Parameter)/Amplitude;
            feedback_N = (((feedback1 + 0.35) * (1))/ (0.7));
             % y= ( ((X-a)x(d-c)) / (b-a) )  + c 
                % ( a , b ) = initial interval --> (-0.4, 0.4) 
                % ( c , d ) = final interval --> (0 , 1) 
            
            disp(saveY)
            
            r = feedback_N;
            
        % skip this sample/window
        else
            r = prevfeedback;
        end

    else
        %% UNKNOWN PHASE
        r = prevfeedback;
        warning("UNKNOWN EPOCH MARKER: " + marker)
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % time spent
    span = toc(tick);
    
    % debug
    disp("Processed sample " + samplenum + ...
        " (window=" + windownum + ...
        ", marker=" + marker + ...
        ", duration=" + sprintf('%.3f', span) + "s):");
    %     + ...
    %         " data intensity" + intensity(1) + ...
    %         " density " + density(1) );
end

% EXECUTED AT THE END OF THE SESSION
function finish(session)
    ploth = figure('Name', 'Session Plot');
    ploth.NumberTitle = 'off';
    
    %nchannels = size(session.channels, 2)/4; % total number of channels (NF+Correction) 
    nchannels = size(session.channels, 2); % total number of channels (NF+Correction) 

    disp(nchannels)
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
    NF = mean(session.data,2); % average of NF channels HbO

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
