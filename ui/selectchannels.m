classdef selectchannels < handle
    %FEEDBACK LSL CHANNEL SELECTION

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
    
    properties
        hFig           matlab.ui.Figure;
        hRequiredPanel matlab.ui.container.Panel;
        hChannelsPanel matlab.ui.container.Panel;
        hRequired      matlab.ui.control.Table;
        hChannels      matlab.ui.control.Table;
        hButton        matlab.ui.control.Button;
        hStyleOk;
        hStyleNotOk;   
    end
    
    events
        Selected
    end
    
    methods
        function self = selectchannels()  
        end
        
        function show(self)
            % create figure
            self.hFig             = uifigure();
            self.hFig.Visible     = 'off';
            self.hFig.Name        = 'SELECT LSL CHANNELS';
            %self.hFig.Color       = [0.0 0.0 0.0];
            self.hFig.MenuBar     = 'none';
            self.hFig.Units       = 'pixels';
            self.hFig.NumberTitle = 'off';
            self.hFig.Position    = [0, 0, ...
                channels_lsl.figwidth, ... 
                channels_lsl.figheight];

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
            self.hChannelsPanel.Title = 'SELECTED';
            self.hChannelsPanel.Position = [
                selectchannels.padding, ...
                selectchannels.buttonheight + 2*selectchannels.padding, ...
                selectchannels.panelwidth, ...
                selectchannels.panelheightchannels
            ];

            % create required table
            self.hRequired = uitable(self.hRequiredPanel);
            self.hRequired.ColumnName = {'MIN'; 'MAX'; 'SEL'; 'TYPE'; 'UNIT'};
            self.hRequired.ColumnWidth = {50, 50, 45, 'auto', 100};
            self.hRequired.RowName = {};
            self.hRequired.ColumnEditable = [false false false false false];
            self.hRequired.Position = [...
                selectchannels.padding, ...
                selectchannels.padding, ...
                selectchannels.tablewidth, ...
                selectchannels.tableheightrequired];
            self.hRequired.SelectionType = 'cell';
            self.hRequired.ColumnFormat = { 
                'char', 'char', 'char', 'char', 'char' };
            
            % create channels table
            self.hChannels = uitable(self.hChannelsPanel);
            self.hChannels.ColumnName = {''; 'LSL CH'; 'DEV CH'; 'TYPE'; 'UNIT'};
            self.hChannels.ColumnWidth = {25, 60, 60, 'auto', 100};
            self.hChannels.RowName = {};
            self.hChannels.ColumnEditable = [true false false false false];
            self.hChannels.Position = [...
                selectchannels.padding, ...
                selectchannels.padding, ...
                selectchannels.tablewidth, ...
                selectchannels.tableheightchannels];
            self.hChannels.CellEditCallback = @self.onSelectedChanged;
            self.hChannels.SelectionType = 'cell';
            self.hChannels.ColumnFormat = { 
                'logical', 'char', 'char', 'char', 'char' };

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
            self.updateOK();
            
            % show
            self.hFig.Visible = 'on';
        end
        
        function initRequired(self)
            global myprotocols;
            req = myprotocols.selected.fh.requires();
            self.hRequired.Data = strings([0,5]);
            for idx = 1:length(req.channels)
                self.hRequired.Data(idx,:) = [
                    req.channels(idx).min, ...
                    req.channels(idx).max, ...
                    0, ...
                    req.channels(idx).type, ...
                    req.channels(idx).unit
                ];
            end
        end

        function initSelected(self)
            global mylsl;
            global mydevices;
            tblidx = 1;
            lenreqs = size(self.hRequired.Data, 1);
            self.hChannels.Data = strings([0,5]);
            for idx = 1:mylsl.lslchannels
                if idx <= size(mydevices.selected.lsl.channels, 1) && ...
                   self.isShowChannel(mydevices.selected.lsl.channels(idx))
                    self.hChannels.Data(tblidx,:) = [
                        "false", ...
                        idx, ...
                        mydevices.selected.lsl.channels(idx).devch, ...
                        mydevices.selected.lsl.channels(idx).type, ...
                        mydevices.selected.lsl.channels(idx).unit
                    ];
                    tblidx = tblidx + 1;
                elseif lenreqs == 0
                    self.hChannels.Data(tblidx,:) = [
                        "false", ...
                        idx, ...
                        "", ...
                        "", ...
                        ""
                    ];
                    tblidx = tblidx + 1;
                end
            end
        end
        
        function r = isShowChannel(self, channel)
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
        
        function updateOK(self)
            isok = true;
            for idx = 1:size(self.hRequired.Data, 1)
                min = self.hRequired.Data(idx, 1);
                max = self.hRequired.Data(idx, 2);
                sel = self.hRequired.Data(idx, 3);
                if sel < min || sel > max
                   isok = false;
                   addStyle(self.hRequired, self.hStyleNotOk, 'cell', [idx 3]);
                else
                   addStyle(self.hRequired, self.hStyleOk, 'cell', [idx 3]);
                end
            end
            self.hButton.Enable = isok;
        end
        
        function onSelectedChanged(self, ~, ~)
            for idxreq = 1:size(self.hRequired.Data, 1)
                typereq = self.hRequired.Data(idxreq, 4);
                slctreq = 0;
                for idxlsl = 1:size(self.hChannels.Data, 1)
                    selected = self.hChannels.Data(idxlsl,1);
                    typelsl = self.hChannels.Data(idxlsl,4);
                    if selected == "1" && typereq == typelsl
                        slctreq = slctreq + 1;
                    end
                end
                self.hRequired.Data(idxreq, 3) = slctreq;
            end
            self.updateOK();
        end
        
        function onButtonClicked(self, ~, ~)
            disp("OK");
            notify(self, 'Selected');
            close(self.hFig);
        end
    end
end


