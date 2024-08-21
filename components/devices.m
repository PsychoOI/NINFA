classdef devices < handle
    %Devices
    %   Detailed explanation goes here

    properties (Constant)
        types = ["NIRS", "EEG"]
    end
    
    properties
        nirs     struct = [];
        eeg      struct = [];
        selected struct = struct([]);
    end
    
    methods
        function self = devices()
            self.reload();
        end
        
        function reload(self)
            files = ls("devices/*.json");
            for f = 1:size(files, 1)
                file = files(f, 1:end);
                json = jsondecode(fileread("./devices/" + file));
                switch json.type
                    case "NIRS"
                        idx = length(self.nirs) + 1;
                        self.nirs(idx).name = json.name;
                        self.nirs(idx).type = json.type;
                        self.nirs(idx).lsl = json.lsl;
                    case "EEG"
                        idx = length(self.eeg) + 1;
                        self.eeg(idx).name = json.name;
                        self.eeg(idx).type = json.type;
                        self.eeg(idx).lsl = json.lsl;
                    otherwise
                        disp("Ignoring unknown device type");
                end
            end
        end
        
        function r = select(self, type, name)
            switch type
                case "NIRS"
                    for d = 1:length(self.nirs)
                        if self.nirs(d).name == name
                            self.selected = self.nirs(d);
                            r = true;
                            return
                        end
                    end
                case "EEG"
                    for d = 1:length(self.eeg)
                        if self.eeg(d).name == name
                            self.selected = self.eeg(d);
                            r = true;
                            return
                        end
                    end
                otherwise
                    warning("Ignoring unknown device type: " + type);
            end
            r = false;
        end
    end
end
