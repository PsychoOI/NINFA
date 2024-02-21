% Example Algorithm 1 for Demonstration
%   marker:       current epoch marker
%   samplerate:   sample rate
%   samplenum:    current sample number
%   sample:       current sample values
%   windownum:    current window number
%   window:       current window values
%   isfullwindow: true once first window is filled
%   prevfeedback: previous feedback
%   RETURN:       normalized value between 0.0 (min) and 1.0 (max)

function r = example1(...
    marker, samplerate, samplenum, sample, ...
    windownum, window, isfullwindow, prevfeedback)

    % IMPORTANT: 
    %   Your algorithm must take less than (1/samplerate) seconds 
    %   in average or else you fall behind schedule and get a drift.
    %   If you're algorithm requires more time than that then
    %   run your calculation on every n-th window only and 
    %   repeat your previous feedback for all other windows.

    n    = 1;
    tick = tic();
    
    % custom feedback range
    minfb = -100;
    maxfb = 100;
    
    % return 0.5 until first full window
    if ~isfullwindow
        r = 0.5;
    
    % calculate on every n-th window
    elseif mod(windownum, n) == 0
        % simulate 80% computation time (80ms of 100ms for 10Hz)
        pause((1.0/double(samplerate))*0.8);
        % create dummy feedback value in [minfb, maxfb]
        r = double(randi([minfb,maxfb]));
        % map from [minfb, maxfb] to [0, 1]    
        r = (r-minfb) * (1.0/(maxfb-minfb));
        
    % skip this sample/window
    else
        r = prevfeedback;
    end

    % time spent
    span = toc(tick);

    % debug
    disp("Processed sample " + samplenum + ...
        " (window=" + windownum + ...
        ", marker=" + marker + ...
        ", duration=" + sprintf('%.3f', span) + "s" + ...
        ", fb=" + sprintf('%.3f', r) + ")");
end
