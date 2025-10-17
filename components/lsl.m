classdef lsl < handle
    %LSL Wrapper for reading data from liblsl

    properties (Constant)
        lib         struct    = lsl_loadlib();
    end
    
    properties
        streams     cell      = {};           % found streams
        stream      lsl_streaminfo;           % used stream
        inlet       lsl_inlet;                % inlet
        lslchannels uint32    = 0;            % lsl stream channel count
        sratenom    double    = 0.0;          % device claimed sample rate
        srate       double    = 0.0;          % measured sample rate
        channels    uint32    = [];           % channel numbers to use
        SSchannels  uint32    = [];           % short-separation channel numbers
        streaming   logical   = false;        % true if open() was successful
        tick        uint64    = 0;            % start tick of streaming
        nsamples    double    = 0.0;          % received samples since tick
        sample      double    = zeros(0);     % last sample (NF)
        SSsample    double    = zeros(0);     % last sample (SS)
        timestamp   double    = 0.0;          % last sample timestamp
        outtrigger  lsl_outlet;               % outlet for trigger
        outmarker   lsl_outlet;               % outlet for marker
        marker      double    = 0.0;          % current epoch marker
        N           (1,1) uint32 = 0          % number of channels per block inferred from LSL
    end
    
    events
        NewSample
    end
    
    methods
        function self = lsl()
            %LSL Construct an instance of this class
        end
        
        function set.marker(self, value) 
            if self.marker ~= value
                self.marker = value;
                self.trigger(value);
            end
        end

        function reset(self, rows, channels, SSchannels)
            %RESET  Configure which channels to read (NF & SS)
            global myprotocols;
            
            % Validate number of rows
            rows = ceil(rows);
            if rows == 0
                error("Rows can't be zero");
            end
            
            % Validate NF channels
            if isempty(channels)
                error("Channels can't be empty");
            end
            % Ensure all requested NF channels are in range
            if any(channels <= 0) || any(channels > self.lslchannels)
                error("Requested invalid channel(s) " + mat2str(channels) + ...
                      " of " + self.lslchannels);
            end
            
            % Apply NF selection
            self.channels = channels;
            nNF = numel(channels);
            self.sample = zeros(1, nNF);
            self.timestamp = 0;
            self.marker = 0;
            
            % Check if protocol requires SS channels
            req = myprotocols.selected.fh.requires();
            if isfield(req, 'SSchannels')
                if isempty(SSchannels)
                    % Allow "no SS" at runtime (e.g., sham where shorts drive NF)
                    self.SSchannels = [];
                    self.SSsample   = zeros(1, 0);
                else
                    % Validate SS channels when provided
                    if any(SSchannels <= 0) || any(SSchannels > self.lslchannels)
                        error("Requested invalid short channel(s) " + mat2str(SSchannels) + ...
                              " of " + self.lslchannels);
                    end
                    self.SSchannels = SSchannels;
                    nSS = numel(SSchannels);
                    self.SSsample = zeros(1, nSS);
                end
            else
                % Protocol does not require SS → none
                self.SSchannels = [];
                self.SSsample   = zeros(1, 0);
            end
        end
        
        function r = open(self, type)
            self.streams = lsl_resolve_byprop(self.lib, 'type', type, 1, 1);
            if ~isempty(self.streams)
                self.stream       = self.streams{1};
                self.lslchannels  = self.stream.channel_count();
                % Infer N from LSL stream (ignoring COUNTER if present)
                if mod(self.lslchannels, 4) == 1
                    % has COUNTER
                    self.N = uint32((self.lslchannels - 1) / 4);
                elseif mod(self.lslchannels, 4) == 0
                    % no COUNTER
                    self.N = uint32(self.lslchannels / 4);
                else
                    % inconsistent
                    error('lsl:BadChannelCount', ...
                          'LSL stream has %d channels, which cannot be split evenly into 4 blocks (+optional COUNTER).', ...
                          self.lslchannels);
                end

                self.sratenom     = self.stream.nominal_srate();
                self.inlet        = lsl_inlet(self.stream);
                self.outtrigger   = lsl_outlet( ...
                    lsl_streaminfo(self.lib, 'Trigger', 'Trigger', 1, 0));
                self.outmarker    = lsl_outlet( ...
                    lsl_streaminfo(self.lib, 'Marker',  'Marker',  1, self.sratenom));
                self.inlet.open_stream();
                self.streaming = true;
                self.nsamples  = 0;
                self.tick      = tic();
                r = true;
            else
                r = false;
            end
        end
        
        function close(self)
            if ~isempty(self.inlet)
                self.inlet.close_stream();
                self.streaming = false;
            end
            if ~isempty(self.outtrigger)
                delete(self.outtrigger);
            end
            if ~isempty(self.outmarker)
                delete(self.outmarker);
            end
        end
        
        function update(self)
            % Early exit if we haven't opened a stream
            if isempty(self.inlet)
                return
            end
        
            npullmax = ceil(max(1, max(self.srate, self.sratenom)));
            for pullCount = 1:npullmax
                [vec, ts] = self.inlet.pull_sample(0);
                if isempty(vec)
                    break
                end
        
                % Stamp & count
                self.timestamp = ts;
                self.nsamples  = self.nsamples + 1;
        
                % Make sure our sample buffer was allocated
                nChans = numel(self.channels);
                if numel(self.sample) ~= nChans
                    error('lsl:SampleBufferMismatch', ...
                          'LSL.sample length (%d) does not match channels count (%d). Did you call reset?', ...
                          numel(self.sample), nChans);
                end
        
                % Extract NF channels safely
                for idx = 1:nChans
                    ch = self.channels(idx);
                    if ch < 1 || ch > numel(vec)
                        error('lsl:InvalidChannelIndex', ...
                              'Requested NF channel index %d is out of range [1:%d].', ...
                              ch, numel(vec));
                    end
                    self.sample(idx) = vec(ch);
                end
        
                % Extract SS channels safely
                nSS = numel(self.SSchannels);
                if numel(self.SSsample) ~= nSS
                    error('lsl:SSSampleBufferMismatch', ...
                          'LSL.SSsample length (%d) does not match SSchannels count (%d).', ...
                          numel(self.SSsample), nSS);
                end
                for idx = 1:nSS
                    ch = self.SSchannels(idx);
                    if ch < 1 || ch > numel(vec)
                        error('lsl:InvalidSSChannelIndex', ...
                              'Requested SS channel index %d is out of range [1:%d].', ...
                              ch, numel(vec));
                    end
                    self.SSsample(idx) = vec(ch);
                end
        
                % Fire event & push marker
                notify(self, 'NewSample');
                if ~isempty(self.outmarker) && isvalid(self.outmarker)
                    self.outmarker.push_sample(self.marker);
                end
        
                if pullCount == npullmax
                    disp("WARNING: PULLED " + string(npullmax) + " LSL SAMPLES IN ONE TICK")
                end
            end
        
            % Recompute measured sample rate once per second
            elapsed = toc(self.tick);
            if elapsed >= 1.0
                self.srate = self.nsamples / elapsed;
            end
        end

        
        function r = trigger(self, value)
            if ~isempty(self.outtrigger) && isvalid(self.outtrigger) && value ~= 0
                self.outtrigger.push_sample(value);
                r = true;
            else
                r = false;
            end
        end
    end
end
