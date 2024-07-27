classdef session < handle
    %SESSION Stores all information about a session
    %   Detailed explanation goes here
    
    properties
        running     logical = 0;          % true if session is running
        lengthmax   uint64  = 0;          % maximum length of session (s)
        length      double  = 0.0;        % current length of session (s)
        starttick   uint64  = 0;          % high precision tick of start
        starttime   double  = 0.0;        % timestamp of start
        stoptime    double  = 0.0;        % timestamp of stop
        protocol    string  = "";         % protocol to execute
        protocolmax double  = 0.0;        % max tracked protocol exec time
        protocolavg double  = 0.0;        % avg tracked protocol exec time
        protocolsum double  = 0.0;        % sum tracked protocol exec time
        srate       double  = 0.0;        % sample rate
        channels    uint32  = [];         % channel numbers
        SizeCHSS    uint32  = [];         % SS channel numbers
        data        double  = zeros(0,0); % session data
        times       double  = zeros(0);   % timestamps of sesssion data
        idx         uint32  = 0;          % current index in data and times
        firsttime   double  = 0.0;        % first time       
        window      double  = zeros(0,0); % current window
        windowtimes double  = zeros(0);   % current window times
        windowidx   uint32  = 0;          % current index in window
        windownum   uint32  = 1;          % current window num
        feedback    double  = zeros(0);   % recorded feedbacks
        markerinfo  double  = zeros(0,6); % info about epochs
        markers     double  = zeros(0,0); % recorded epochs
        marker      double  = 0.0;        % current epoch (0=undefined)
        bgcolor     double  = [0 0 0];    % current epoch bg color
        fbvisible   logical = false;      % if feedback bar is visible
        study       string  = "";         % name of study
        subject     uint32  = 1;          % subject numer
        run         uint32  = 1;          % run number
        ploth       matlab.ui.Figure;
    end
    
    events
        Started
        Stopped
        Window
        Epoch
    end
    
    methods
        %% Start a new session
        function r = start(self, protocol, lengthmax, window, srate, ...
                           channels, SizeCHSS, markerinfo, study, subject, run)
            if self.running
                r = false;
                return;
            end
            if isvalid(self.ploth)
                close(self.ploth);
            end
            numrows = ceil(srate*lengthmax);
            numcols = size(channels,2); %length(channels);
            numrowswnd = ceil(srate*window);
            self.running = true;
            self.protocol = protocol;
            self.protocolmax = 0.0;
            self.protocolavg = 0.0;
            self.protocolsum = 0.0;
            self.lengthmax = lengthmax;          
            self.srate = srate;
            self.channels = channels;
            self.SizeCHSS = SizeCHSS;
            self.data = zeros(numrows, numcols);
            self.times = zeros(numrows, 1);
            self.feedback = zeros(numrows, 1);
            self.idx = 0;           
            self.window = zeros(numrowswnd, numcols);
            self.windowtimes = zeros(numrowswnd, 1);
            self.windowidx = 0;
            self.windownum = 1;
            self.markers = zeros(numrows, 1);
            self.markerinfo = markerinfo;
            self.marker = 0;
            self.bgcolor = [0 0 0];
            self.fbvisible = false;
            self.study = study;
            self.subject = subject;
            self.run = run;
            self.starttick = tic();
            self.starttime = now();
            r = true;
            notify(self, "Started");
            self.update()
        end
        
        %% Stop a running session
        function r = stop(self)
            if ~self.running
                r = false;
                return;
            end
            self.marker = 0;
            self.bgcolor = [0 0 0];
            self.fbvisible = false;
            self.running = false;
            self.stoptime = now();
            r = true;
            notify(self, "Stopped");
            self.save();
        end
        
        
        %% Update a running session
        function update(self)
            %% do nothing if not running
            if ~self.running
                return;
            end
            %% update session length
            self.length = toc(self.starttick);
            %% update current epoch
            epochfound = false;
            epochold   = self.marker;
            for i = 1:size(self.markerinfo,1)
                epochstart = self.markerinfo(i,1);
                epochend   = self.markerinfo(i,2);
                epochval   = self.markerinfo(i,3);
                epochshow  = self.markerinfo(i,4);
                epochred   = self.markerinfo(i,5);
                epochgreen = self.markerinfo(i,6);
                epochblue  = self.markerinfo(i,7);
                if epochstart <= self.length && epochend >= self.length
                    self.marker = epochval;
                    self.bgcolor = [epochred epochgreen epochblue];
                    self.fbvisible = epochshow;
                    epochfound  = true;
                    break
                end
            end
            if ~epochfound; self.marker = 0.0; end
            if epochold ~= self.marker; notify(self, "Epoch"); end
            %% stop session if required samples are recorded
            if self.idx >= length(self.data)
                self.stop();
            end
            %% stop session if time is up
            %if self.lengthmax > 0.0 && self.length >= self.lengthmax
            %    self.stop();
            %end
        end     

        
        %% Push a new sample to running session
        function pushSample(self, sample, ts)
            %% do nothing if not running
            if ~self.running
                return;
            end
            %% save timestamp of first sample
            if self.firsttime == 0
                self.firsttime = ts;
            end
            relts = ts - self.firsttime;
            %% add sample to data
            self.idx = self.idx + 1;
            self.data(self.idx,:) = sample;
            self.times(self.idx,:) = relts;
            self.markers(self.idx,:) = self.marker;
            %% add sample to window
            if self.windowidx < length(self.window)
                self.windowidx = self.windowidx + 1;
            else
                self.window = circshift(self.window, -1);
                self.windowtimes = circshift(self.windowtimes, -1);
            end
            self.window(self.windowidx,:) = sample;
            self.windowtimes(self.windowidx,:) = relts;
            
            %% raise window event
            notify(self, "Window");
            if self.windowidx >= length(self.window)
                self.windownum = self.windownum + 1;
            end
        end
        
        
        %% Push a new feedback to running session
        function pushFeedback(self, v, span)
            if ~self.running
                return;
            end
            self.feedback(self.idx,:) = v;
            self.protocolsum = self.protocolsum + span;
            self.protocolavg = self.protocolsum / double(self.idx);
            if span > self.protocolmax
                self.protocolmax = span;
            end
        end

        %% Save session to disk
        function save(self)
            usedrows = max(self.idx,1);
            % study/subject info
            export.study = self.study;
            export.subject = self.subject;
            export.run = self.run;
            % meta info
            export.protocol = self.protocol;
            export.samplerate = self.srate;
            export.channels = self.channels;
            export.SizeCHSS = self.SizeCHSS;
            export.starttime = datetime(self.starttime,'ConvertFrom','datenum');
            export.stoptime = datetime(self.stoptime,'ConvertFrom','datenum');
            export.duration = self.length;
            export.windowsamples = length(self.window);
            % data
            export.times = self.times(1:usedrows,:);
            export.data = self.data(1:usedrows,:);
            export.feedback = self.feedback(1:usedrows,:);
            export.marker = self.markers(1:usedrows,:);
            % export
            studyname = "unnamed";
            if self.study ~= ""; studyname = self.study; end          
            filename = ...
                studyname + "-" + ...
                sprintf('%03d', self.subject) + "-" + ...
                sprintf('%02d', self.run);           
            save("./sessions/" + filename + ".mat", '-struct','export');
        end
    end
end

