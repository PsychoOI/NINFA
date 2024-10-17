classdef protocols < handle
    %Protocols
    %   Detailed explanation goes here

    properties (Constant)
    end
    
    properties
        list     struct = []
        selected struct = struct([]);
    end
    
    methods
        function reload(self, device)
            self.list = [];
            self.selected = struct();
            files = dir(fullfile("protocols", "*.m"));
            for f = 1:size(files, 1)
                file = files(f).name;
                name = strtrim(erase(file, ".m"));
                disp("Attempting to call function: " + name); % Debugging output
                try
                    fh = feval(name);           
                    req = fh.requires();
                catch ME
                    warning("Error calling function '" + name + "': " + ME.message); % Log any errors
                    continue; % Skip to the next file
            end

                if ~self.iscompatible(req, device)
                    continue
                end
                idx = length(self.list) + 1;
                self.list(idx).name = name;
                self.list(idx).fh = fh;
                self.list(idx).req = req;
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
        end
        
        function r = select(self, name)
            for p = 1:length(self.list)
                if self.list(p).name == name
                    self.selected = self.list(p);
                    r = true;
                    return
                end
            end
            r = false;
        end
    end
end
