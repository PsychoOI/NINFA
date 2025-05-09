classdef selectchannels < handle
    %LSL CHANNEL SELECTION
    % UI for selecting NF (long) and SS (short) fNIRS channels,
    % with JSON pre-selection, sanity checks, and live protocol validation.

    properties (Constant)
        figwidth  = 512;
        figheight = 512;
        padding   = 8;
        buttonheight = 24;
        panelwidth   = selectchannels.figwidth  - 2*selectchannels.padding;
        tablewidth   = selectchannels.panelwidth - 2*selectchannels.padding;
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
        isok   logical = false;  % NF meets protocol requirements
        SSisok logical = false;  % SS meets protocol requirements
    end

    properties (Access=private)
        selected_   uint32 = [];
        SSselected_ uint32 = [];

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
        %% Dependent property accessors
        function r = get.selected(self)
            r = self.selected_;
        end
        function set.selected(self,val)
            self.selected_ = uint32(val);
            self.updateOK();
        end
        function r = get.SSselected(self)
            r = self.SSselected_;
        end
        function set.SSselected(self,val)
            self.SSselected_ = uint32(val);
            self.updateOK();
        end

        %% Build the REQUIRED table
        function initRequired(self)
            if isempty(self.hFig)||~isvalid(self.hFig), return; end
            global myprotocols;
            reqs = myprotocols.selected.fh.requires();
            n    = numel(reqs.channels);
            C    = cell(n,8);
            for i=1:n
                ch = reqs.channels(i);
                C{i,1} = ch.min;
                C{i,2} = ch.max;
                C{i,3} = 0;                % SEL_NF
                C{i,4} = char(ch.type);
                C{i,5} = char(ch.unit);
                if isfield(reqs,'SSchannels') && i<=numel(reqs.SSchannels)
                    ss = reqs.SSchannels(i);
                    C{i,6} = ss.min;
                    C{i,7} = ss.max;
                else
                    C{i,6} = 0;
                    C{i,7} = 0;
                end
                C{i,8} = 0;                % SEL_SS
            end
            self.hRequired.Data = C;
        end

        %% Build the SELECTED table
        function initSelected(self)
            if isempty(self.hFig)||~isvalid(self.hFig), return; end
            global mylsl mydevices;
            allCh = mydevices.selected.lsl.channels;
            rows  = cell(0,6);
            for idx=1:mylsl.lslchannels
                if idx<=numel(allCh) && self.isChannelVisible(allCh(idx))
                    nf = ismember(idx,self.selected_);
                    ss = ismember(idx,self.SSselected_);
                    ch = allCh(idx);
                    rows(end+1,:) = { ...
                        logical(nf), ...   % NF
                        idx, ...           % LSL CH
                        ch.devch, ...      % DEV CH
                        char(ch.type), ... % TYPE
                        char(ch.unit), ... % UNIT
                        logical(ss)};      % SS
                end
            end
            self.hChannels.Data = rows;
            self.hChannelsPanel.Title = sprintf( ...
                'NF: %d  |  SS: %d', numel(self.selected_), numel(self.SSselected_));
            self.updateOK();
        end

        %% Pre-select from JSON channel_map with UI feedback
        function preselectFromDeviceJSON(self)
            global mydevices;
            dev = mydevices.selected;
            if isempty(dev) || ~isfield(dev,'lsl') || isempty(dev.lsl.channels)
                return
            end
            map = dev.channel_map;
            % skip explicit empty arrays
            if isnumeric(map.long_channels) && isempty(map.long_channels) && ...
               isnumeric(map.short_channels) && isempty(map.short_channels)
                return
            end
    
            try
                % Attempt validation and pick the indices
                self.validateChannelMap(map, dev.lsl.channels);
                self.selected   = mydevices.getLongChannelIndices();
                self.SSselected = mydevices.getShortChannelIndices();

            catch ME
                % Prepare a succinct, user-facing message
                userMsg = strrep(ME.message, newline, ' ');  % single-line
                dialogTitle = 'Channel Map Error';
    
                if ~isempty(self.hFig) && isvalid(self.hFig)
                    % If the UI figure is up, use uialert
                    uialert(self.hFig, userMsg, dialogTitle);
                end
                % Do NOT rethrow — we've shown the error to the user
            end
        end

        %% Show (or refresh) the UI
        function show(self)
            if isvalid(self.hFig)
                self.initRequired();
                self.preselectFromDeviceJSON();
                self.initSelected();
                figure(self.hFig);
                return;
            end

            % Main figure
            self.hFig = uifigure( ...
                'Name','SELECT LSL CHANNELS', ...
                'MenuBar','none','NumberTitle','off', ...
                'Position',[0,0,selectchannels.figwidth,selectchannels.figheight]);

            % REQUIRED panel
            self.hRequiredPanel = uipanel(self.hFig, ...
                'Title','REQUIRED','AutoResizeChildren','on', ...
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

            % SELECTED panel
            self.hChannelsPanel = uipanel(self.hFig, ...
                'Title','SELECTED: 0','AutoResizeChildren','on', ...
                'Position',[ ...
                  selectchannels.padding, selectchannels.buttonheight+2*selectchannels.padding, ...
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

            % Styles
            c = uistyle('HorizontalAlignment','center');
            addStyle(self.hRequired, c, 'column',1:8);
            addStyle(self.hChannels, c, 'column',[2,3]);
            self.hStyleOk    = uistyle('BackgroundColor','green','HorizontalAlignment','center');
            self.hStyleNotOk = uistyle('BackgroundColor','red','HorizontalAlignment','center');

            % OK button
            self.hButton = uibutton(self.hFig, ...
                'Text','OK','FontWeight','bold', ...
                'Position',[ ...
                  selectchannels.padding, selectchannels.padding, ...
                  selectchannels.panelwidth, selectchannels.buttonheight], ...
                'ButtonPushedFcn',@self.onSelectedClicked);

            % Initial fill
            self.initRequired();
            self.preselectFromDeviceJSON();
            self.initSelected();
        end

        function close(self)
            if ~isempty(self.hFig) && isvalid(self.hFig)
                delete(self.hFig);
            end
        end
    end

    methods (Access=private)
        %% Visibility filter
        function r = isChannelVisible(self,ch)
            if isempty(self.hRequired.Data), r=true; return; end
            D = self.hRequired.Data;
            for i=1:size(D,1)
                if strcmp(D{i,4},ch.type) && strcmp(D{i,5},ch.unit)
                    r=true; return;
                end
            end
            r=false;
        end
        %% Helper: collect IDs from struct or flat vector
        function ids = collectIDs(~, x)
            if isstruct(x)
                c = struct2cell(x);
                c = c(~cellfun(@isempty, c));
                ids = vertcat(c{:});
            else
                ids = x(:);
            end
        end

         %% Top‐level JSON sanity checks
        function validateChannelMap(self, map, allCh)
            % Ensure struct with required fields
            if ~isstruct(map) || ~isfield(map,'long_channels') || ~isfield(map,'short_channels')
                error('selectchannels:InvalidChannelMap', ...
                      'channel_map must be a struct with fields ''long_channels'' & ''short_channels''');
            end
    
            % Flatten cell→struct if needed, and guard empty
            if iscell(allCh), allCh = vertcat(allCh{:}); end
            if isempty(allCh)
                error('selectchannels:NoChannels','Device has no channels to validate.');
            end
    
            devChList = [allCh.devch];
            maxCh     = max(devChList);
    
            % Extract lists
            longIds  = collectIDs(self, map.long_channels);
            shortIds = collectIDs(self, map.short_channels);
    
            % Range check & overlap
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
    
            % Delegate per‐type or flat checks
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
            % Flatten again if cell
            if iscell(allCh), allCh = vertcat(allCh{:}); end
            devChList = [allCh.devch];
    
            for fn = fieldnames(mf)'
                subType = fn{1};          % e.g. 'HbO' or 'HbR'
                ids     = mf.(subType);
                if isempty(ids), continue; end
    
                % Now validate that specific JSON.<fieldName>.<subType>
                % e.g: JSON.Long_Channel.HbO
                self.validateChannelIDs(ids, maxCh, fieldName, subType, true);
    
                % Ensure at least one device channel matches this type
                mask = ismember(devChList, ids);
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
            % Build a human‐readable context string
            if ~isempty(subType)
                ctx = sprintf('JSON.%s.%s', fieldName, subType);
            else
                ctx = sprintf('JSON.%s', fieldName);
            end
    
            % Error identifier (kept short)
            idTag = fieldName;
            if ~isempty(subType), idTag = [idTag '_' subType]; end
            errID = sprintf('selectchannels:Invalid_%s', idTag);
    
            % Empty?
            if isempty(ids)
                if allowEmpty
                    return
                else
                    error(errID, 'Field ''%s'' must not be empty.', ctx);
                end
            end
    
            % Integer vector?
            if ~isvector(ids) || any(ids ~= floor(ids))
                error(errID, 'Field ''%s'' must be a vector of integers.', ctx);
            end
    
            % Range
            if any(ids < 1) || any(ids > maxN)
                error(errID, 'Values in ''%s'' must be between 1 and %d.', ctx, maxN);
            end
    
            % Duplicates
            [u,~,ic]   = unique(ids);
            counts     = accumarray(ic,1);
            dupIDs     = u(counts>1);
            if ~isempty(dupIDs)
                error(errID, 'Field ''%s'' contains duplicate IDs: %s.', ctx, mat2str(dupIDs));
            end
    
            % Too many entries
            if numel(ids) > maxN
                error(errID, 'Field ''%s'' has too many entries (max %d).', ctx, maxN);
            end
        end



         %% UI‐sanity check
        function ok = validateUISelection(self)
            if isempty(self.hChannels) || ~isvalid(self.hChannels)
                ok = true; return;
            end
    
            totalCh = size(self.hChannels.Data,1);
            sel     = self.selected_;
            ss      = self.SSselected_;
    
            ok1 = ~isempty(sel) && all(sel>=1 & sel<=totalCh);
            ok2 = isempty(ss)   || all(ss>=1 & ss<=totalCh);
            ok3 = (numel(sel)+numel(ss)) <= totalCh;
    
            ok = ok1 && ok2 && ok3;
        end


        %% Protocol + UI validity & styling
        function updateOK(self)
            global myprotocols mydevices;
            reqs   = myprotocols.selected.fh.requires().channels;
            lslchs = mydevices.selected.lsl.channels;
            sel    = intersect(self.selected_,1:numel(lslchs));
            ss     = intersect(self.SSselected_,1:numel(lslchs));
            self.isok = ~isempty(sel);
            for i=1:numel(reqs)
                r = reqs(i);
                types = string({lslchs(sel).type});
                units = string({lslchs(sel).unit});
                cnt = sum(types==string(r.type) & units==string(r.unit));
                bg = self.hStyleOk;
                if cnt<r.min||cnt>r.max, bg = self.hStyleNotOk; self.isok=false; end
                if isvalid(self.hRequired)
                    self.hRequired.Data{i,3} = cnt;
                    addStyle(self.hRequired,bg,'cell',[i,3]);
                end
            end
            self.SSisok = true;
            for i=1:numel(reqs)
                r = reqs(i);
                if isfield(r,'SSchannels')&&~isempty(r.SSchannels)
                    types = string({lslchs(ss).type});
                    units = string({lslchs(ss).unit});
                    cnt = sum(types==string(r.type) & units==string(r.unit));
                    bg = self.hStyleOk;
                    if cnt<r.SSchannels.min||cnt>r.SSchannels.max, bg = self.hStyleNotOk; self.SSisok=false; end
                    if isvalid(self.hRequired)
                        self.hRequired.Data{i,7} = cnt;
                        addStyle(self.hRequired,bg,'cell',[i,7]);
                    end
                end
            end
            uiok = self.validateUISelection();
            if ~isempty(self.hButton)&&isvalid(self.hButton)
                self.hButton.Enable = matlab.lang.OnOffSwitchState(self.isok && self.SSisok && uiok);
            end
        end

        %% Table-edit callback
        function onSelectedChanged(self,~,~)
            T = self.hChannels.Data;
            nf = uint32([]); ss = uint32([]);
            for r=1:size(T,1)
                if T{r,1}, nf(end+1)=uint32(T{r,2}); end
                if T{r,6}, ss(end+1)=uint32(T{r,2}); end
            end
            self.selected   = nf;
            self.SSselected = ss;
        end

        %% OK button callback
        function onSelectedClicked(self,~,~)
            if ~self.isok
                uialert(self.hFig,'Invalid channel selection','Selection Error');
                return;
            end
            notify(self,'Done');
            self.close();
        end
    end
end
