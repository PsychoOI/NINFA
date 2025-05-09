classdef devices < handle
    %Devices
    %   Loads and manages devices from JSON files

    properties (Constant)
        types = ["NIRS", "EEG", "test_device"];
    end

    properties
        nirs        struct = struct([]);  % NIRS device array
        eeg         struct = struct([]);  % EEG device array
        test_device struct = struct([]);  % Test devices
        selected    struct = struct([]);  % Currently selected device
    end

    methods
        function self = devices()
            self.reload();
        end

        function reload(self)
            % Load all devices from "devices/" folder
            emptyDevice = struct( ...
                'name',        "", ...
                'type',        "", ...
                'lsl',         [], ...
                'channel_map', struct('long_channels', struct(), ...
                                      'short_channels', struct()) ...
            );

            self.nirs        = emptyDevice([]);  
            self.eeg         = emptyDevice([]);  
            self.test_device = emptyDevice([]);  

            files = dir(fullfile("devices","*.json"));
            for f = 1:numel(files)
                json = jsondecode(fileread(fullfile("devices", files(f).name)));
                device = self.createDeviceStructure(json);
                switch lower(json.type)
                    case 'nirs'
                        self.nirs(end+1) = device;
                    case 'eeg'
                        self.eeg(end+1) = device;
                    case 'test_device'
                        self.test_device(end+1) = device;
                    otherwise
                        warning("Unknown device type: %s", json.type);
                end
                disp("Loaded device: " + json.name + " (" + json.type + ")");
            end
        end

        function device = createDeviceStructure(~, json)
            device.name = json.name;
            device.type = json.type;
            device.lsl  = json.lsl;
            if isfield(json,'channel_map')
                device.channel_map = json.channel_map;
            else
                device.channel_map = struct('long_channels', struct(), ...
                                            'short_channels', struct());
            end
        end

        function ok = select(self, type, name)
            % Choose a device by type & name
            ok = false;
            switch lower(type)
                case 'nirs',         list = self.nirs;
                case 'eeg',          list = self.eeg;
                case 'test_device',  list = self.test_device;
                otherwise
                    warning("Unknown device type: %s", type);
                    return;
            end
            for i = 1:numel(list)
                if list(i).name == name
                    self.selected = list(i);
                    disp("Selected device: " + name + " (" + type + ")");
                    ok = true;
                    return;
                end
            end
            warning("Device %s of type %s not found.", name, type);
        end

        function idxs = getLongChannelIndices(self)
            % Translate devch IDs → LSL indices (long/HbO vs HbR) 
            cm = self.selected.channel_map.long_channels;
            if ~isstruct(cm)
                error('getLongChannelIndices:BadMap', ...
                      'long_channels must be a struct for device "%s"', ...
                      self.selected.name);
            end
            allCh = self.selected.lsl.channels;
            idxs  = uint32([]);
            for f = fieldnames(cm)'
                typStr = f{1};
                devchs = cm.(typStr);
                for d = devchs(:)'
                    % find only the channels whose devch==d AND whose type==typStr
                    matches = find( arrayfun(@(c) c.devch==d && strcmp(c.type,typStr), allCh) );
                    idxs = [idxs; uint32(matches(:))];
                end
            end
            idxs = unique(idxs);  % sort & remove duplicates
        end

        function idxs = getShortChannelIndices(self)
            cm = self.selected.channel_map.short_channels;
            if ~isstruct(cm)
                error('getShortChannelIndices:BadMap', ...
                      'short_channels must be a struct for device "%s"', ...
                      self.selected.name);
            end
            allCh = self.selected.lsl.channels;
            idxs  = uint32([]);
            for f = fieldnames(cm)'
                typStr = f{1};
                devchs = cm.(typStr);
                for d = devchs(:)'
                    matches = find( arrayfun(@(c) c.devch==d && strcmp(c.type,typStr), allCh) );
                    idxs = [idxs; uint32(matches(:))];
                end
            end
            idxs = unique(idxs);
        end
    end
end
