classdef selectchannels < handle
    %LSL CHANNEL SELECTION
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (Constant)
        figwidth  = 512;
        figheight = 512;
        padding = 8;
        buttonheight = 24;
        panelwidth = selectchannels.figwidth - 2*selectchannels.padding;
        tablewidth = selectchannels.panelwidth - 2*selectchannels.padding;
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
        selected       % Public: backed by selected_
        SSselected     % Public: backed by SSselected_
    end

    properties
        % Validity flags (exposed for AppDesigner callbacks)
        isok    logical = false;
        SSisok  logical = false;
    end

    properties (Access = private)
        % Backing fields for Dependent properties
        selected_   uint32 = [];
        SSselected_ uint32 = [];

        % UI handles
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

        %% Exposed methods for AppDesigner
        function initRequired(self)
            if isempty(self.hFig) || ~isvalid(self.hFig), return; end
            global myprotocols;
            reqs = myprotocols.selected.fh.requires();
            self.hRequired.Data = strings(0,8);
            for i = 1:numel(reqs.channels)
                if isfield(reqs, 'SSchannels') && i <= numel(reqs.SSchannels)
                    minSS = reqs.SSchannels(i).min;
                    maxSS = reqs.SSchannels(i).max;
                else
                    minSS = 0; maxSS = 0;
                end
                self.hRequired.Data(i,:) = [
                    reqs.channels(i).min, reqs.channels(i).max, 0, ...
                    reqs.channels(i).type, reqs.channels(i).unit, ...
                    minSS, maxSS, 0
                ];
            end
        end

        function initSelected(self)
            if isempty(self.hFig) || ~isvalid(self.hFig), return; end
            global mylsl mydevices;
            data = strings(0,6);
            row = 1;
            for idx = 1:mylsl.lslchannels
                if idx <= numel(mydevices.selected.lsl.channels) && self.isChannelVisible(mydevices.selected.lsl.channels(idx))
                    nf = ismember(idx, self.selected_);
                    ss = ismember(idx, self.SSselected_);
                    data(row,:) = [
                        string(nf), string(idx), ...
                        string(mydevices.selected.lsl.channels(idx).devch), ...
                        mydevices.selected.lsl.channels(idx).type, ...
                        mydevices.selected.lsl.channels(idx).unit, ...
                        string(ss)
                    ];
                    row = row + 1;
                end
            end
            self.hChannels.Data = data;
            self.hChannelsPanel.Title = sprintf('NF: %d  |  SS: %d', numel(self.selected_), numel(self.SSselected_));
            self.updateOK();
        end

      function preselectFromDeviceJSON(self)
        global mydevices;
        if ~isfield(mydevices.selected, 'channel_map')
            return;            % nothing to do if user omitted it
        end
    
        map   = mydevices.selected.channel_map;
        allCh = mydevices.selected.lsl.channels;
        selLong  = uint32([]);
        selShort = uint32([]);
    
        %% 1) Handle long_channels
        if isfield(map, 'long_channels')
            lc = map.long_channels;
            if isnumeric(lc)
                % old-style: a flat list of devch IDs
                idxs = self.findLSLIndicesFromDevch(allCh, lc);
                selLong = uint32(idxs);
            elseif isstruct(lc)
                % new-style: per-type groups
                for f = fieldnames(lc)'
                    typ    = f{1};
                    devchs = lc.(typ);
                    idxs   = self.findLSLIndicesFromDevch(allCh, devchs);
                    for j = idxs
                        if strcmp(allCh(j).type, typ)
                            selLong(end+1) = uint32(j);
                        end
                    end
                end
            end
        end
    
        %% 2) Handle short_channels (same logic)
        if isfield(map, 'short_channels')
            sc = map.short_channels;
            if isnumeric(sc)
                idxs = self.findLSLIndicesFromDevch(allCh, sc);
                selShort = uint32(idxs);
            elseif isstruct(sc)
                for f = fieldnames(sc)'
                    typ    = f{1};
                    devchs = sc.(typ);
                    idxs   = self.findLSLIndicesFromDevch(allCh, devchs);
                    for j = idxs
                        if strcmp(allCh(j).type, typ)
                            selShort(end+1) = uint32(j);
                        end
                    end
                end
            end
        end
    
        %% 3) Assign back through the dependent properties
        self.selected  = selLong;
        self.SSselected = selShort;
    end


        %% Show or refresh UI
        function show(self)
            if isvalid(self.hFig)
                self.initRequired(); self.preselectFromDeviceJSON(); self.initSelected();
                figure(self.hFig); return;
            end
            % Build UI
            self.hFig = uifigure('Name','SELECT LSL CHANNELS','MenuBar','none','NumberTitle','off', ...
                'Position',[0,0,selectchannels.figwidth,selectchannels.figheight]);
            % Required panel
            self.hRequiredPanel = uipanel(self.hFig,'Title','REQUIRED','AutoResizeChildren','on', ...
                'Position',[selectchannels.padding,selectchannels.figheight-selectchannels.padding-selectchannels.panelheightrequired, ...
                            selectchannels.panelwidth,selectchannels.panelheightrequired]);
            self.hRequired = uitable(self.hRequiredPanel,'ColumnName',{'MIN_NF','MAX_NF','SEL_NF','TYPE','UNIT','MIN_SS','MAX_SS','SEL_SS'}, ...
                'ColumnFormat',{'short','short','short','char','char','short','short','short'}, ...
                'ColumnEditable',false(1,8),'RowName',{}, ...
                'Position',[selectchannels.padding,selectchannels.padding,selectchannels.tablewidth,selectchannels.tableheightrequired]);
            % Channels panel
            self.hChannelsPanel = uipanel(self.hFig,'Title','SELECTED: 0','AutoResizeChildren','on', ...
                'Position',[selectchannels.padding,selectchannels.buttonheight+2*selectchannels.padding, ...
                            selectchannels.panelwidth,selectchannels.panelheightchannels]);
            self.hChannels = uitable(self.hChannelsPanel,'ColumnName',{'NF','LSL CH','DEV CH','TYPE','UNIT','SS'}, ...
                'ColumnFormat',{'logical','short','short','char','char','logical'}, ...
                'ColumnEditable',[true,false,false,false,false,true],'RowName',{}, ...
                'Position',[selectchannels.padding,selectchannels.padding,selectchannels.tablewidth,selectchannels.tableheightchannels], ...
                'CellEditCallback',@self.onSelectedChanged);
            % Styles
            cstyle = uistyle('HorizontalAlignment','center');
            addStyle(self.hChannels,cstyle,'column',[2,3]);
            addStyle(self.hRequired,cstyle,'column',[1,2,3]);
            self.hStyleOk = uistyle('BackgroundColor','green','HorizontalAlignment','center');
            self.hStyleNotOk = uistyle('BackgroundColor','red','HorizontalAlignment','center');
            % OK button
            self.hButton = uibutton(self.hFig,'Text','OK','FontWeight','bold', ...
                'Position',[selectchannels.padding,selectchannels.padding,selectchannels.panelwidth,selectchannels.buttonheight], ...
                'ButtonPushedFcn',@self.onButtonClicked);
            % Initialize
            self.initRequired(); self.preselectFromDeviceJSON(); self.initSelected();
            self.hFig.Visible='on';
        end

        %% Close method exposed for AppDesigner
        function close(self)
            if ~isempty(self.hFig) && isvalid(self.hFig)
                delete(self.hFig);
            end
        end
    end

    methods (Access = private)
        %% Visibility logic
        function r = isChannelVisible(self, channel)
            if isempty(self.hRequired.Data), r=true; return; end
            for i=1:size(self.hRequired.Data,1)
                if self.hRequired.Data(i,4)==channel.type && self.hRequired.Data(i,5)==channel.unit
                    r=true; return; end
            end
            r=false;
        end

        %% Map devch list to LSL indices
        function indices = findLSLIndicesFromDevch(~,lslchs,devchList)
            indices = uint32([]);
            for i=1:numel(lslchs)
                if ismember(lslchs(i).devch,devchList)
                    indices(end+1)=uint32(i);
                end
            end
        end

        %% Update OK status and style required table
        function updateOK(self)
            global myprotocols mydevices;
            chreq = myprotocols.selected.fh.requires().channels;
            lslchs = mydevices.selected.lsl.channels;
            self.isok = ~isempty(self.selected_);
            for i=1:numel(chreq)
                cnt=0;
                for id=self.selected_
                    if id<=numel(lslchs) && strcmp(chreq(i).type,lslchs(id).type) && strcmp(chreq(i).unit,lslchs(id).unit)
                        cnt=cnt+1;
                    end
                end
                st=self.hStyleOk; if cnt<chreq(i).min || cnt>chreq(i).max, self.isok=false; st=self.hStyleNotOk; end
                if isvalid(self.hRequired)
                    self.hRequired.Data(i,3)=cnt;
                    addStyle(self.hRequired,st,'cell',[i,3]);
                end
            end
            self.SSisok=true;
            for i=1:numel(chreq)
                if isfield(chreq(i),'SSchannels') && ~isempty(chreq(i).SSchannels)
                    ssc=0;
                    for id=self.SSselected_
                        if id<=numel(chreq(i).SSchannels), ssc=ssc+1; end
                    end
                    st=self.hStyleOk; if ssc<chreq(i).SSchannels.min||ssc>chreq(i).SSchannels.max, self.SSisok=false; st=self.hStyleNotOk; end
                    if isvalid(self.hRequired)
                        self.hRequired.Data(i,7)=ssc;
                        addStyle(self.hRequired,st,'cell',[i,7]);
                    end
                end
            end
        end

        %% UI Callbacks
        function onSelectedChanged(self,~,~)
            newNF=[]; newSS=[];
            for r=1:size(self.hChannels.Data,1)
                if self.hChannels.Data(r,1)=='1', newNF(end+1)=str2double(self.hChannels.Data(r,2)); end
                if self.hChannels.Data(r,6)=='1', newSS(end+1)=str2double(self.hChannels.Data(r,2)); end
            end
            self.selected=newNF; self.SSselected=newSS;
        end
        function onButtonClicked(self,~,~)
            notify(self,'Done'); self.close();
        end
    end
end
