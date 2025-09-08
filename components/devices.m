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
                                      'short_channels', struct()), ...
                'channels_per_block', uint32(0), ...
                'modes',       struct(), ...
                'ui',          struct('blind_role', false), ...
                'randomize',   false, ...
                'default_mode', "A" ...
            );


            self.nirs        = emptyDevice([]);  
            self.eeg         = emptyDevice([]);  
            self.test_device = emptyDevice([]);  

            files = dir(fullfile("devices","*.json"));
            for f = 1:numel(files)
                json  = jsondecode(fileread(fullfile("devices", files(f).name)));
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
            % Required basics
            device.name = json.name;
            device.type = json.type;
            device.lsl  = json.lsl;
        
            % Channel map (global, not per-mode)
            if isfield(json,'channel_map')
                device.channel_map = json.channel_map;
            else
                device.channel_map = struct('long_channels', struct(), ...
                                            'short_channels', struct());
            end
        
            % Channels-per-block (optional hint for LSL sanity)
            if isfield(json,'channels_per_block')
                device.channels_per_block = uint32(json.channels_per_block);
            else
                device.channels_per_block = uint32(0);
            end
        
            % study/blinding fields from the single JSON profile
        
            % Modes A/B (label, role, protocol). Keep empty struct if missing.
            if isfield(json,'modes')
                device.modes = json.modes;
            else
                device.modes = struct();
                warning('devices:createDeviceStructure:NoModes', ...
                    'Device "%s": JSON has no "modes" object.', device.name);
            end
        
            % UI flags (currently only blind_role)
            device.ui = struct('blind_role', false);
            if isfield(json,'ui')
                if isfield(json.ui,'blind_role')
                    device.ui.blind_role = logical(json.ui.blind_role);
                end
            end
        
            % Randomize flag
            device.randomize = false;
            if isfield(json,'randomize')
                device.randomize = logical(json.randomize);
            end
        
            % Default mode (falls back to "A" with a warning)
            device.default_mode = "A";
            if isfield(json,'default_mode') && ~isempty(json.default_mode)
                device.default_mode = string(json.default_mode);
            else
                warning('devices:createDeviceStructure:DefaultModeMissing', ...
                    'Device "%s": default_mode missing; defaulting to "A".', device.name);
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
                if strcmp(char(list(i).name), char(name))   % robust to string/char
                    self.selected = list(i);
                    disp("Selected device: " + string(name) + " (" + string(type) + ")");
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
        function [ok] = sanityCheckSelected(self)
            % Simple sanity check for fNIRS device channels.
            % Ensures HbO and HbR exist, match, and COUNTER channel is present.

            ok = false;
        
            if isempty(self.selected) || ~isfield(self.selected,'lsl') || ~isfield(self.selected.lsl,'channels')
                error('No selected device or channels.');
            end
        
            allCh = self.selected.lsl.channels;
            if iscell(allCh), allCh = vertcat(allCh{:}); end
            if isempty(allCh)
                error('Selected device has empty channel list.');
            end
        
            types  = string({allCh.type});
            devchs = double([allCh.devch]);
        
            n_hbo = sum(types=="HbO");
            n_hbr = sum(types=="HbR");
        
            if n_hbo == 0 || n_hbr == 0
                error('Missing HbO or HbR channels (HbO=%d, HbR=%d).', n_hbo, n_hbr);
            end
        
            if n_hbo ~= n_hbr
                error('Mismatch between HbO (%d) and HbR (%d) channel counts.', n_hbo, n_hbr);
            end
        
            if ~any(types=="COUNTER" & devchs==0)
                error('Missing COUNTER channel with devch=0.');
            end
        
            % Passed
            ok = true;
            self.selected.channels_per_block  = uint32(n_hbo);
        end

    end
end
