classdef protocols < handle
    %Protocols
    %   Detailed explanation goes here

    properties (Constant)
    end
    
    properties
        list     struct = []
        selected struct = struct([]);
        SSselected struct = struct([]);
    end
    
    methods
        function reload(self, device)
            self.list       = [];
            self.selected   = struct();
            self.SSselected = struct();
        
            % If 'protocols' is a regular folder, ensure it's on the path:
            if exist('+protocols','dir') == 0
                addpath('protocols');
            end
        
            d = dir(fullfile('protocols','*.m'));
            for k = 1:numel(d)
                [~, base] = fileparts(d(k).name);   % e.g. 'BandPass'
        
                % If protocols is a package folder (+protocols), use package-qualifed name:
                if exist('+protocols','dir')
                    fqname = ['protocols.' base];
                else
                    fqname = base;
                end
        
                % Safeguard: skip if it's not callable
                if ~(exist(fqname,'file') || exist(fqname,'class'))
                    continue
                end
        
                % Call the protocol factory/constructor
                try
                    fh  = feval(fqname);
                catch err
                    warning('Skipping %s: %s', fqname, err.message);
                    continue
                end
        
                % Requirements & compatibility
                if ~isfield(fh,'requires') && ~ismethod(fh,'requires')
                    warning('Skipping %s: missing requires()', fqname);
                    continue
                end
        
                req = fh.requires();
                if ~self.iscompatible(req, device), continue; end
        
                idx = numel(self.list) + 1;
                self.list(idx).name = base;
                self.list(idx).fh   = fh;
                self.list(idx).req  = req;
            end
        end

        
        function r = iscompatible(~, req, dev)
            % check device type
            if req.devicetype ~= "ANY" && req.devicetype ~= dev.type
                r = false;
                return
            end
            % check channel requirements
            for idx = 1:length(req.channels)
                found = 0;
                for lslch = 1:length(dev.lsl.channels)
                    if req.channels(idx).type == dev.lsl.channels(lslch).type && ...
                       req.channels(idx).unit == dev.lsl.channels(lslch).unit
                       found = found + 1;
                    end
                end
                if found < req.channels(idx).min
                    r = false;
                    return
                end
            end
            r = true;
            % check SSchannel requirements
            if ~isfield(req, 'SSchannels')
                req.SSchannels = [];
            end

            for idx = 1:length(req.SSchannels)
                found = 0;
                for lslch = 1:length(dev.lsl.channels)
                     if req.SSchannels(idx).type == dev.lsl.channels(lslch).type && ...
                        req.SSchannels(idx).unit == dev.lsl.channels(lslch).unit
                        found = found + 1;
                     end
                 end
                 if found < req.SSchannels(idx).min
                     r = false;
                     return
                 end
            end
        end
        
        function r = select(self, name)
            for p = 1:length(self.list)
                % exact match
                if strcmp(char(self.list(p).name), char(name))
                    self.selected = self.list(p);
                    self.SSselected = self.list(p);
                    r = true;
                    return
                end
            end
            r = false;
        end
    end
end
