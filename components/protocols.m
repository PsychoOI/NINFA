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
        function self = protocols()
        end
        
        function reload(self, device)
            self.list = [];
            self.selected = struct();
            files = ls("protocols/*.m");
            for f = 1:size(files, 1)
                file = files(f, 1:end);
                name = strtrim(erase(file, ".m"));
                fh = feval(name);
                req = fh.requires();          
                if req.devicetype ~= "ANY" && req.devicetype ~= device.type
                    continue
                end
                idx = length(self.list) + 1;
                self.list(idx).name = name;
                self.list(idx).fh = fh;
                self.list(idx).req = req;
            end
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
