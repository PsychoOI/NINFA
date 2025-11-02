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
        markerinfo  double  = zeros(0,8);   % info about epochs
        markers     double  = zeros(0,1);   % recorded epochs
        marker      double  = 0.0;          % current epoch (0 = undefined)
        bgcolor     double  = [0 0 0];      % current epoch background color
        fbvisible   logical = false;        % if feedback bar is visible
        study       string  = "";           % name of study
        subject     uint32  = 1;            % subject number
        run         uint32  = 1;            % run number
        transfer    logical  = false; % per‐epoch: whether transfer 1 or neurofeedback 0
        runType     categorical;      % per-sample vector, "transfer" | "neurofeedback"
        nf_channels_used uint32 = uint32([]); % Neurofeedback channels used as inputs to the algorithm
        ss_channels_used uint32 = uint32([]); % short separation channels used as inputs to the algorithm
        
    end
        % Blinded-condition metadata (saved for unblinding/repro)
    properties
        mode_label        string  = ""   % "A" | "B"
        mode_role         string  = ""   % "real" | "sham"
        mode_protocol     string  = ""   % protocol chosen by mode
        randomize_state   logical = false
        default_mode_used string  = "A"
        randseed                   = []   % [] or scalar (uint32/double)
        json_filename     string  = ""   % which single-device profile was used
        mode_source       string  = ""   % "default" | "randomize" | "manual"  (optional but handy)
        mode_reason       string  = ""   % free text override reason (optional)
        sham_uses_short  logical = false
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

            self.protocol = protocol;
            if strlength(self.mode_protocol) == 0
                self.mode_protocol = self.protocol;
            end
            if strlength(self.mode_protocol) == 0
                self.mode_protocol = self.protocol;
            end
            if isempty(self.default_mode_used)
                self.default_mode_used = "A";
            end
            self.protocolmax = 0.0;
            self.protocolavg = 0.0;
            self.protocolsum = 0.0;
            self.lengthmax   = lengthmax;
            self.srate       = srate;
            self.device      = device;
            self.channels    = channels;
            self.SSchannels  = SSchannels;
            % initialize everything as “transfer”
            self.transfer = false;
            self.runType    = categorical( ...
                                repmat("transfer", self.datasize,1), ...
                                ["neurofeedback","transfer"]);
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
                    self.transfer  = logical(m(4));
                    self.fbvisible = logical(m(5));
                    self.bgcolor   = m(6:8);
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

            if self.transfer
                self.runType(self.idx) = "transfer";
            else
                self.runType(self.idx) = "neurofeedback";
            end

            if self.firsttime == 0
                self.firsttime = ts;
            end
            relts = ts - self.firsttime;
            
            % Shift window if full
            if self.windowidx < self.windowsize
                self.windowidx = self.windowidx + 1;
            else
                % Shift NF window
                for fn = fieldnames(self.window)'
                    self.window.(fn{1}) = circshift(self.window.(fn{1}), -1);
                end
            
                % Shift SS window 
                for fn = fieldnames(self.SSwindow)'
                    self.SSwindow.(fn{1}) = circshift(self.SSwindow.(fn{1}), -1);
                end
                % Shift the time-vector
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
            % how many samples actually recorded
            used = max(self.idx, 1);

            % build export filename based on the study parameters
            export.study      = self.study;
            export.subject    = self.subject;
            export.run        = self.run;

            export.samplerate = self.srate;
            export.channels   = self.channels; % NF channels actually used
            export.SSchannels = self.SSchannels; % SS channels actually used

            export.starttime  = datetime(self.starttime,'ConvertFrom','datenum');
            export.stoptime   = datetime(self.stoptime,'ConvertFrom','datenum');
            export.duration   = self.length;
            export.windowsize = self.windowsize;

            export.device     = self.device;
            export.protocol   = self.protocol;
            
            % per-sample bookkeeping
            export.times       = self.times(1:used);
            export.runType = cellstr(self.runType(1:used)); % "transfer" | "neurofeedback"
            export.rawFeedback  = self.rawFeedback(1:used);
            export.normFeedback = self.normFeedback(1:used);
            export.markers     = self.markers(1:used);

            % Blinded-condition metadata
            export.mode_label        = self.mode_label;        % "A"/"B"
            export.mode_role         = self.mode_role;         % "real"/"sham"
            export.mode_protocol     = self.mode_protocol;     % e.g., "MovAvg_SS"
            export.randomize_state   = logical(self.randomize_state);
            export.default_mode_used = self.default_mode_used; % "A" unless device JSON said otherwise
            export.randseed          = self.randseed;          % [] unless randomized
            export.json_filename     = self.json_filename;     % device JSON name
            export.mode_source       = self.mode_source;       % "default"/"randomize"/"manual" (optional)
            export.mode_reason       = self.mode_reason;       % override reason (optional)

            
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
            
            export.windowtimes = self.windowtimes(1:min(self.windowidx,self.windowsize));
            
            
            % Study folder & safe names
            studyName = self.study;
            if studyName == "", studyName = "unnamed"; end
        
            % Safe folder/prefix (replace anything non [A-Za-z0-9._-] with '_')
            safeStudy = regexprep(string(studyName), '[^A-Za-z0-9._-]', '_');
        
            baseDir = fullfile("sessions", safeStudy);
            if ~exist(baseDir, 'dir'), mkdir(baseDir); end
        
            % Timestamp as YYYY-MM-DD_HH-MM-SS
            ts = string(datetime(self.starttime, 'ConvertFrom', 'datenum', ...
                                 'Format', 'yyyy-MM-dd_HH-mm-ss'));
        
            % Filename: <Study>_S###_R##_<ts>.mat
            baseName = sprintf("%s_S%03d_R%02d_%s", safeStudy, self.subject, self.run, ts);
            fpath    = fullfile(baseDir, baseName + ".mat");
        
            % A rare collision handling: add _v02, _v03, ...
            if exist(fpath, 'file')
                k = 2;
                while true
                    candidate = fullfile(baseDir, baseName + sprintf("_v%02d.mat", k));
                    if ~exist(candidate, 'file')
                        fpath = candidate;
                        break;
                    end
                    k = k + 1;
                end
            end
        
            % Save
            save(fpath, '-struct', 'export');
        end
    end
end
