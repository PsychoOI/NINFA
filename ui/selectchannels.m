classdef selectchannels < handle
    %LSL CHANNEL SELECTION
    % UI for selecting NF (long) and SS (short) fNIRS channels,
    % with JSON pre‐selection, sanity checks, and live protocol validation.

    properties (Constant)
        figwidth            = 512;
        figheight           = 512;
        padding             = 8;
        buttonheight        = 24;
        panelwidth          = selectchannels.figwidth  - 2*selectchannels.padding;
        tablewidth          = selectchannels.panelwidth - 2*selectchannels.padding;
        panelheightrequired = 128;
        panelheightchannels = selectchannels.figheight - ...
                              4*selectchannels.padding - ...
                              selectchannels.panelheightrequired - ...
                              selectchannels.buttonheight;
        tableheightrequired = selectchannels.panelheightrequired - ...
                              2*selectchannels.padding - 16;
        tableheightchannels = selectchannels.panelheightchannels - ...
                              2*selectchannels.padding - 16;
    end

    properties (Dependent)
        selected    % NF (long) channel indices
        SSselected  % SS (short) channel indices
    end

    properties
        isok    logical = false;  % NF meets protocol requirements
        SSisok  logical = false;  % SS meets protocol requirements
    end

    properties (Access = private)
        selected_    uint32 = [];
        SSselected_  uint32 = [];
        visibleIdx  uint32 = [];    % maps each visible row → absolute LSL index

        hFig           matlab.ui.Figure;
        hRequiredPanel matlab.ui.container.Panel;
        hChannelsPanel matlab.ui.container.Panel;
        hRequired      matlab.ui.control.Table;
        hChannels      matlab.ui.control.Table;
        hButton        matlab.ui.control.Button;
        hStyleOk       matlab.ui.style.Style;
        hStyleNotOk    matlab.ui.style.Style;
    end

    events
        Done
    end

    methods
        %% Dependent‐property accessors
        function r = get.selected(self)
            r = self.selected_;
        end
        function set.selected(self, val)
            self.selected_ = uint32(val);
            self.updateOK();
        end

        function r = get.SSselected(self)
            r = self.SSselected_;
        end
        function set.SSselected(self, val)
            self.SSselected_ = uint32(val);
            self.updateOK();
        end

        %% Build (or refresh) the REQUIRED table
        function initRequired(self)
            if isempty(self.hFig) || ~isvalid(self.hFig)
                return;
            end
            global myprotocols;
            reqs = myprotocols.selected.fh.requires();
            n    = numel(reqs.channels);
            C    = cell(n, 8);
            for i = 1:n
                ch = reqs.channels(i);
                C{i,1} = ch.min;
                C{i,2} = ch.max;
                C{i,3} = 0;                % SEL_NF (will be updated below)
                C{i,4} = char(ch.type);
                C{i,5} = char(ch.unit);
                if isfield(reqs, 'SSchannels') && i <= numel(reqs.SSchannels)
                    ss = reqs.SSchannels(i);
                    C{i,6} = ss.min;
                    C{i,7} = ss.max;
                else
                    C{i,6} = 0;
                    C{i,7} = 0;
                end
                C{i,8} = 0;                % SEL_SS (will be updated below)
            end
            self.hRequired.Data = C;
        end

        %% Build (or refresh) the SELECTED table
        function initSelected(self)
            if isempty(self.hFig) || ~isvalid(self.hFig)
                return;
            end
            % build the list of *absolute* LSL indices that pass your filter
            global mydevices
            
            allCh = mydevices.selected.lsl.channels;
            vis   = uint32([]);
            for idx = 1:numel(allCh)
                if self.isChannelVisible(allCh(idx))
                    vis(end+1) = idx;
                end
            end
            self.visibleIdx = vis;
        
            % now build the table rows
            nVis = numel(vis);
            rows = cell(nVis,6);
            for r = 1:nVis
                absIdx = vis(r);
                ch     = allCh(absIdx);
                nf     = ismember(absIdx, self.selected_);
                ss     = ismember(absIdx, self.SSselected_);
                rows(r,:) = {
                    logical(nf), ...   % NF checkbox
                    r, ... % the row number
                    ch.devch,   ...   % DEV CH
                    char(ch.type), ...
                    char(ch.unit), ...
                    logical(ss)      % SS checkbox
                };
            end
        
            self.hChannels.Data = rows;
            % refresh the panel title
            self.hChannelsPanel.Title = sprintf('NF: %d  |  SS: %d', ...
                numel(self.selected_), numel(self.SSselected_));
            % and re‐validate everything
            self.updateOK();
        end

        %% Try JSON‐based preselection (no effect if UI is closed)
        function preselectFromDeviceJSON(self)
            global mydevices;
            dev = mydevices.selected;
            if isempty(dev) || ~isfield(dev,'lsl') || isempty(dev.lsl.channels)
                return;
            end
            map = dev.channel_map;
            % skip explicit empty arrays
            if isnumeric(map.long_channels) && isempty(map.long_channels) && ...
               isnumeric(map.short_channels) && isempty(map.short_channels)
                return;
            end

            try
                % Validate map, then pull long/short indices from device
                self.validateChannelMap(map, dev.lsl.channels);
                self.selected   = mydevices.getLongChannelIndices();
                self.SSselected = mydevices.getShortChannelIndices();
            catch ME
                userMsg    = strrep(ME.message, newline, ' ');
                dialogTitle = 'Channel Map Error';
                if ~isempty(self.hFig) && isvalid(self.hFig)
                    uialert(self.hFig, userMsg, dialogTitle);
                end
            end
        end

        %% Rebuild both tables (Required + Selected), but skip JSON if already manually chosen
        function refreshAll(self)
            if isempty(self.hFig) || ~isvalid(self.hFig)
                % UI isn’t built yet → only apply JSON defaults if user
                % has never touched selections at all:
                if isempty(self.selected_) && isempty(self.SSselected_)
                   self.preselectFromDeviceJSON();
                end
                return;
            end

            % Always rebuild the REQUIRED table
            self.initRequired();


            % Rebuild the SELECTED table to show the up‐to‐date state
            self.initSelected();
        end

        %% Show (build UI once, then bring to front)
        function show(self)
            if isempty(self.hFig) || ~isvalid(self.hFig)
                % Create main figure
                self.hFig = uifigure( ...
                    'Name','SELECT LSL CHANNELS', ...
                    'MenuBar','none', ...
                    'NumberTitle','off', ...
                    'Position',[0, 0, selectchannels.figwidth, selectchannels.figheight]);

                % ── REQUIRED panel ──
                self.hRequiredPanel = uipanel(self.hFig, ...
                    'Title','REQUIRED', ...
                    'AutoResizeChildren','on', ...
                    'Position',[ ...
                      selectchannels.padding, ...
                      selectchannels.figheight - selectchannels.padding - selectchannels.panelheightrequired, ...
                      selectchannels.panelwidth, selectchannels.panelheightrequired]);
                self.hRequired = uitable(self.hRequiredPanel, ...
                    'ColumnName',{'MIN_NF','MAX_NF','SEL_NF','TYPE','UNIT','MIN_SS','MAX_SS','SEL_SS'}, ...
                    'ColumnFormat',{'numeric','numeric','numeric','char','char','numeric','numeric','numeric'}, ...
                    'ColumnEditable',false(1,8), ...
                    'RowName',{}, ...
                    'Position',[ ...
                      selectchannels.padding, selectchannels.padding, ...
                      selectchannels.tablewidth, selectchannels.tableheightrequired]);

                % ── SELECTED panel ──
                self.hChannelsPanel = uipanel(self.hFig, ...
                    'Title','SELECTED: 0', ...
                    'AutoResizeChildren','on', ...
                    'Position',[ ...
                      selectchannels.padding, selectchannels.buttonheight + 2*selectchannels.padding, ...
                      selectchannels.panelwidth, selectchannels.panelheightchannels]);
                self.hChannels = uitable(self.hChannelsPanel, ...
                    'ColumnName',{'NF','LSL CH','DEV CH','TYPE','UNIT','SS'}, ...
                    'ColumnFormat',{'logical','numeric','numeric','char','char','logical'}, ...
                    'ColumnEditable',[true,false,false,false,false,true], ...
                    'RowName',{}, ...
                    'CellEditCallback',@self.onSelectedChanged, ...
                    'Position',[ ...
                      selectchannels.padding, selectchannels.padding, ...
                      selectchannels.tablewidth, selectchannels.tableheightchannels]);

                % ── Styles ──
                cCenter = uistyle('HorizontalAlignment','center');
                addStyle(self.hRequired,  cCenter, 'column', 1:8);
                addStyle(self.hChannels,  cCenter, 'column', [2,3]);
                self.hStyleOk    = uistyle('BackgroundColor','green','HorizontalAlignment','center');
                self.hStyleNotOk = uistyle('BackgroundColor','red',  'HorizontalAlignment','center');

                % ── OK button ──
                self.hButton = uibutton(self.hFig, ...
                    'Text','OK', ...
                    'FontWeight','bold', ...
                    'Position',[ ...
                      selectchannels.padding, selectchannels.padding, ...
                      selectchannels.panelwidth, selectchannels.buttonheight], ...
                    'ButtonPushedFcn',@self.onSelectedClicked);

                % Initial population of both tables:
                self.refreshAll();
            end

            % Bring the figure to front (visible)
            self.hFig.Visible = 'on';
            try
                self.hFig.RequestBringToFront();
            catch
                figure(self.hFig);
            end
        end

        function close(self)
            if ~isempty(self.hFig) && isvalid(self.hFig)
                delete(self.hFig);
            end
        end
    end


    methods (Access = private)
        %% Return true if that channel’s type/unit shows up in REQUIRED table
        function r = isChannelVisible(self, ch)
            if isempty(self.hRequired.Data)
                r = true;
                return;
            end
            D = self.hRequired.Data;
            for i = 1:size(D,1)
                if strcmp(D{i,4}, ch.type) && strcmp(D{i,5}, ch.unit)
                    r = true; 
                    return;
                end
            end
            r = false;
        end

        %% Flatten struct or flat vector into a column of IDs
        function ids = collectIDs(~, x)
            if isstruct(x)
                c = struct2cell(x);
                c = c(~cellfun(@isempty,c));
                ids = vertcat(c{:});
            else
                ids = x(:);
            end
        end

        %% Top‐level JSON sanity checks
        function validateChannelMap(self, map, allCh)
            if ~isstruct(map) || ~isfield(map,'long_channels') || ~isfield(map,'short_channels')
                error('selectchannels:InvalidChannelMap', ...
                      'channel_map must be a struct with fields ''long_channels'' & ''short_channels''');
            end

            % Flatten allCh if cell
            if iscell(allCh)
                allCh = vertcat(allCh{:});
            end
            if isempty(allCh)
                error('selectchannels:NoChannels', 'Device has no channels to validate.');
            end

            devChList = [allCh.devch];
            maxCh     = max(devChList);

            longIds  = collectIDs(self, map.long_channels);
            shortIds = collectIDs(self, map.short_channels);

            outOfRange = setdiff([longIds; shortIds], (1:maxCh).');
            if ~isempty(outOfRange)
                error('selectchannels:InvalidChannelMap', ...
                      'Channel IDs out of range [1–%d]: %s', maxCh, mat2str(outOfRange));
            end
            overlap = intersect(longIds, shortIds);
            if ~isempty(overlap)
                error('selectchannels:InvalidChannelMap', ...
                      'Channels cannot be both long & short: %s', mat2str(overlap));
            end

            if isstruct(map.long_channels)
                self.validatePerTypeMap(map.long_channels,  allCh, 'long_channels',  maxCh);
                self.validatePerTypeMap(map.short_channels, allCh, 'short_channels', maxCh);
            else
                self.validateChannelIDs(longIds,  maxCh, 'long_channels',  '', false);
                self.validateChannelIDs(shortIds, maxCh, 'short_channels', '', true);
            end
        end

        %% Per‐type grouping checks
        function validatePerTypeMap(self, mf, allCh, fieldName, maxCh)
            if iscell(allCh)
                allCh = vertcat(allCh{:});
            end
            devChList = [allCh.devch];

            for fn = fieldnames(mf)'
                subType = fn{1};  
                ids     = mf.(subType);
                if isempty(ids)
                    continue;
                end

                self.validateChannelIDs(ids, maxCh, fieldName, subType, true);

                mask  = ismember(devChList, ids);
                types = {allCh(mask).type};
                if ~any(strcmp(types, subType))
                    error('selectchannels:InvalidChannelMap', ...
                          'In JSON.%s.%s, no device channels of type ''%s'' were found.', ...
                          fieldName, subType, subType);
                end
            end
        end

        %% Flat‐vector / per‐subType checks
        function validateChannelIDs(~, ids, maxN, fieldName, subType, allowEmpty)
            if ~isempty(subType)
                ctx = sprintf('JSON.%s.%s', fieldName, subType);
            else
                ctx = sprintf('JSON.%s', fieldName);
            end

            idTag = fieldName;
            if ~isempty(subType)
                idTag = [idTag '_' subType];
            end
            errID = sprintf('selectchannels:Invalid_%s', idTag);

            if isempty(ids)
                if allowEmpty
                    return;
                else
                    error(errID, 'Field ''%s'' must not be empty.', ctx);
                end
            end

            if ~isvector(ids) || any(ids ~= floor(ids))
                error(errID, 'Field ''%s'' must be a vector of integers.', ctx);
            end

            if any(ids < 1) || any(ids > maxN)
                error(errID, 'Values in ''%s'' must be between 1 and %d.', ctx, maxN);
            end

            [u,~,ic] = unique(ids);
            counts   = accumarray(ic,1);
            dupIDs   = u(counts>1);
            if ~isempty(dupIDs)
                error(errID, 'Field ''%s'' contains duplicate IDs: %s.', ctx, mat2str(dupIDs));
            end

            if numel(ids) > maxN
                error(errID, 'Field ''%s'' has too many entries (max %d).', ctx, maxN);
            end
        end

        %% UI sanity check
        function ok = validateUISelection(self)
            global mydevices
            nlsl = numel(mydevices.selected.lsl.channels);  
        
            sel = self.selected_;
            ss  = self.SSselected_;
        
            ok1 = ~isempty(sel) && all(sel   >=1 & sel   <= nlsl);
            ok2 = isempty(ss)    || all(ss    >=1 & ss    <= nlsl);
            ok3 = isempty(intersect(sel, ss));  % no channel both long & short
        
            ok = ok1 && ok2 && ok3;
        end

        %% Protocol + UI validity & styling
         function updateOK(self)
            global myprotocols mydevices;
            % get per‐type requirements for NF
            reqs   = myprotocols.selected.fh.requires().channels;
            % all LSL channels
            lslchs = mydevices.selected.lsl.channels;
            % only keep valid indices
            sel    = intersect(self.selected_,   1:numel(lslchs));
            ss     = intersect(self.SSselected_, 1:numel(lslchs));
    
            % ——— 1) Update SEL_NF (col 3) ———
            self.isok = true;
            for i = 1:numel(reqs)
                r = reqs(i);
                % how many of the SELECTED NF match this type/unit?
                types = string({lslchs(sel).type});
                units = string({lslchs(sel).unit});
                cnt   = sum(types==string(r.type) & units==string(r.unit));
                % pick red/green style
                bg = self.hStyleOk;
                if cnt < r.min || cnt > r.max
                    bg = self.hStyleNotOk;
                    self.isok = false;
                end
                if isvalid(self.hRequired)
                    self.hRequired.Data{i,3} = cnt;             % SEL_NF
                    addStyle(self.hRequired, bg, 'cell', [i,3]);
                end
            end
    
            % ——— 2) Update SEL_SS (col 8) ———
            self.SSisok = true;
            rootReq = myprotocols.selected.fh.requires();  % the top‐level struct
            if isfield(rootReq,'SSchannels')
                for i = 1:numel(rootReq.SSchannels)
                    ssr = rootReq.SSchannels(i);               % has .min/.max
                    if ~isempty(ssr)
                        types = string({lslchs(ss).type});
                        units = string({lslchs(ss).unit});
                        cnt   = sum(types==string(reqs(i).type) & units==string(reqs(i).unit));
                        bg    = self.hStyleOk;
                        if cnt < ssr.min || cnt > ssr.max
                            bg = self.hStyleNotOk;
                            self.SSisok = false;
                        end
                        if isvalid(self.hRequired)
                            self.hRequired.Data{i,8} = cnt;     % SEL_SS
                            addStyle(self.hRequired, bg, 'cell', [i,8]);
                        end
                    end
                end
            end
    
            % ——— 3) Enable/disable OK button ———
            uiok = self.validateUISelection();
            if ~isempty(self.hButton) && isvalid(self.hButton)
                self.hButton.Enable = matlab.lang.OnOffSwitchState( ...
                    self.isok && self.SSisok && uiok );
            end
    
            % ——— 4) Refresh bottom‐panel title (“NF: x  |  SS: y”) ———
            if isvalid(self.hChannelsPanel)
                self.hChannelsPanel.Title = sprintf('NF: %d  |  SS: %d', ...
                    numel(sel), numel(ss));
            end
        end

        %% Table‐edit callback
        function onSelectedChanged(self, ~, ~)
            T  = self.hChannels.Data;
            nf = uint32([]);
            ss = uint32([]);
            for r = 1:size(T,1)
                if T{r,1}           % NF column
                    nf(end+1) = self.visibleIdx(r);
                end
                if T{r,6}           % SS column
                    ss(end+1) = self.visibleIdx(r);
                end
            end
            % now both JSON‐preselect and manual ticks feed the same vectors:
            self.selected_   = nf;
            self.SSselected_ = ss;
            self.updateOK();
        end

        %% OK button callback
        function onSelectedClicked(self, ~, ~)
            if ~self.isok
                uialert(self.hFig,'Invalid channel selection','Selection Error');
                return;
            end
            notify(self, 'Done');
            self.close();
        end
    end

    methods (Access = public)
        %% Deselect a list of channels (removes from both lists, then refresh UI)
        function deselectChannels(self, badList)
            if isempty(badList)
                return;
            end

            badList = unique(uint32(badList(:)));
            self.selected_   = setdiff(self.selected_,   badList, 'stable');
            self.SSselected_ = setdiff(self.SSselected_, badList, 'stable');

            if ~isempty(self.hFig) && isvalid(self.hFig)
                self.initSelected();
                self.updateOK();
            end
        end
    end
end
