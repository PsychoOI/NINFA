classdef devices < handle
    %Devices
    %   Detailed explanation goes here

    properties (Constant)
        types = ["NIRS", "EEG", "test_device"]
    end
    
    properties
        nirs     struct = [];
        eeg      struct = [];
        test_device struct = [];
        selected struct = struct([]);
    end
    
    methods
        function self = devices()
            self.reload();
        end
        
        function reload(self)
            files = dir(fullfile("devices", "*.json")); % Get a list of JSON 
            for f = 1:size(files, 1)
                file = files(f).name; % Get the filename from the structure
                disp("Attempting to open file: " + file); % Display the file being processed

                % Construct the full path to the JSON file
                filepath = fullfile(".", "devices", file);

                % Check if the file exists before trying to read it
                if exist(filepath, 'file') == 2
                    json = jsondecode(fileread(filepath)); % Read and decode JSON
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
                        case "test_device"
                            idx = length(self.test_device) + 1;
                            self.test_device(idx).name = json.name;
                            self.test_device(idx).type = json.type;
                            self.test_device(idx).lsl = json.lsl;
                        otherwise
                            disp("Ignoring unknown device type");
                    end
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
                case "test_device"
                    for d = 1:length(self.test_device)
                        if self.test_device(d).name == name
                            self.selected = self.test_device(d);
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