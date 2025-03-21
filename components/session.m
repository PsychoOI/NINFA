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
        device      struct  = struct();   % device used in session
        channels    uint32  = [];         % channel numbers
        SSchannels    uint32  = [];         % channel numbers
        fn          cell    = [];         % field names in data and window
        data        struct  = struct();   % session data
        SSdata        struct  = struct();   % session data
        datasize    uint32  = 0;          % rows count in data
        times       double  = zeros(0);   % timestamps of sesssion data
        idx         uint32  = 0;          % current index in data and times
        firsttime   double  = 0.0;        % first time       
        window      struct  = struct();   % current window
        SSwindow      struct  = struct();   % current window
        windowsize  uint32  = 0;          % rows count in window
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
    end
    
    events
        Started
        Stopped
        Window
        Epoch
    end
    
    methods
        %% Return Channel Counts for each Type
        function r = countChannelTypes(self)
            r = struct();
            lslchannels = self.device.lsl.channels;
            numlslchannels = length(lslchannels);
            for ch = self.channels
                type = "unknown";
                if ch <= numlslchannels
                    type = lslchannels(ch).type;
                end
                if ~isfield(r, type)
                    r.(type) = 0;
                end
                r.(type) = r.(type) + 1;
            end
        end
        
        %% Return Channel Counts for each Type
        function r = countSSChannelTypes(self)
            r = struct();
            lslchannels = self.device.lsl.channels;
            numlslchannels = length(lslchannels);
            for ch = self.SSchannels
                type = "unknown";
                if ch <= numlslchannels
                    type = lslchannels(ch).type;
                end
                if ~isfield(r, type)
                    r.(type) = 0;
                end
                r.(type) = r.(type) + 1;
            end
        end

        %% Start a new session
        function r = start(self, protocol, lengthmax, window, srate, ...
                           device, channels, SSchannels, markerinfo, study, subject, run)
            if self.running
                r = false;
                return;
            end
            self.datasize = ceil(srate*lengthmax);
            self.windowsize = ceil(srate*window);
            self.running = true;
            self.protocol = protocol;
            self.protocolmax = 0.0;
            self.protocolavg = 0.0;
            self.protocolsum = 0.0;
            self.lengthmax = lengthmax;
            self.srate = srate;
            self.device = device;
            self.channels = channels;
            self.SSchannels = SSchannels;
            counts = self.countChannelTypes();
            SScounts = self.countSSChannelTypes();
            self.data = struct();
            self.SSdata = struct();
            self.window = struct();
            self.SSwindow = struct();
            self.fn = fieldnames(counts);
            for k = 1:numel(self.fn) % Type? 
                self.data.(self.fn{k}) = zeros(self.datasize, counts.(self.fn{k}));
                self.window.(self.fn{k}) = zeros(self.windowsize, counts.(self.fn{k}));
            end

            self.fn = fieldnames(SScounts);
            for k = 1:numel(self.fn) % Type? 
                self.SSdata.(self.fn{k}) = zeros(self.datasize, SScounts.(self.fn{k}));
                self.SSwindow.(self.fn{k}) = zeros(self.windowsize, SScounts.(self.fn{k}));
            end

            self.times = zeros(self.datasize, 1);
            self.feedback = zeros(self.datasize, 1);
            self.idx = 0;           
            self.windowtimes = zeros(self.windowsize, 1);
            self.windowidx = 0;
            self.windownum = 1;
            self.markers = zeros(self.datasize, 1);
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
            if self.idx >= self.datasize
                self.stop();
            end
            %% stop session if time is up
            %if self.lengthmax > 0.0 && self.length >= self.lengthmax
            %    self.stop();
            %end
        end     

        
        %% Push a new sample to running session
        function pushSample(self, sample, SSsample, ts)
            %% do nothing if not running
            if ~self.running
                return;
            end
            %% increment index for sample
            self.idx = self.idx + 1;
            %% save timestamp
            if self.firsttime == 0
                self.firsttime = ts;
            end
            relts = ts - self.firsttime;          
            %% shift window
            if self.windowidx < self.windowsize
                self.windowidx = self.windowidx + 1;
            else
                for k = 1:numel(self.fn)
                    self.window.(self.fn{k}) = ...
                        circshift(self.window.(self.fn{k}), -1);
                    self.SSwindow.(self.fn{k}) = ...
                        circshift(self.SSwindow.(self.fn{k}), -1);
                end
                self.windowtimes = circshift(self.windowtimes, -1);
            end
            self.windowtimes(self.windowidx,:) = relts;
            self.times(self.idx,:) = relts;
            self.markers(self.idx,:) = self.marker;
            %% add new sample to data and window
            colidx = struct();
            SScolidx = struct();
            lslchannels = self.device.lsl.channels;
            numlslchannels = length(lslchannels);
            for i = 1:length(self.channels)
                type = "unknown";
                val = sample(i);
                ch = self.channels(i);
                if ch <= numlslchannels
                    type = lslchannels(ch).type;
                end
                if ~isfield(colidx, type)
                    colidx.(type) = 1;
                end
                self.data.(type)(self.idx, colidx.(type)) = val;
                self.window.(type)(self.windowidx, colidx.(type)) = val;
                colidx.(type) = colidx.(type) + 1;
            end

            for i = 1:length(self.SSchannels)
                type = "unknown";
                val = SSsample(i);
                ch = self.SSchannels(i);
                if ch <= numlslchannels
                    type = lslchannels(ch).type;
                end
                if ~isfield(SScolidx, type)
                    SScolidx.(type) = 1;
                end
                self.SSdata.(type)(self.idx, SScolidx.(type)) = val;
                self.SSwindow.(type)(self.windowidx, SScolidx.(type)) = val;
                SScolidx.(type) = SScolidx.(type) + 1;
            end


            %% raise window event
            notify(self, "Window");
            if self.windowidx >= self.windowsize
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
            export.device = self.device;
            export.protocol = self.protocol;
            export.samplerate = self.srate;
            export.channels = self.channels;
            export.SSchannels = self.SSchannels;
            export.starttime = datetime(self.starttime,'ConvertFrom','datenum');
            export.stoptime = datetime(self.stoptime,'ConvertFrom','datenum');
            export.duration = self.length;
            export.windowsamples = self.windowsize;
            % data
             for k = 1:numel(self.fn)
                export.data.(self.fn{k}) = self.data.(self.fn{k})(1:usedrows,:);
            end
            for k = 1:numel(self.fn)
                export.SSdata.(self.fn{k}) = self.SSdata.(self.fn{k})(1:usedrows,:);
            end
            export.times = self.times(1:usedrows,:);
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

