classdef devices < handle
    %Devices
    %   Loads and manages devices from JSON files

    properties (Constant)
        types = ["NIRS", "EEG", "test_device"]
    end

    properties
        nirs struct = struct([]);          % NIRS device array
        eeg struct = struct([]);           % EEG device array
        test_device struct = struct([]);   % Test devices
        selected struct = struct([]);      % Currently selected device
    end

    methods
        function self = devices()
            self.reload();
        end

        function reload(self)
            % Load all devices from "devices/" folder
            emptyDevice = struct( ...
                'name', "", ...
                'type', "", ...
                'lsl', [], ...
                'channel_map', struct('long_channels', struct(), 'short_channels', struct()) ...
            );


            self.nirs = emptyDevice([]);
            self.eeg = emptyDevice([]);
            self.test_device = emptyDevice([]);

            files = dir(fullfile("devices", "*.json"));

            for f = 1:numel(files)
                file = files(f).name;
                disp("Attempting to open file: " + file);
                filepath = fullfile(".", "devices", file);

                if exist(filepath, 'file') == 2
                    json = jsondecode(fileread(filepath));
                    self.processDeviceJson(json);
                else
                    warning("File not found: " + filepath);
                end
            end
        end

        function processDeviceJson(self, json)
            device = self.createDeviceStructure(json);

            switch lower(json.type)
                case 'nirs'
                    self.nirs(end + 1) = device;
                case 'eeg'
                    self.eeg(end + 1) = device;
                case 'test_device'
                    self.test_device(end + 1) = device;
                otherwise
                    warning("Unknown device type: " + json.type);
            end

            disp("Loaded device: " + json.name + " (" + json.type + ")");
        end

        function device = createDeviceStructure(~, json)
            device.name = json.name;
            device.type = json.type;
            device.lsl = json.lsl;
            if isfield(json, 'channel_map')
                device.channel_map = json.channel_map;
            else
                device.channel_map = struct('long_channels', [], 'short_channels', []);
            end
        end

        function r = select(self, type, name)
            list = [];
            switch lower(type)
                case 'nirs'
                    list = self.nirs;
                case 'eeg'
                    list = self.eeg;
                case 'test_device'
                    list = self.test_device;
                otherwise
                    warning("Unknown device type: " + type);
                    r = false;
                    return;
            end

            for i = 1:numel(list)
                if list(i).name == name
                    self.selected = list(i);
                    disp("Selected device: " + name + " (" + type + ")");
                    r = true;
                    return;
                end
            end

            r = false;
            disp("Device " + name + " of type " + type + " not found.");
        end
    end
end
