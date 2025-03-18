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
            % Clear the current protocol list and selection
            self.list = [];
            self.selected = struct();
        
            % List all protocol files in the "protocols" folder
            files = dir(fullfile("protocols", "*.m"));
            disp("Found protocol files:");
            for i = 1:length(files)
                disp(" - " + files(i).name);
            end
        
            % Iterate through each protocol file
            for f = 1:size(files, 1)
                file = files(f).name;
                name = strtrim(erase(file, ".m")); % Extract protocol name
                disp("Attempting to call function: " + name); % Debugging output
        
                try
                    fh = feval(name); % Try to call the protocol function
                    req = fh.requires(); % Get its requirements
                    disp(" - Successfully called '" + name + "'. Requirements:");
                    disp(req);
                catch ME
                    warning("Error calling function '" + name + "': " + ME.message);
                    continue; % Skip to the next file on error
                end
        
                % Check if the protocol is compatible with the device
                if ~self.iscompatible(req, device)
                    disp(" - Protocol '" + name + "' is not compatible with the device.");
                    continue;
                end
        
                % Add the protocol to the list
                idx = length(self.list) + 1;
                self.list(idx).name = name;
                self.list(idx).fh = fh;
                self.list(idx).req = req;
                disp(" - Protocol '" + name + "' added to the protocol list.");
            end
        
            % Final debugging output for the list
            if isempty(self.list)
                warning("No compatible protocols were found for the selected device.");
            else
                disp("Protocols loaded successfully:");
                for i = 1:length(self.list)
                    disp(" - " + self.list(i).name);
                end
            end
        end

        
        function r = iscompatible(~, req, dev)
            disp("Checking compatibility for protocol:");
            disp(req);
            disp("Against device:");
            disp(dev);
        
            % Check device type
            if req.devicetype ~= "ANY" && req.devicetype ~= dev.type
                disp(" - Incompatible: Device type mismatch.");
                r = false;
                return;
            end
        
            % Check channel requirements
            for idx = 1:length(req.channels)
                disp("Checking channel requirement: " + idx);
                disp(req.channels(idx));
                found = 0;
                for lslch = 1:length(dev.lsl.channels)
                    disp("Checking against device channel: " + lslch);
                    disp(dev.lsl.channels(lslch));
                    if req.channels(idx).type == dev.lsl.channels(lslch).type && ...
                       req.channels(idx).unit == dev.lsl.channels(lslch).unit
                        found = found + 1;
                    end
                end
                if found < req.channels(idx).min
                    disp(" - Incompatible: Not enough matching channels found.");
                    r = false;
                    return;
                end
            end
        
            disp(" - Compatible.");
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
