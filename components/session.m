classdef session < handle
    %SESSION Stores all information about a session
    
    properties
        running     logical = false;        % true if session is running
        lengthmax   uint64  = 0;            % maximum length of session (s)
        length      double  = 0.0;          % current length of session (s)
        starttick   uint64  = 0;            % high precision tick of start
        starttime   double  = 0.0;          % timestamp of start
        stoptime    double  = 0.0;          % timestamp of stop
        protocol    string  = "";           % protocol to execute
        protocolmax double  = 0.0;          % max tracked protocol exec time
        protocolavg double  = 0.0;          % avg tracked protocol exec time
        protocolsum double  = 0.0;          % sum tracked protocol exec time
        srate       double  = 0.0;          % sample rate
        device      struct  = struct();     % device used in session
        channels    uint32  = [];           % channel numbers (NF)
        SSchannels  uint32  = [];           % channel numbers (SS)
        fn          cell    = {};           % field names in data and window
        data        struct  = struct();     % session data (NF)
        SSdata      struct  = struct();     % session data (SS)
        datasize    uint32  = 0;            % rows count in data
        times       double  = zeros(0,1);   % timestamps of session data
        idx         uint32  = 0;            % current index in data and times
        firsttime   double  = 0.0;          % first timestamp
        window      struct  = struct();     % current window (NF)
        SSwindow    struct  = struct();     % current window (SS)
        windowsize  uint32  = 0;            % rows count in window
        windowtimes double  = zeros(0,1);   % current window times
        windowidx   uint32  = 0;            % current index in window
        windownum   uint32  = 1;            % current window number
        normFeedback double  = zeros(0,1);   % recorded *normalized* feedback [0–1]
        rawFeedback  double  = zeros(0,1);   % recorded *raw* feedback (e.g. HbO difference)
        markerinfo  double  = zeros(0,7);   % info about epochs
        markers     double  = zeros(0,1);   % recorded epochs
        marker      double  = 0.0;          % current epoch (0 = undefined)
        bgcolor     double  = [0 0 0];      % current epoch background color
        fbvisible   logical = false;        % if feedback bar is visible
        study       string  = "";           % name of study
        subject     uint32  = 1;            % subject number
        run         uint32  = 1;            % run number
        runType     categorical;            % per‐sample: "feedback" or "transfer"
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
            for ch = self.channels
                if ch <= numel(lslchannels)
                    type = lslchannels(ch).type;
                else
                    type = "unknown";
                end
                if ~isfield(r, type)
                    r.(type) = 0;
                end
                r.(type) = r.(type) + 1;
            end
        end
        
        %% Return SS Channel Counts for each Type
        function r = countSSChannelTypes(self)
            r = struct();
            lslchannels = self.device.lsl.channels;
            for ch = self.SSchannels
                if ch <= numel(lslchannels)
                    type = lslchannels(ch).type;
                else
                    type = "unknown";
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
            self.datasize   = ceil(srate * lengthmax);
            self.windowsize = ceil(srate * window);
            self.running    = true;
            self.protocol   = protocol;
            self.protocolmax = 0.0;
            self.protocolavg = 0.0;
            self.protocolsum = 0.0;
            self.lengthmax   = lengthmax;
            self.srate       = srate;
            self.device      = device;
            self.channels    = channels;
            self.SSchannels  = SSchannels;
            % initialize everything as “transfer”
            self.runType    = categorical( ...
                                repmat("transfer", self.datasize,1), ...
                                ["feedback","transfer"]);
            counts   = self.countChannelTypes();
            SScounts = self.countSSChannelTypes();
            
            % Initialize data structures for NF
            self.data   = struct();
            self.window = struct();
            fnTypes = fieldnames(counts);
            for k = 1:numel(fnTypes)
                t = fnTypes{k};
                self.data.(t)   = zeros(self.datasize, counts.(t));
                self.window.(t) = zeros(self.windowsize, counts.(t));
            end
            
            % Initialize data structures for SS
            self.SSdata   = struct();
            self.SSwindow = struct();
            fnSSTypes = fieldnames(SScounts);
            for k = 1:numel(fnSSTypes)
                t = fnSSTypes{k};
                self.SSdata.(t)   = zeros(self.datasize, SScounts.(t));
                self.SSwindow.(t) = zeros(self.windowsize, SScounts.(t));
            end
            
            % Initialize time and marker arrays
            self.times       = zeros(self.datasize, 1);
            self.normFeedback = zeros(self.datasize, 1);
            self.rawFeedback  = zeros(self.datasize, 1);
            self.markers     = zeros(self.datasize, 1);
            self.markerinfo  = markerinfo;
            self.windowtimes = zeros(self.windowsize, 1);
            
            self.idx        = 0;
            self.windowidx  = 0;
            self.windownum  = 1;
            self.marker     = 0.0;
            self.bgcolor    = [0 0 0];
            self.fbvisible  = false;
            self.study      = study;
            self.subject    = subject;
            self.run        = run;
            self.starttick  = tic();
            self.starttime  = now();
            
            r = true;
            notify(self, 'Started');
            self.update();
        end
        
        %% Stop a running session
        function r = stop(self)
            if ~self.running
                r = false;
                return;
            end
            self.running = false;
            self.stoptime = now();
            r = true;
            notify(self, 'Stopped');
            self.save();
        end
        
        %% Periodic update (epoch, length, stop conditions)
        function update(self)
            if ~self.running, return; end
            
            % Update session length
            self.length = toc(self.starttick);
            
            % Update epoch
            oldMarker = self.marker;
            foundEpoch = false;
            for i = 1:size(self.markerinfo,1)
                m = self.markerinfo(i,:);
                if self.length >= m(1) && self.length <= m(2)
                    self.marker  = m(3);
                    self.bgcolor = m(5:7);
                    self.fbvisible = logical(m(4));
                    foundEpoch = true;
                    break;
                end
            end
            if ~foundEpoch
                self.marker = 0.0;
            end
            if self.marker ~= oldMarker
                notify(self, 'Epoch');
            end
            
            % Stop when data buffer is full
            if self.idx >= self.datasize
                self.stop();
            end
        end
        
        %% Push a new sample to running session
        function pushSample(self, sample, SSsample, ts)
            if ~self.running, return; end
            
            % Increment index
            self.idx = self.idx + 1;

            % record run‑type per sample as categorical
            if self.fbvisible
                self.runType(self.idx) = "feedback";
            else
                self.runType(self.idx) = "transfer";
            end

            if self.firsttime == 0
                self.firsttime = ts;
            end
            relts = ts - self.firsttime;
            
            % Shift window if full
            if self.windowidx < self.windowsize
                self.windowidx = self.windowidx + 1;
            else
                 % — Debug: print before shifting —
                fprintf('Rolling window #%d (full):\n', self.windownum);
                fprintf('  NF fields:  %s\n', strjoin(fieldnames(self.window), ', '));
                fprintf('  SS fields:  %s\n', strjoin(fieldnames(self.SSwindow), ', '));

                 % — Shift NF window independently —
                for fn = fieldnames(self.window)'
                    self.window.(fn{1}) = circshift(self.window.(fn{1}), -1);
                end
            
                % — Shift SS window independently (no-op if no SS fields) —
                for fn = fieldnames(self.SSwindow)'
                    self.SSwindow.(fn{1}) = circshift(self.SSwindow.(fn{1}), -1);
                end
                % — Debug: confirm after shifting —
                fprintf('  After roll, first row of each NF buffer:\n');
                for fn = fieldnames(self.window)'
                    col = self.window.(fn{1})(1,:);
                    fprintf('    %s: [%s]\n', fn{1}, num2str(col));
                end
            
                % — Shift the time-vector —
                self.windowtimes = circshift(self.windowtimes, -1);
            end
            
            % Store times and markers
            self.windowtimes(self.windowidx) = relts;
            self.times(self.idx)             = relts;
            self.markers(self.idx)           = self.marker;
            
            % Prepare column counters
            colidx   = struct();
            SScolidx = struct();
            lslch    = self.device.lsl.channels;
            nlsl     = numel(lslch);
            
            % --- Process NF sample values
            for i = 1:numel(self.channels)
                ch = self.channels(i);
                val = sample(i);
                if ch <= nlsl
                    type = lslch(ch).type;
                else
                    type = "unknown";
                end
                if ~isfield(colidx, type)
                    colidx.(type) = 1;
                end
                idxCol = colidx.(type);
                self.data.(type)(self.idx, idxCol)   = val;
                self.window.(type)(self.windowidx, idxCol) = val;
                colidx.(type) = idxCol + 1;
            end
            
            % --- Process SS sample values (guard against empty)
            if ~isempty(self.SSchannels) && ~isempty(SSsample)
                nSS = min(numel(self.SSchannels), numel(SSsample));
                for i = 1:nSS
                    ch  = self.SSchannels(i);
                    val = SSsample(i);
                    if ch <= nlsl
                        type = lslch(ch).type;
                    else
                        type = "unknown";
                    end
                    if ~isfield(SScolidx, type)
                        SScolidx.(type) = 1;
                    end
                    idxCol = SScolidx.(type);
                    self.SSdata.(type)(self.idx, idxCol)   = val;
                    self.SSwindow.(type)(self.windowidx, idxCol) = val;
                    SScolidx.(type) = idxCol + 1;
                end
            end
            
            % Notify window event
            notify(self, 'Window');
            if self.windowidx >= self.windowsize
                self.windownum = self.windownum + 1;
            end
        end
        
        %% Push a new feedback to running session
        function pushFeedback(self, rawVal, normVal, span)
            if ~self.running, return; end
            % store the un‑scaled (raw) feedback
            self.rawFeedback(self.idx)  = rawVal;
            % store the scaled [0–1] feedback
            self.normFeedback(self.idx) = normVal;
            % protocol timing book‑keeping remains the same
            self.protocolsum  = self.protocolsum + span;
            self.protocolavg  = self.protocolsum / double(self.idx);
            self.protocolmax  = max(self.protocolmax, span);
        end
        
        %% Save session to disk
        function save(self)
            used = max(self.idx, 1);
            
            export.study      = self.study;
            export.subject    = self.subject;
            export.run        = self.run;
            export.device     = self.device;
            export.protocol   = self.protocol;
            export.samplerate = self.srate;
            export.channels   = self.channels;
            export.SSchannels = self.SSchannels;
            export.starttime  = datetime(self.starttime,'ConvertFrom','datenum');
            export.stoptime   = datetime(self.stoptime,'ConvertFrom','datenum');
            export.duration   = self.length;
            export.windowsize = self.windowsize;
            export.runType    = cellstr( self.runType(1:used));
            
            % Export NF data
            types = fieldnames(self.data);
            for k = 1:numel(types)
                t = types{k};
                export.data.(t) = self.data.(t)(1:used, :);
                export.window.(t) = self.window.(t)(1:min(self.windowidx,self.windowsize), :);
            end
            
            % Export SS data
            typesSS = fieldnames(self.SSdata);
            for k = 1:numel(typesSS)
                t = typesSS{k};
                export.SSdata.(t) = self.SSdata.(t)(1:used, :);
                export.SSwindow.(t) = self.SSwindow.(t)(1:min(self.windowidx,self.windowsize), :);
            end
            
            export.times       = self.times(1:used);
            export.windowtimes = self.windowtimes(1:min(self.windowidx,self.windowsize));
            export.rawFeedback  = self.rawFeedback(1:used);
            export.normFeedback = self.normFeedback(1:used);
            export.markers     = self.markers(1:used);
            
            % Choose study name or default to "unnamed"
            if self.study == ""
                studyName = "unnamed";
            else
                studyName = self.study;
            end
            
            % Build the filename and save
            fname = sprintf("%s-%03d-%02d.mat", ...
                studyName, ...
                self.subject, self.run);
            save(fullfile("sessions", fname), '-struct', 'export');
        end
    end
end
