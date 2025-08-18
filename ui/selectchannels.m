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
        
            vis = uint32([]);
            for idx = 1:numel(allCh)
                if self.isChannelVisible(allCh(idx))
                    vis(end+1) = idx; %#ok<AGROW>
                end
            end
            self.visibleIdx = vis;
        
            % now build the table rows
            nVis = numel(vis);
            rows = cell(nVis,6);
            for r = 1:nVis
                absIdx = vis(r);          % absolute index in full LSL list
                ch     = allCh(absIdx);
                nf     = ismember(absIdx, self.selected_);
                ss     = ismember(absIdx, self.SSselected_);
                rows(r,:) = {
                    logical(nf), ...       % NF checkbox
                    absIdx,       ...      % LSL CH = absolute LSL index (FIXED)
                    ch.devch,     ...      % DEV CH (device numbering)
                    char(ch.type), ...
                    char(ch.unit), ...
                    logical(ss)            % SS checkbox
                };
            end
        
            self.hChannels.Data = rows;
        
            % regression guard: UI LSL column must equal visibleIdx
            try
                shown = cell2mat(self.hChannels.Data(:,2));
                if ~isequal(double(self.visibleIdx(:)), double(shown(:)))
                    warning('LSL CH column mismatch: UI not showing absolute LSL indices.');
                end
            catch
                % ignore if table is mid-build
            end
        
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
                % Validate the JSON against device channels
                self.validateChannelMap(map, dev.lsl.channels);
        
                % Convert JSON device IDs (HbO/HbR) to absolute LSL indices
                [longIdx, shortIdx] = self.devjson_to_lsl_indices(map, dev.lsl.channels);
        
                % Store as absolute indices (what the UI and logic use)
                self.selected   = longIdx;
                self.SSselected = shortIdx;
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
            % If REQUIRED table not ready, fallback to HbO/HbR-only selector
            if isempty(self.hRequired) || ~isvalid(self.hRequired) || isempty(self.hRequired.Data)
                r = strcmp(ch.type,'HbO') || strcmp(ch.type,'HbR');
                return;
            end
            % Otherwise, use REQUIRED-type filtering
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
    
            % Update SEL_NF (col 3)
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
    
            % Update SEL_SS (col 8)
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
    
            % Enable/disable OK button
            uiok = self.validateUISelection();
            if ~isempty(self.hButton) && isvalid(self.hButton)
                self.hButton.Enable = matlab.lang.OnOffSwitchState( ...
                    self.isok && self.SSisok && uiok );
            end
    
            % Refresh bottom‐panel title (“NF: x  |  SS: y”)
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

        function [longLSL, shortLSL] = devjson_to_lsl_indices(self, map, allCh)
            % Convert JSON dev channel lists (per type) into absolute LSL indices.
            % Only HbO/HbR are considered (UI design).
            longLSL  = uint32([]);
            shortLSL = uint32([]);
        
            % Ensure allCh is a flat struct array
            if iscell(allCh), allCh = vertcat(allCh{:}); end
        
            % Local helper to add matches from a map branch into a target vector
            function addFromBranch(branch, which) % which = 'long' or 'short'
                if ~isstruct(branch), return; end
                for wantedType = ["HbO","HbR"]
                    t = char(wantedType);
                    if ~isfield(branch, t), continue; end
                    devIDs = branch.(t);
                    if isempty(devIDs), continue; end
                    for d = devIDs(:)'
                        idx = find(arrayfun(@(c) strcmp(c.type,t) && c.devch==d, allCh), 1, 'first');
                        if ~isempty(idx)
                            if strcmp(which,'long')
                                longLSL(end+1) = uint32(idx); %#ok<AGROW>
                            else
                                shortLSL(end+1) = uint32(idx); %#ok<AGROW>
                            end
                        else
                            warning('No LSL channel found for (%s, devch=%d).', t, d);
                        end
                    end
                end
            end
        
            addFromBranch(map.long_channels,  'long');
            addFromBranch(map.short_channels, 'short');
        
            % Keep order stable and remove duplicates just in case
            longLSL  = unique(longLSL,  'stable');
            shortLSL = unique(shortLSL, 'stable');
        end
        % Per-type simulator helper: maps devch->LSL (tolerant) and counts predicted removals
        function H = simulateType_(self, devchs, typeStr)
            H = struct( ...
                'type',            string(typeStr), ...
                'requested_devch', uint32(devchs(:).'), ...
                'found_devch',     uint32([]), ...
                'not_found_devch', uint32([]), ...
                'found_lsl',       uint32([]), ...
                'nf_remove',       uint32([]), ...
                'ss_remove',       uint32([]), ...
                'nf_remove_count', uint32(0), ...
                'ss_remove_count', uint32(0));
    
            if isempty(devchs)
                return;
            end
    
            % Map devch -> LSL, but do NOT error if a devch doesn't exist; mark as "not found"
            found_lsl = uint32([]);
            found_dev = uint32([]);
            notfound  = uint32([]);
            for d = devchs(:).'
                try
                    idx = self.devch_to_lsl(d, typeStr);
                    found_lsl(end+1) = idx; %#ok<AGROW>
                    found_dev(end+1) = d;   %#ok<AGROW>
                catch
                    notfound(end+1) = d;    %#ok<AGROW>
                end
            end
    
            H.found_devch     = unique(found_dev, 'stable');
            H.not_found_devch = unique(notfound,  'stable');
            H.found_lsl       = unique(found_lsl, 'stable');
    
            % Predict removals by intersecting with current selections
            nf_to_remove = intersect(self.selected_,   H.found_lsl, 'stable');
            ss_to_remove = intersect(self.SSselected_, H.found_lsl, 'stable');
    
            H.nf_remove       = nf_to_remove;
            H.ss_remove       = ss_to_remove;
            H.nf_remove_count = uint32(numel(nf_to_remove));
            H.ss_remove_count = uint32(numel(ss_to_remove));
        end

        function [nNF, nSS] = getSelectionCounts_(self)
            nNF = uint32(numel(self.selected_));
            nSS = uint32(numel(self.SSselected_));
        end

        function s = joinIntList_(~, v)
            if isempty(v), s = ""; return; end
            s = strjoin(string(v(:).'), ',');
        end



        %% Deselect a list of channels (removes from both lists, then refresh UI)
        function deselectChannels(self, devchs, type)
            % Input checks
            if nargin < 3
                error('selectchannels:BadInput', ...
                    'deselectChannels(devchs, type) requires device channel(s) and a type (e.g., "HbO").');
            end
            if isempty(devchs)
                return;
            end
            if ~isvector(devchs) || ~isnumeric(devchs) || any(devchs ~= floor(devchs))
                error('selectchannels:BadInput','"devchs" must be an integer scalar or vector.');
            end
            T = string(type);
            if ~isscalar(T) || strlength(T)==0
                error('selectchannels:BadInput','"type" must be a nonempty scalar string/char (e.g., "HbO" or "HbR").');
            end

            % Normalize and map devch -> absolute LSL indices
            devchs = unique(double(devchs(:)'));              % dedupe, row
            badLSL = self.devch_to_lsl(devchs, T);

            % Remove from both selections (order preserved)
            self.selected_   = setdiff(self.selected_,   badLSL, 'stable');
            self.SSselected_ = setdiff(self.SSselected_, badLSL, 'stable');

            if ~isempty(self.hFig) && isvalid(self.hFig)
                self.initSelected();
                self.updateOK();
            end
        end
    end

    methods (Access = public)
        %% Map device channel(s) + type -> absolute LSL index/indices
        %  Usage:
        %     idx = obj.devch_to_lsl(5, 'HbO');           % scalar -> scalar
        %     idx = obj.devch_to_lsl([5 6 10], 'HbO');    % vector -> vector
        %  Returns:
        %     idx : uint32 row indices into mydevices.selected.lsl.channels
        %           (the same numbers shown in the "LSL CH" column).
        function idx = devch_to_lsl(self, devch, type)
            % Input checks
            if nargin < 3
                error('selectchannels:BadInput', ...
                      'devch_to_lsl(devch, type) needs devch and type.');
            end
            if ~isvector(devch) || ~isnumeric(devch) || any(devch ~= floor(devch))
                error('selectchannels:BadInput','"devch" must be an integer scalar or vector.');
            end
            T = string(type);
            if ~isscalar(T) || strlength(T) == 0
                error('selectchannels:BadInput','"type" must be a nonempty scalar string/char (e.g., "HbO").');
            end
        
            % Get current device channels
            global mydevices;
            allCh = mydevices.selected.lsl.channels;
            if iscell(allCh), allCh = vertcat(allCh{:}); end
            if isempty(allCh)
                error('selectchannels:NoChannels','No LSL channels for current device.');
            end
        
            % Prepare arrays for matching
            types  = string({allCh.type});
            devchs = double([allCh.devch]);
        
            % sanity: requested TYPE exists?
            if ~any(types == T)
                avail = unique(types);
                error('selectchannels:UnknownType', ...
                      'Type "%s" not found. Available types: %s', T, strjoin(cellstr(avail), ', '));
            end
        
            % Resolve each devch
            devch = double(devch(:)');        % row vector
            out   = NaN(1, numel(devch));
            for k = 1:numel(devch)
                d    = devch(k);
                hit  = find((types == T) & (devchs == d), 1, 'first');
                if isempty(hit)
                    error('selectchannels:NoMatchingLSL', ...
                          'No LSL channel for (type="%s", devch=%d).', T, d);
                end
                out(k) = hit;                 % deterministic
            end
        
            idx = uint32(out);
        end

        %% Parse a user string of devch numbers (tolerant; no ranges)
        %  Usage:
        %    P = obj.parseDevchInput(" 3, 7 , 12, ");
        %  Returns struct:
        %    P.devchs  : uint32 row vector of unique device channels (e.g., [3 7 12])
        %    P.ignored : string array of tokens that were not purely digits (e.g., ["a","?"])
        function P = parseDevchInput(~, raw)
            if nargin < 2 || isempty(raw)
                P = struct('devchs', uint32([]), 'ignored', string([]));
                return;
            end
            s = string(raw);
    
            % Normalize separators to commas, then split
            s = replace(s, [";", " "], ",");
            % Also collapse multiple commas
            while contains(s, ",,")
                s = replace(s, ",,", ",");
            end
    
            tokens = split(s, ",");
            tokens = strtrim(tokens);
            tokens = tokens(tokens ~= "");            % drop empties
    
            % Keep only pure digits; collect ignored
            isNumTok = arrayfun(@(t) ~isempty(regexp(t, '^\d+$', 'once')), tokens);
            goodTok  = tokens(isNumTok);
            badTok   = tokens(~isNumTok);
    
            vals = uint32(str2double(goodTok));
            vals = unique(vals, 'stable');           % dedupe, preserve order
    
            P = struct('devchs', vals(:).', 'ignored', badTok(:).');
        end
        %% Simulate a deselection (no state change) for preview
        %  Inputs: two devch lists (can be empty). "Both" should be expanded in UI before calling.
        %  Returns struct S with per-type preview and totals.
        function S = simulateDeselect(self, devchsHbO, devchsHbR)
            if nargin < 2, devchsHbO = []; end
            if nargin < 3, devchsHbR = []; end
    
            % Per-type results
            S.hbo = self.simulateType_(uint32(devchsHbO), "HbO");
            S.hbr = self.simulateType_(uint32(devchsHbR), "HbR");
    
            % Totals
            S.totals.nf_remove = S.hbo.nf_remove_count + S.hbr.nf_remove_count;
            S.totals.ss_remove = S.hbo.ss_remove_count + S.hbr.ss_remove_count;
            S.totals.found_devch     = [S.hbo.found_devch,     S.hbr.found_devch];
            S.totals.not_found_devch = [S.hbo.not_found_devch, S.hbr.not_found_devch];
    
            % Ready-to-show summary
            S.summary = sprintf( ...
                "HbO: -NF %d, -SS %d; HbR: -NF %d, -SS %d; Totals: -NF %d, -SS %d", ...
                S.hbo.nf_remove_count, S.hbo.ss_remove_count, ...
                S.hbr.nf_remove_count, S.hbr.ss_remove_count, ...
                S.totals.nf_remove,    S.totals.ss_remove);
        end

        %% Apply a deselection (commit) and return a brief result summary
        %  Inputs: two devch lists (can be empty). "Both" should be expanded in UI before calling.
        %  Returns R with before/after counts and a message.
        function R = applyDeselect(self, devchsHbO, devchsHbR)
            if nargin < 2, devchsHbO = []; end
            if nargin < 3, devchsHbR = []; end
    
            % Counts before
            [nfBefore, ssBefore] = self.getSelectionCounts_();
    
            % Apply (reuse your devch-based API; call per type if nonempty)
            if ~isempty(devchsHbO)
                self.deselectChannels(uint32(devchsHbO), 'HbO');
            end
            if ~isempty(devchsHbR)
                self.deselectChannels(uint32(devchsHbR), 'HbR');
            end
    
            % Counts after
            [nfAfter, ssAfter] = self.getSelectionCounts_();
    
            R = struct();
            R.nf_before = nfBefore;
            R.nf_after  = nfAfter;
            R.ss_before = ssBefore;
            R.ss_after  = ssAfter;
    
            % Short message for UI
            msgParts = string([]);
            if ~isempty(devchsHbO), msgParts(end+1) = "HbO(" + self.joinIntList_(devchsHbO) + ")"; end 
            if ~isempty(devchsHbR), msgParts(end+1) = "HbR(" + self.joinIntList_(devchsHbR) + ")"; end 
    
            if isempty(msgParts)
                R.message = sprintf("No channels specified. NF %d→%d, SS %d→%d.", nfBefore, nfAfter, ssBefore, ssAfter);
            else
                R.message = sprintf("Removed %s. NF %d→%d, SS %d→%d.", ...
                    strjoin(cellstr(msgParts), '; '), nfBefore, nfAfter, ssBefore, ssAfter);
            end
        end
    end
end
