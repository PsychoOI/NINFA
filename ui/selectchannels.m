classdef selectchannels < handle
    %LSL CHANNEL SELECTION  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties(Constant)
        figwidth  = 512;
        figheight = 512;
        padding = 8;    
        buttonheight = 24;
        panelwidth = selectchannels.figwidth-2*selectchannels.padding;
        tablewidth = selectchannels.panelwidth-2*selectchannels.padding;
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties
        hFig           matlab.ui.Figure;
        hRequiredPanel matlab.ui.container.Panel;
        hChannelsPanel matlab.ui.container.Panel;
        hRequired      matlab.ui.control.Table;
        hChannels      matlab.ui.control.Table;
        hButton        matlab.ui.control.Button;
        hStyleOk       matlab.ui.style.Style;
        hStyleNotOk    matlab.ui.style.Style; 
        selected       uint32  = [];
        SSselected          uint32  = [];
        isok           logical = false;
        SSisok         logical = false;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    events
        Done
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = private)
        
        % returns true if channel matches a requirement or no requirements
        function r = isChannelVisible(self, channel)
            lenreqs = size(self.hRequired.Data, 1);
            if lenreqs == 0
                r = true;
                return
            end
            for idx = 1:lenreqs
                if self.hRequired.Data(idx, 4) == channel.type && ...
                   self.hRequired.Data(idx, 5) == channel.unit
                    r = true;
                    return;
                end
            end
            r = false;
        end
        
        % updates ok status
        function updateOK(self)
            global myprotocols;
            global mydevices;
            chreq = myprotocols.selected.fh.requires().channels;
            chlsl = mydevices.selected.lsl.channels;
            self.isok = ~isempty(self.selected);
            for idxreq = 1:length(chreq)
                found = 0;
                for idxlsl = [self.selected]
                    if chreq(idxreq).type == chlsl(idxlsl).type && ...
                       chreq(idxreq).unit == chlsl(idxlsl).unit
                        found = found + 1;
                    end
                end
                min = chreq(idxreq).min;
                max = chreq(idxreq).max;
                if found < min || found > max
                    self.isok = false;
                    if isvalid(self.hRequired)
                        self.hRequired.Data(idxreq, 3) = found;
                        addStyle(self.hRequired, ...
                        self.hStyleNotOk, 'cell', [idxreq 3]);
                        self.SSisok = true;
                    end
                else
                    if isvalid(self.hRequired)
                        self.hRequired.Data(idxreq, 3) = found;
                        addStyle(self.hRequired, ...
                            self.hStyleOk, 'cell', [idxreq 3]);
                    end
                end
            end
            if isvalid(self.hChannelsPanel)
                self.hChannelsPanel.Title = "SELECTED: " + ...
                    length(self.selected);
                  %% SS
                  req = myprotocols.selected.fh.requires();
                  if ~isfield(req, 'SSchannels')
                        req.SSchannels = [];
                  end
                 SSchreq = req.SSchannels;
                 self.SSisok = ~isempty(self.SSselected);
                 for idxreq = 1:length(SSchreq)
                     found = 0;
                     for idxlsl = [self.SSselected]
                         if SSchreq(idxreq).type == chlsl(idxlsl).type && ...
                            SSchreq(idxreq).unit == chlsl(idxlsl).unit
                             found = found + 1;
                         end
                      end
                      min = SSchreq(idxreq).min;
                      max = SSchreq(idxreq).max;
                      if found < min || found > max
                         self.SSisok = false;
                         if isvalid(self.hRequired)
                            self.hRequired.Data(idxreq, 8) = found;
                            addStyle(self.hRequired, ...
                            self.hStyleNotOk, 'cell', [idxreq 8]);
                        end
                      else
                         if isvalid(self.hRequired)
                            self.hRequired.Data(idxreq, 8) = found;
                            addStyle(self.hRequired, ...
                            self.hStyleOk, 'cell', [idxreq 8]);
                        end
                     end
                end
            end
            if isvalid(self.hChannelsPanel)
                 self.hChannelsPanel.Title = "SELECTED: " + ...
                     "NF = " + length(self.selected) + "  SS = " + length(self.SSselected);
            end
        end
        
        % executed when checkbox is changed
        function onSelectedChanged(self, ~, ~)
            newselected = [];
            newSSelected = [];
            for idx = 1:size(self.hChannels.Data, 1)
                row = self.hChannels.Data(idx,:);
                % Checking the first column
                if row(1) == "1"
                    lslidx = str2double(row(2));
                    newselected(end+1) = lslidx;
                end
                % Checking the sisth column
                if row(6) == "1"
                    lslidx = str2double(row(2));
                    newSSelected(end+1) = lslidx;
                end
            end
            self.selected = newselected;
            self.SSselected = newSSelected;
        end

        % executed on OK button
        function onButtonClicked(self, ~, ~)
            notify(self, 'Done');
            self.close();
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods
        function r = get.selected(self)
            r = self.selected;
        end
        
        function set.selected(self,val)
            self.selected = val;
            self.updateOK();
        end
        
        function r = get.SSselected(self)
            r = self.SSselected;
        end
        
        function set.SSselected(self,val)
            self.SSselected = val;
            self.updateOK(); % non faccio il controllo su SS
        end

        function show(self)
            % window already open
            if isvalid(self.hFig)
                self.initRequired();
                self.initSelected();
                figure(self.hFig);
                return;
            end
            
            % create figure
            self.hFig             = uifigure();
            self.hFig.Visible     = 'off';
            self.hFig.Name        = 'SELECT LSL CHANNELS';
            %self.hFig.Color       = [0.0 0.0 0.0];
            self.hFig.MenuBar     = 'none';
            self.hFig.Units       = 'pixels';
            self.hFig.NumberTitle = 'off';
            self.updateOK();
            self.hFig.Position    = [0, 0, ...
                selectchannels.figwidth, ... 
                selectchannels.figheight];

            % create required panel
            self.hRequiredPanel = uipanel(self.hFig);
            self.hRequiredPanel.AutoResizeChildren = 'on';
            self.hRequiredPanel.Title = 'REQUIRED';
            self.hRequiredPanel.Position = [
                selectchannels.padding, ...
                selectchannels.figheight - ...
                  selectchannels.padding - ...
                  selectchannels.panelheightrequired, ...
                selectchannels.panelwidth, ...
                selectchannels.panelheightrequired
            ];
            
            % create channels panel
            self.hChannelsPanel = uipanel(self.hFig);
            self.hChannelsPanel.AutoResizeChildren = 'on';
            self.hChannelsPanel.Title = 'SELECTED: 0';
            self.hChannelsPanel.Position = [
                selectchannels.padding, ...
                selectchannels.buttonheight + 2*selectchannels.padding, ...
                selectchannels.panelwidth, ...
                selectchannels.panelheightchannels
            ];
            % create required table
             self.hRequired = uitable(self.hRequiredPanel);
             self.hRequired.ColumnName = {'MIN_NF'; 'MAX_NF'; 'SEL_NF'; 'TYPE'; 'UNIT';'MIN_SS';'MAX_SS';'SEL_SS'};
             self.hRequired.ColumnWidth = {'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto', 'auto'};
             self.hRequired.ColumnFormat = {'short', 'short', 'short', 'char', 'char' ,'short', 'short' ,'short'};
             self.hRequired.RowName = {};
             self.hRequired.ColumnEditable = [false false false false false false false false];
             self.hRequired.Position = [...
                 selectchannels.padding, ...
                 selectchannels.padding, ...
                 selectchannels.tablewidth, ...
                 selectchannels.tableheightrequired];
             self.hRequired.SelectionType = 'cell';

            % create channels table
            self.hChannels = uitable(self.hChannelsPanel);
            self.hChannels.ColumnName = {'NF'; 'LSL CH'; 'DEV CH'; 'TYPE'; 'UNIT';'SS'};
            self.hChannels.ColumnWidth = {35, 60, 60, 'auto', 100, 35};
            self.hChannels.ColumnFormat = { 
                'logical','short', 'short', 'char', 'char' , 'logical'};
            self.hChannels.RowName = {};
            self.hChannels.ColumnEditable = [true  false false false false true];
            self.hChannels.Position = [...
                selectchannels.padding, ...
                selectchannels.padding, ...
                selectchannels.tablewidth, ...
                selectchannels.tableheightchannels];
            self.hChannels.CellEditCallback = @self.onSelectedChanged;
            self.hChannels.SelectionType = 'cell';

            % create center style
            s = uistyle();
            s.HorizontalAlignment = 'center';
            addStyle(self.hChannels, s, 'column', [2;3]);
            addStyle(self.hRequired, s, 'column', [1;2;3]);
            
            % create ok button
            self.hButton = uibutton(self.hFig, 'push');
            self.hButton.ButtonPushedFcn = @self.onButtonClicked;
            self.hButton.FontWeight = 'bold';
            self.hButton.Text = 'OK';
            self.hButton.Position = [
                selectchannels.padding, ...
                selectchannels.padding, ...
                selectchannels.panelwidth, ...
                selectchannels.buttonheight];
            
            % init ok style
            self.hStyleOk = uistyle();
            self.hStyleOk.BackgroundColor = 'green';
            self.hStyleOk.HorizontalAlignment = 'center';
            
            % init notok style
            self.hStyleNotOk = uistyle();
            self.hStyleNotOk.BackgroundColor = 'red';
            self.hStyleNotOk.HorizontalAlignment = 'center';
            
            % init tables data
            self.initRequired();
            self.initSelected();
            
            % show
            self.hFig.Visible = 'on';
        end
        
        function close(self)
            if isvalid(self.hFig)
                close(self.hFig);
            end
        end
        
         function initRequired(self)
             if isempty(self.hFig) || ~isvalid(self.hFig)
                 return
             end
             global myprotocols;
             req = myprotocols.selected.fh.requires();
             self.hRequired.Data = strings([0,8]);
             for idx = 1:length(req.channels)
                  % Check if SSchannels exist
                  if ~isfield(req, 'SSchannels') || isempty(req.SSchannels)
                        minSSchannels = 0;
                        maxSSchannels = 0;
                  else
                        % Ensure idx does not exceed the length of SSchannels
                        if idx <= length(req.SSchannels)
                            minSSchannels = req.SSchannels(idx).min;
                            maxSSchannels = req.SSchannels(idx).max;
                        else
                            % If idx exceeds, assign default values
                            minSSchannels = 0;
                            maxSSchannels = 0;
                        end
                  end

                 % Fill in the data for the current channel
                 self.hRequired.Data(idx,:) = [
                     req.channels(idx).min, ...
                     req.channels(idx).max, ...
                     0, ...
                     req.channels(idx).type, ...
                     req.channels(idx).unit, ...
                     minSSchannels, ...
                     maxSSchannels, ...
                     0, ...
                 ];
             end
          end

        function initSelected(self)
            if isempty(self.hFig) || ~isvalid(self.hFig)
                return;
            end
            global mylsl;
            global mydevices;
            tblidx = 1;
            lenreqs = size(self.hRequired.Data, 1);
            self.hChannels.Data = strings([0,6]);
            for idx = 1:mylsl.lslchannels
                isselected = ismember(idx, self.selected);
                isselectedstr = convertCharsToStrings(num2str(isselected));
                isSSselected = ismember(idx, self.SSselected);
                isSSselectedstr = convertCharsToStrings(num2str(isSSselected));
                if idx <= size(mydevices.selected.lsl.channels, 1) && ...
                   self.isChannelVisible(mydevices.selected.lsl.channels(idx))
                    self.hChannels.Data(tblidx,:) = [
                        isselectedstr, ...
                        idx, ...
                        mydevices.selected.lsl.channels(idx).devch, ...
                        mydevices.selected.lsl.channels(idx).type, ...
                        mydevices.selected.lsl.channels(idx).unit, ...
                        isSSselectedstr
                    ];
                    tblidx = tblidx + 1;
                elseif lenreqs == 0
                    self.hChannels.Data(tblidx,:) = [
                        isselectedstr, ...
                        idx, ...
                        "", ...
                        "", ...
                        "", ...
                        isSSselectedstr
                    ];
                    tblidx = tblidx + 1;
                end
            end

            self.updateOK();
        end
    end
end
