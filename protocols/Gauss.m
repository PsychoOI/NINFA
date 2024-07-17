function fh = Gauss
  fh.init = @init;
  fh.process = @process;
end

% EXECUTED ONCE ON START
function init()
    global Filter
    ordine = 15;
    cutoff = 0.022;
    Filter = gaussfir(cutoff, ordine);
end

% EXECUTED FOR EACH RECEIVED LSL PACKET
function r = process(...
    marker, nChSS, samplerate, samplenum, ~, ...
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

    nChLS = (size(window,2)/4)-nChSS;

    n    = 1;
    tick = tic();
       
    if marker == 1
        %% waiting phase at the very beginng (first epoch)
        r = 0.5; % feedback value
%         disp(nChSS);
        MarkerPrevious = 1;
        First = 0;

    elseif marker == 2   % rest condition
        if MarkerPrevious ~= 2       
           CounterRS = 0;
           DataRS  = []; 
           RestValue = [];
         end
        % return 0.5 until first full window
         if ~isfullwindow
            r = 0.5;            
            % calculate on every n-th window: Real-Time Preprocessing
        elseif mod(windownum, n) == 0           
	
            DataConc = window(:,(size(window,2)/2)+1:end); % concentration data
            CounterRS = CounterRS + 1;
		    % saving the value of the last frame   
            DataRS(CounterRS,1:nChLS)= DataConc(end,1:nChLS); % only HbO data of long channels

            disp(CounterRS)
            r = 0.5;          

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
                DataFilt = DataRS(floor(samplerate*25):CounterRS,1:nChLS); %prendo solo HbO
                disp(size(DataFilt))
                
                % Gaussian Filtering
                for s = 1:size(DataFilt,2) 
                    DataFiltGs(:,s) = conv(DataFilt(:,s), Filter, 'same'); 
                end
                    
                RestValue(1,1) = mean(mean(DataFiltGs,2));
                
                disp(RestValue)
   
                r = 0.5; 
                
            end
        MarkerPrevious = marker;
        
        else
            MarkerPrevious = marker;
            r = prevfeedback;
        end
        
    else
         MarkerPrevious = marker;
        % return 0.5 until first full window
        if ~isfullwindow
            r = 0.5;            
            % calculate on every n-th window: Real-Time Preprocessing
        elseif mod(windownum, n) == 0           
            
            DataConc = window(:,(size(window,2)/2)+1:end); % concentration data 
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

    end
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