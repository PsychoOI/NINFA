classdef lsl < handle
    %LSL Wrapper for reading data from liblsl
    %   Detailed explanation goes here

    properties (Constant)
        lib         struct = lsl_loadlib();
    end
    
    properties
        streams     cell = {};           % found streams
        stream      lsl_streaminfo;      % used stream
        inlet       lsl_inlet;           % inlet
        lslchannels uint32 = 0;          % lsl stream channel count
        sratenom    double = 0.0;        % device claimed sample rate
        srate       double = 0.0;        % measured sample rate
        channels    uint32 = [];         % channel numbers to use
        streaming   logical = 0;         % true if open() was successful
        tick        uint64 = 0;          % start tick of streaming
        nsamples    double = 0.0;        % received samples since tick
        sample      double = zeros(0);   % last sample
        timestamp   double = 0.0;        % last sample timestamp
        outtrigger  lsl_outlet;          % outlet for trigger
        outmarker   lsl_outlet;          % outlet for marker
        marker      double = 0.0;        % current epoch marker
    end
    
    events
        NewSample
    end
    
    methods
        function self = lsl()
            %LSL Construct an instance of this class
        end
        
        function set.marker(self, value) 
            if (self.marker ~= value)
                self.marker = value;
                self.trigger(value);
            end
        end

        function reset(self, rows, channels)
            cols = length(channels);
            rows = ceil(rows);
            if rows == 0, error("Rows can't be zero"); end
            if cols == 0, error("Channels can't be empty"); end
            for ch = channels
                if ch <= 0 || ch > self.lslchannels
                    error("Requested invalid channel " ...
                        + ch + " of " + self.lslchannels);
                end
            end
            self.channels = channels;
            self.sample = zeros(1, cols);
            self.timestamp = 0;
            self.marker = 0;
        end
        
        function r = open(self, type)
            self.streams = lsl_resolve_byprop(self.lib,'type',type,1,1);
            if ~isempty(self.streams)
                self.stream = self.streams{1};
                self.lslchannels = self.stream.channel_count();
                self.sratenom = self.stream.nominal_srate();
                self.inlet = lsl_inlet(self.stream);
                self.outtrigger = lsl_outlet(lsl_streaminfo(self.lib, ...
                    'Trigger', 'Trigger', 1, 0));
                self.outmarker = lsl_outlet(lsl_streaminfo(self.lib, ...
                    'Marker', 'Marker', 1, self.sratenom));
                self.inlet.open_stream();
                self.streaming = true;
                self.nsamples = 0;
                self.tick = tic();
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
            if isempty(self.inlet)
                return
            end
            npullmax = ceil(max(1, max(self.srate, self.sratenom)));
            for i = 1:npullmax
                [vec,ts] = self.inlet.pull_sample(0);
                if ~isempty(vec)
                    self.timestamp = ts;
                    idx = 1;
                    self.nsamples = self.nsamples + 1;
                    for ch = self.channels
                        self.sample(idx) = vec(ch);
                        idx = idx + 1;
                    end
                    notify(self, 'NewSample');
                    if isvalid(self.outmarker) && ~isempty(self.outmarker)
                        self.outmarker.push_sample(self.marker);
                    end
                    if i == npullmax
                        disp("WARNING: PULLED " + string(npullmax) + ...
                            " LSL SAMPLES IN ONE TICK")
                    end
                else
                    break
                end
            end
            elapsed = toc(self.tick);
            if elapsed >= 1.0
                self.srate = self.nsamples / elapsed;
            end
        end
        
        function r = trigger(self, value)
            if isvalid(self.outtrigger) && ~isempty(self.outtrigger) && value ~= 0
                self.outtrigger.push_sample(value);
                r = true;
            else
                r = false;
            end
        end
    end
end
