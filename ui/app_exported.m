classdef app_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        FileMenu                        matlab.ui.container.Menu
        LoadMenu                        matlab.ui.container.Menu
        SaveMenu                        matlab.ui.container.Menu
        LSLSTREAMPanel                  matlab.ui.container.Panel
        GridLayout                      matlab.ui.container.GridLayout
        TYPELabel                       matlab.ui.control.Label
        TYPEEditField                   matlab.ui.control.EditField
        OPENButton                      matlab.ui.control.Button
        CHANNELSLabel_2                 matlab.ui.control.Label
        CHANNELSFOUNDLabel              matlab.ui.control.Label
        SAMPLERATEDescLabel             matlab.ui.control.Label
        SAMPLERATELabel                 matlab.ui.control.Label
        SETTINGSPanel                   matlab.ui.container.Panel
        GridLayout2                     matlab.ui.container.GridLayout
        NEUROFEEDBACKCHANNELSEditFieldLabel  matlab.ui.control.Label
        NEUROFEEDBACKCHANNELSEditField  matlab.ui.control.EditField
        WINDOWSIZESEditFieldLabel       matlab.ui.control.Label
        WINDOWSIZESEditField            matlab.ui.control.NumericEditField
        SESSIONLENGTHSEditFieldLabel    matlab.ui.control.Label
        SESSIONLENGTHSEditField         matlab.ui.control.NumericEditField
        PROTOCOLLabel                   matlab.ui.control.Label
        PROTOCOLDropDown                matlab.ui.control.DropDown
        CHANNELSFORCORRECTIONEditFieldLabel  matlab.ui.control.Label
        CHANNELSFORCORRECTIONEditField  matlab.ui.control.EditField
        CHANNELSButton                  matlab.ui.control.Button
        STARTButton                     matlab.ui.control.Button
        SESSIONINFOPanel                matlab.ui.container.Panel
        GridLayout3                     matlab.ui.container.GridLayout
        SESSIONSTARTEDDescLabel         matlab.ui.control.Label
        SESSIONSTARTEDLabel             matlab.ui.control.Label
        SESSIONENDEDDescLabel           matlab.ui.control.Label
        SESSIONENDEDLabel               matlab.ui.control.Label
        SESSIONLENGTHSDescLabel         matlab.ui.control.Label
        SESSIONLENGTHLabel              matlab.ui.control.Label
        SESSIONSAMPLESLabel             matlab.ui.control.Label
        SESSIONDRIFTLabel               matlab.ui.control.Label
        SESSIONSAMPLESDescLabel         matlab.ui.control.Label
        SESSIONDRIFTDescLabel           matlab.ui.control.Label
        SESSSIONSTATUSDescLabel         matlab.ui.control.Label
        SESSIONSTATUSLabel              matlab.ui.control.Label
        EPOCHSPanel                     matlab.ui.container.Panel
        MARKERTable                     matlab.ui.control.Table
        MARKERAddButton                 matlab.ui.control.Button
        MARKERDelButton                 matlab.ui.control.Button
        COLORButton                     matlab.ui.control.Button
        IDPanel                         matlab.ui.container.Panel
        GridLayout4                     matlab.ui.container.GridLayout
        SUBJECTEditFieldLabel           matlab.ui.control.Label
        SUBJECTEditField                matlab.ui.control.NumericEditField
        RUNEditFieldLabel               matlab.ui.control.Label
        RUNEditField                    matlab.ui.control.NumericEditField
        STUDYEditFieldLabel             matlab.ui.control.Label
        STUDYEditField                  matlab.ui.control.EditField
        PROTOCOLTIMEPanel               matlab.ui.container.Panel
        GridLayout5                     matlab.ui.container.GridLayout
        PROTOCOLMaxLabel                matlab.ui.control.Label
        PROTOCOLMaxDescLabel            matlab.ui.control.Label
        PROTOCOLAvgLabel                matlab.ui.control.Label
        PROTOCOLAvgDescLabel            matlab.ui.control.Label
        DEVICEPanel                     matlab.ui.container.Panel
        GridLayout6                     matlab.ui.container.GridLayout
        MODELDropDownLabel              matlab.ui.control.Label
        DEVICEDropDown                  matlab.ui.control.DropDown
        TYPEDropDownLabel               matlab.ui.control.Label
        TYPEDropDown                    matlab.ui.control.DropDown
    end

    
    properties (Access = private)
        tick uint64 = tic();
    end
    
    properties (Constant)
        idxred   uint32 = 5;
        idxgreen uint32 = 6;
        idxblue  uint32 = 7;
    end
    
    methods (Access = private)
        function onSessionStarted(app, src, ~)
            app.STARTButton.Text = "STOP";
            app.LoadMenu.Enable = false;
            app.SaveMenu.Enable = false;
            app.NEUROFEEDBACKCHANNELSEditField.Enable = false;
            app.CHANNELSFORCORRECTIONEditField.Enable = false;
            app.WINDOWSIZESEditField.Enable = false;
            app.SESSIONLENGTHSEditField.Enable = false;
            app.PROTOCOLDropDown.Enable = false;         
            app.CHANNELSButton.Enable = false;
            app.SUBJECTEditField.Enable = false;
            app.RUNEditField.Enable = false;
            app.STUDYEditField.Enable = false;          
            app.OPENButton.Enable = false;
            app.MARKERTable.Enable = 'off';
            app.MARKERAddButton.Enable = false;
            app.MARKERDelButton.Enable = false;
            app.COLORButton.Enable = false;
            app.SESSIONSTARTEDLabel.Text = string(...
                datetime(src.starttime,'ConvertFrom','datenum'));
            app.SESSIONENDEDLabel.Text = "-";
            app.SESSIONSTATUSLabel.Text = "Started";
        end
        
        function onSessionStopped(app, src, ~)
            app.STARTButton.Text = "START";
            app.LoadMenu.Enable = true;
            app.SaveMenu.Enable = true;
            app.NEUROFEEDBACKCHANNELSEditField.Enable = true;
            app.CHANNELSFORCORRECTIONEditField.Enable = true;
            app.WINDOWSIZESEditField.Enable = true;
            app.SESSIONLENGTHSEditField.Enable = true;
            app.PROTOCOLDropDown.Enable = true;
            app.CHANNELSButton.Enable = true;
            app.SUBJECTEditField.Enable = true;
            app.RUNEditField.Enable = true;
            app.STUDYEditField.Enable = true;
            app.OPENButton.Enable = true;
            app.MARKERTable.Enable = 'on';
            app.MARKERAddButton.Enable = true;
            if size(app.MARKERTable.Data,1) > 0
                app.MARKERDelButton.Enable = true;
                app.COLORButton.Enable = true;
            end
            app.SESSIONENDEDLabel.Text = string(...
                datetime(src.stoptime,'ConvertFrom','datenum'));
            app.SESSIONSTATUSLabel.Text = "Stopped";
            app.updateStatus();
        end

        function onChannelsSelected(app, src, ~)
        end
    end
    
    methods (Access = public)
        function updateColors(app)
            removeStyle(app.MARKERTable);
            numrows = size(app.MARKERTable.Data,1);
            for i = 1:numrows
                r = app.MARKERTable.Data(i, app.idxred);
                g = app.MARKERTable.Data(i, app.idxgreen);
                b = app.MARKERTable.Data(i, app.idxblue);
                s = uistyle();
                s.BackgroundColor = [r g b];
                s.FontColor = [r g b];
                addStyle(app.MARKERTable, s, 'cell', [i app.idxred]);
                addStyle(app.MARKERTable, s, 'cell', [i app.idxgreen]);
                addStyle(app.MARKERTable, s, 'cell', [i app.idxblue]);
            end
        end
        
        function updateStatus(app)
            global mysession
            expected = double(mysession.length) * mysession.srate;
            missing = expected - double(mysession.idx);
            drift = missing / mysession.srate;
            app.SESSIONLENGTHLabel.Text = ...
                sprintf('%.2f', mysession.length) + " s";
            app.SESSIONSAMPLESLabel.Text = ...
                string(mysession.idx) + "/" + ...
                string(length(mysession.data));
            app.SESSIONDRIFTLabel.Text = ...
                sprintf('%.2f', drift) + " s";
            if drift > 1.0 || drift < -1.0
                app.SESSIONDRIFTLabel.BackgroundColor = 'red';
            else
                app.SESSIONDRIFTLabel.BackgroundColor = 'green';
            end          
            app.PROTOCOLMaxLabel.Text = ...
                sprintf('%.2f', mysession.protocolmax) + " s";
            app.PROTOCOLAvgLabel.Text = ...
                sprintf('%.2f', mysession.protocolavg) + " s";           
            if mysession.protocolavg > (0.9*(1.0/mysession.srate))
                app.PROTOCOLAvgLabel.BackgroundColor = 'red';
            else
                app.PROTOCOLAvgLabel.BackgroundColor = 'green';
            end
        end

        function update(app)
            global mylsl
            global mysession
            if mylsl.streaming
                if toc(app.tick) >= 0.5
                    app.SAMPLERATELabel.Text = ...
                        sprintf('%.2f', mylsl.srate) + " Hz / " + ...
                        sprintf('%.2f', mylsl.sratenom) + " Hz";                
                    if mylsl.sratenom > 0.0
                        ratio = mylsl.srate/mylsl.sratenom;
                        if ratio < 0.9 || ratio > 1.1
                            app.SAMPLERATELabel.BackgroundColor = 'red';
                        else
                            app.SAMPLERATELabel.BackgroundColor = 'green';
                        end              
                    end
                    app.tick = tic();
                end
            end
            if mysession.running
                app.updateStatus();
            end
        end
        
        function updateDevices(app)
            global mydevices;
            app.DEVICEDropDown.Items = {};
            type = lower(app.TYPEDropDown.Value);
            for idx = 1:length(mydevices.(type))
                app.DEVICEDropDown.Items(idx) = ...
                    cellstr(mydevices.(type)(idx).name);
            end
        end
        
        function useDevice(app)
            global mydevices;
            global myprotocols;
            type = convertCharsToStrings(app.TYPEDropDown.Value);
            name = convertCharsToStrings(app.DEVICEDropDown.Value);
            if mydevices.select(type, name)
                disp("SELECTED DEVICE: " + mydevices.selected.name + ...
                    "(" + mydevices.selected.type + ")");
                app.TYPEEditField.Value = mydevices.selected.lsl.type;
                myprotocols.reload(mydevices.selected);
                app.PROTOCOLDropDown.Items = {};
                for idx = 1:length(myprotocols.list)
                    app.PROTOCOLDropDown.Items(idx) = ...
                        cellstr(myprotocols.list(idx).name);
                end
                app.useProtocol();
            end
        end
        
        function useProtocol(app)
            global myprotocols;
            global myselectchannels;
            name = convertCharsToStrings(app.PROTOCOLDropDown.Value);
            if myprotocols.select(name)
                disp("SELECTED PROTOCOL: " + myprotocols.selected.name)
                myselectchannels.selected = [];
                myselectchannels.initRequired();
                myselectchannels.initSelected();
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            global mysession;
            global myselectchannels;
            app.UIFigure.Name = "Settings";
            addlistener(mysession, "Started", @app.onSessionStarted);
            addlistener(mysession, "Stopped", @app.onSessionStopped);
            addlistener(myselectchannels, "Done", @app.onChannelsSelected);
            for idx = 1:length(devices.types)
                app.TYPEDropDown.Items(idx) = cellstr(devices.types(idx));
            end
            app.updateDevices();
            app.useDevice();
            app.MARKERTable.SelectionType = 'row';
            app.MARKERTable.ColumnFormat = { 
                'short', 'short', 'short', 'logical', 'short', 'short', 'short' };
        end

        % Button pushed function: OPENButton
        function OPENButtonPushed(app, event)
            global mylsl
            global myselectchannels
            if ~mylsl.streaming
                r = mylsl.open(app.TYPEEditField.Value);
                if r
                    app.tick = tic();
                    app.OPENButton.Text = "CLOSE";
                    app.TYPEDropDown.Enable = false;
                    app.DEVICEDropDown.Enable = false;
                    app.TYPEEditField.Enable = false;
                    app.CHANNELSFOUNDLabel.Text = int2str(mylsl.lslchannels);
                    app.NEUROFEEDBACKCHANNELSEditField.Enable = true;
                    app.CHANNELSFORCORRECTIONEditField.Enable = true;
                    app.WINDOWSIZESEditField.Enable = true;
                    app.SESSIONLENGTHSEditField.Enable = true;
                    app.PROTOCOLDropDown.Enable = true;               
                    app.SUBJECTEditField.Enable = true;
                    app.RUNEditField.Enable = true;
                    app.STUDYEditField.Enable = true;
                    app.CHANNELSButton.Enable = true;
                    app.MARKERTable.Enable = 'on';
                    app.MARKERAddButton.Enable = true;
                    if size(app.MARKERTable.Data,1) > 0
                        app.MARKERDelButton.Enable = true;
                        app.COLORButton.Enable = true;
                    end
                    app.STARTButton.Enable = true;
                else
                    msgbox("No LSL stream with type '" + ...
                        app.TYPEEditField.Value + ...
                        "' found", "Error", "error");
                end
            else
                mylsl.close();
                myselectchannels.close();
                app.OPENButton.Text = "OPEN";
                app.CHANNELSFOUNDLabel.Text = "-";
                app.SAMPLERATELabel.Text = "-";
                app.TYPEDropDown.Enable = true;
                app.DEVICEDropDown.Enable = true;
                app.TYPEEditField.Enable = true;
                app.NEUROFEEDBACKCHANNELSEditField.Enable = false;
                app.CHANNELSFORCORRECTIONEditField.Enable = false;
                app.WINDOWSIZESEditField.Enable = false;
                app.SESSIONLENGTHSEditField.Enable = false;
                app.PROTOCOLDropDown.Enable = false;
                app.SUBJECTEditField.Enable = false;
                app.RUNEditField.Enable = false;
                app.STUDYEditField.Enable = false;
                app.CHANNELSButton.Enable = false;
                app.MARKERTable.Enable = 'off';
                app.MARKERAddButton.Enable = false;
                app.MARKERDelButton.Enable = false;
                app.COLORButton.Enable = false;
                app.STARTButton.Enable = false;
                app.SAMPLERATELabel.BackgroundColor = 'none';
            end
        end

        % Button pushed function: STARTButton
        function STARTButtonPushed(app, event)
            global mylsl;
            global mysession;
            global SizeCHSS;
            if ~mysession.running
                %% Short channel to regress out
                strchannelsSS = split(app.CHANNELSFORCORRECTIONEditField.Value, ',');
                channelsSS = transpose(str2double(strchannelsSS));          
                SizeCHSS = length(channelsSS);                
                %% Long channel to average for NF
                strchannels = split(app.NEUROFEEDBACKCHANNELSEditField.Value, ',');
                channelsLS = transpose(str2double(strchannels));
                
                channels = [channelsLS channelsSS];
                SizeCH = double(((mylsl.lslchannels)-1)/4); % LS + SS 
%                 SizeCHLS = SizeCH - SizeCHSS;
                
                channels = [channels+1 (channels+1)+SizeCH  (channels+1)+2*SizeCH   (channels+1)+3*SizeCH  ];
                
                srate = mylsl.sratenom; % prefer claimed samplerate
                if srate <= 0, srate = mylsl.srate; end % else use measured
                blocksize = app.WINDOWSIZESEditField.Value * srate;
                
                
                mylsl.reset(blocksize, channels);
                mysession.start(...
                    erase(app.PROTOCOLDropDown.Value, ".m"), ...
                    app.SESSIONLENGTHSEditField.Value, ...
                    app.WINDOWSIZESEditField.Value, ...
                    srate, ...
                    channels, ...
                    SizeCHSS, ...
                    app.MARKERTable.Data, ...
                    app.STUDYEditField.Value, ...
                    app.SUBJECTEditField.Value, ...
                    app.RUNEditField.Value);
            else
                mysession.stop();
            end

        end

        % Value changed function: NEUROFEEDBACKCHANNELSEditField
        function NEUROFEEDBACKCHANNELSEditFieldValueChanged(app, event)
            global mylsl;
            newvalue = "";
            values = split(app.NEUROFEEDBACKCHANNELSEditField.Value, ',');
            for k = 1:length(values)
                v = values{k};
                v = strip(v, ' ');
                [x, s] = str2num(v);
                if s && x > 0 && x <= (double(((mylsl.lslchannels)-1)/4)) %(mylsl.lslchannels-1)/4
                    newvalue = newvalue + x + ',';
                end
            end
            newvalue = strip(newvalue, ',');
            if newvalue == ""
                newvalue = "1";
            end
            app.NEUROFEEDBACKCHANNELSEditField.Value = newvalue;
        end

        % Button pushed function: MARKERAddButton
        function MARKERAddButtonPushed(app, event)
            app.MARKERTable.Data = [app.MARKERTable.Data;[0 0 1 1 0 0 0]];
            app.MARKERTable.Selection = size(app.MARKERTable.Data,1);
            app.MARKERDelButton.Enable = true;
            app.COLORButton.Enable = true;
            app.updateColors();
        end

        % Button pushed function: MARKERDelButton
        function MARKERDelButtonPushed(app, event)
            if ~isempty(app.MARKERTable.Selection)                
                numrows = size(app.MARKERTable.Data,1);
                app.MARKERTable.Data(app.MARKERTable.Selection,:) = [];
                if app.MARKERTable.Selection >= numrows
                    if numrows > 1; app.MARKERTable.Selection = numrows-1;
                    else; app.MARKERTable.Selection = [];
                    end
                end
                numrows = size(app.MARKERTable.Data,1);
                if numrows <= 0
                    app.MARKERDelButton.Enable = false;
                    app.COLORButton.Enable = false;
                end
                app.updateColors();
            end
        end

        % Menu selected function: LoadMenu
        function LoadMenuSelected(app, event)
            global mylsl;
            global myselectchannels;
            [file, path] = uigetfile("./settings/*.mat");
            figure(app.UIFigure); % focus back
            filepath = string(path) + string(file);
            if isequal(file,0) || isequal(path,0)
                return;
            end
            settings = load(filepath);           
            if isfield(settings, 'devicetype')
                app.TYPEDropDown.Value = settings.devicetype;
                app.updateDevices();
            end
            if isfield(settings, 'devicename')
                if any(strcmp(app.DEVICEDropDown.Items, settings.devicename))
                    app.DEVICEDropDown.Value = settings.devicename;
                    app.useDevice();
                else
                    msgbox("Device '" + settings.devicename + ...
                    "' was not found on this computer", "Warning", "warn");
                end
            end
            if isfield(settings, 'lsltype')
                app.TYPEEditField.Value = settings.lsltype;
            end
            if isfield(settings, 'channels')
                myselectchannels.selected = settings.channels;              
            end
            %if isfield(settings, 'channelsLS')
            %    app.NEUROFEEDBACKCHANNELSEditField.Value = settings.channelsLS;                
            %end
            %if isfield(settings, 'channelsSS')
            %    app.CHANNELSFORCORRECTIONEditField.Value = settings.channelsSS;
            %end
            if isfield(settings, 'windowsize')
                app.WINDOWSIZESEditField.Value = settings.windowsize;
            end
            if isfield(settings, 'sessionlength')
                app.SESSIONLENGTHSEditField.Value = settings.sessionlength;        
            end
            if isfield(settings, 'protocol')
                if any(strcmp(app.PROTOCOLDropDown.Items, settings.protocol))
                    app.PROTOCOLDropDown.Value = settings.protocol;
                    app.useProtocol();
                else
                    msgbox("Protocol '" + settings.protocol + ...
                    "' was not found on this computer", "Warning", "warn");
                end
            end
            if isfield(settings, 'epochs')
                [numrows, numcols] = size(settings.epochs);
                tblcols = length(app.MARKERTable.ColumnName);
                if numrows > 0 && tblcols > numcols
                    settings.epochs(numrows, tblcols) = 0.0;
                end
                app.MARKERTable.Data = settings.epochs;
                if ~isempty(app.MARKERTable.Data) && mylsl.streaming
                    app.MARKERDelButton.Enable = true;
                    app.COLORButton.Enable = true;
                end
                app.updateColors();
            end
            if isfield(settings, 'study')           
                app.STUDYEditField.Value = settings.study;
            end
        end

        % Menu selected function: SaveMenu
        function SaveMenuSelected(app, event)
            global mydevices;
            global myselectchannels;
            [file, path] = uiputfile("./settings/*.mat");
            figure(app.UIFigure); % focus back
            if isequal(file,0) || isequal(path,0)
                return;
            end
            filepath = string(path) + string(file);
            settings.devicetype = mydevices.selected.type;
            settings.devicename = mydevices.selected.name;
            settings.lsltype = app.TYPEEditField.Value;
            settings.channels = myselectchannels.selected;
            %settings.channelsLS = app.NEUROFEEDBACKCHANNELSEditField.Value;
            %settings.channelsSS = app.CHANNELSFORCORRECTIONEditField.Value;
            settings.windowsize = app.WINDOWSIZESEditField.Value;
            settings.sessionlength = app.SESSIONLENGTHSEditField.Value;
            settings.protocol = app.PROTOCOLDropDown.Value;
            settings.epochs = app.MARKERTable.Data;
            settings.study = app.STUDYEditField.Value;
            save(filepath, '-struct','settings');
        end

        % Cell edit callback: MARKERTable
        function MARKERTableCellEdit(app, event)
            indices = event.Indices;
            newData = event.NewData;
            row = indices(1,1);
            col = indices(1,2);
            if col == 3
                if newData < 1
                    app.MARKERTable.Data(row,col) = 1;
                elseif newData > 99
                    app.MARKERTable.Data(row,col) = 99;
                end
            elseif col == 1 || col == 2
                if newData < 0
                    app.MARKERTable.Data(row,col) = 0;
                end
            end
        end

        % Button pushed function: COLORButton
        function COLORButtonPushed(app, event)
            c = uisetcolor([0 0 0]);
            rows = app.MARKERTable.Selection;         
            for r = rows
                app.MARKERTable.Data(r, app.idxred)   = c(1);
                app.MARKERTable.Data(r, app.idxgreen) = c(2);
                app.MARKERTable.Data(r, app.idxblue)  = c(3);
            end           
            app.updateColors();
        end

        % Value changed function: CHANNELSFORCORRECTIONEditField
        function CHANNELSFORCORRECTIONEditFieldValueChanged(app, event)
%             value = app.CHANNELSFORCORRECTIONEditField.Value;
             global mylsl;
            
            newvalue = "";
            values = split(app.CHANNELSFORCORRECTIONEditField.Value, ',');
            for k = 1:length(values)
                v = values{k};
                v = strip(v, ' ');
                [x, s] = str2num(v);
                if s && x > 0 && x < (mylsl.lslchannels-1)/4
                    newvalue = newvalue + x + ',';
                end
            end
            newvalue = strip(newvalue, ',');
            if newvalue == ""
                newvalue = "1";
            end
            app.CHANNELSFORCORRECTIONEditField.Value = newvalue;
        end

        % Value changed function: DEVICEDropDown
        function DEVICEDropDownValueChanged(app, event)
            app.useDevice();
        end

        % Value changed function: TYPEDropDown
        function TYPEDropDownValueChanged(app, event)
            app.updateDevices();
            app.useDevice();
        end

        % Button pushed function: CHANNELSButton
        function CHANNELSButtonPushed(app, event)
            global myselectchannels;
            myselectchannels.show();
            %myselectchannels.initRequired();
            %myselectchannels.initSelected();
        end

        % Value changed function: PROTOCOLDropDown
        function PROTOCOLDropDownValueChanged(app, event)
            app.useProtocol();
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 657 832];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Resize = 'off';

            % Create FileMenu
            app.FileMenu = uimenu(app.UIFigure);
            app.FileMenu.Text = 'File';

            % Create LoadMenu
            app.LoadMenu = uimenu(app.FileMenu);
            app.LoadMenu.MenuSelectedFcn = createCallbackFcn(app, @LoadMenuSelected, true);
            app.LoadMenu.Text = 'Load';

            % Create SaveMenu
            app.SaveMenu = uimenu(app.FileMenu);
            app.SaveMenu.MenuSelectedFcn = createCallbackFcn(app, @SaveMenuSelected, true);
            app.SaveMenu.Text = 'Save';

            % Create LSLSTREAMPanel
            app.LSLSTREAMPanel = uipanel(app.UIFigure);
            app.LSLSTREAMPanel.AutoResizeChildren = 'off';
            app.LSLSTREAMPanel.Title = 'LSL STREAM';
            app.LSLSTREAMPanel.Position = [22 601 623 118];

            % Create GridLayout
            app.GridLayout = uigridlayout(app.LSLSTREAMPanel);
            app.GridLayout.ColumnWidth = {'1.5x', '2x', '1x'};
            app.GridLayout.RowHeight = {'1x', '1x', '1x'};

            % Create TYPELabel
            app.TYPELabel = uilabel(app.GridLayout);
            app.TYPELabel.HorizontalAlignment = 'center';
            app.TYPELabel.Layout.Row = 1;
            app.TYPELabel.Layout.Column = 1;
            app.TYPELabel.Text = 'TYPE';

            % Create TYPEEditField
            app.TYPEEditField = uieditfield(app.GridLayout, 'text');
            app.TYPEEditField.Layout.Row = 1;
            app.TYPEEditField.Layout.Column = 2;

            % Create OPENButton
            app.OPENButton = uibutton(app.GridLayout, 'push');
            app.OPENButton.ButtonPushedFcn = createCallbackFcn(app, @OPENButtonPushed, true);
            app.OPENButton.Layout.Row = 1;
            app.OPENButton.Layout.Column = 3;
            app.OPENButton.Text = 'OPEN';

            % Create CHANNELSLabel_2
            app.CHANNELSLabel_2 = uilabel(app.GridLayout);
            app.CHANNELSLabel_2.HorizontalAlignment = 'center';
            app.CHANNELSLabel_2.Layout.Row = 2;
            app.CHANNELSLabel_2.Layout.Column = 1;
            app.CHANNELSLabel_2.Text = 'CHANNELS';

            % Create CHANNELSFOUNDLabel
            app.CHANNELSFOUNDLabel = uilabel(app.GridLayout);
            app.CHANNELSFOUNDLabel.Layout.Row = 2;
            app.CHANNELSFOUNDLabel.Layout.Column = 2;
            app.CHANNELSFOUNDLabel.Text = '-';

            % Create SAMPLERATEDescLabel
            app.SAMPLERATEDescLabel = uilabel(app.GridLayout);
            app.SAMPLERATEDescLabel.HorizontalAlignment = 'center';
            app.SAMPLERATEDescLabel.Layout.Row = 3;
            app.SAMPLERATEDescLabel.Layout.Column = 1;
            app.SAMPLERATEDescLabel.Text = 'SAMPLE RATE';

            % Create SAMPLERATELabel
            app.SAMPLERATELabel = uilabel(app.GridLayout);
            app.SAMPLERATELabel.Layout.Row = 3;
            app.SAMPLERATELabel.Layout.Column = 2;
            app.SAMPLERATELabel.Text = '-';

            % Create SETTINGSPanel
            app.SETTINGSPanel = uipanel(app.UIFigure);
            app.SETTINGSPanel.AutoResizeChildren = 'off';
            app.SETTINGSPanel.Title = 'SETTINGS';
            app.SETTINGSPanel.Position = [21 383 375 205];

            % Create GridLayout2
            app.GridLayout2 = uigridlayout(app.SETTINGSPanel);
            app.GridLayout2.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x'};

            % Create NEUROFEEDBACKCHANNELSEditFieldLabel
            app.NEUROFEEDBACKCHANNELSEditFieldLabel = uilabel(app.GridLayout2);
            app.NEUROFEEDBACKCHANNELSEditFieldLabel.HorizontalAlignment = 'center';
            app.NEUROFEEDBACKCHANNELSEditFieldLabel.FontSize = 11;
            app.NEUROFEEDBACKCHANNELSEditFieldLabel.Layout.Row = 2;
            app.NEUROFEEDBACKCHANNELSEditFieldLabel.Layout.Column = 1;
            app.NEUROFEEDBACKCHANNELSEditFieldLabel.Text = 'NEUROFEEDBACK CHANNELS';

            % Create NEUROFEEDBACKCHANNELSEditField
            app.NEUROFEEDBACKCHANNELSEditField = uieditfield(app.GridLayout2, 'text');
            app.NEUROFEEDBACKCHANNELSEditField.ValueChangedFcn = createCallbackFcn(app, @NEUROFEEDBACKCHANNELSEditFieldValueChanged, true);
            app.NEUROFEEDBACKCHANNELSEditField.Enable = 'off';
            app.NEUROFEEDBACKCHANNELSEditField.Tooltip = {'Enter comma separated numeric values larger than zero and less or equal to LSL channels.'};
            app.NEUROFEEDBACKCHANNELSEditField.Layout.Row = 2;
            app.NEUROFEEDBACKCHANNELSEditField.Layout.Column = 2;
            app.NEUROFEEDBACKCHANNELSEditField.Value = '2';

            % Create WINDOWSIZESEditFieldLabel
            app.WINDOWSIZESEditFieldLabel = uilabel(app.GridLayout2);
            app.WINDOWSIZESEditFieldLabel.HorizontalAlignment = 'center';
            app.WINDOWSIZESEditFieldLabel.FontSize = 11;
            app.WINDOWSIZESEditFieldLabel.Layout.Row = 4;
            app.WINDOWSIZESEditFieldLabel.Layout.Column = 1;
            app.WINDOWSIZESEditFieldLabel.Text = 'WINDOW SIZE (S)';

            % Create WINDOWSIZESEditField
            app.WINDOWSIZESEditField = uieditfield(app.GridLayout2, 'numeric');
            app.WINDOWSIZESEditField.Limits = [0 3600];
            app.WINDOWSIZESEditField.HorizontalAlignment = 'left';
            app.WINDOWSIZESEditField.Enable = 'off';
            app.WINDOWSIZESEditField.Layout.Row = 4;
            app.WINDOWSIZESEditField.Layout.Column = 2;
            app.WINDOWSIZESEditField.Value = 2;

            % Create SESSIONLENGTHSEditFieldLabel
            app.SESSIONLENGTHSEditFieldLabel = uilabel(app.GridLayout2);
            app.SESSIONLENGTHSEditFieldLabel.HorizontalAlignment = 'center';
            app.SESSIONLENGTHSEditFieldLabel.FontSize = 11;
            app.SESSIONLENGTHSEditFieldLabel.Layout.Row = 5;
            app.SESSIONLENGTHSEditFieldLabel.Layout.Column = 1;
            app.SESSIONLENGTHSEditFieldLabel.Text = 'SESSION LENGTH (S)';

            % Create SESSIONLENGTHSEditField
            app.SESSIONLENGTHSEditField = uieditfield(app.GridLayout2, 'numeric');
            app.SESSIONLENGTHSEditField.Limits = [0 3600];
            app.SESSIONLENGTHSEditField.HorizontalAlignment = 'left';
            app.SESSIONLENGTHSEditField.Enable = 'off';
            app.SESSIONLENGTHSEditField.Layout.Row = 5;
            app.SESSIONLENGTHSEditField.Layout.Column = 2;
            app.SESSIONLENGTHSEditField.Value = 10;

            % Create PROTOCOLLabel
            app.PROTOCOLLabel = uilabel(app.GridLayout2);
            app.PROTOCOLLabel.HorizontalAlignment = 'center';
            app.PROTOCOLLabel.FontSize = 11;
            app.PROTOCOLLabel.Layout.Row = 1;
            app.PROTOCOLLabel.Layout.Column = 1;
            app.PROTOCOLLabel.Text = 'PROTOCOL';

            % Create PROTOCOLDropDown
            app.PROTOCOLDropDown = uidropdown(app.GridLayout2);
            app.PROTOCOLDropDown.Items = {};
            app.PROTOCOLDropDown.ValueChangedFcn = createCallbackFcn(app, @PROTOCOLDropDownValueChanged, true);
            app.PROTOCOLDropDown.Enable = 'off';
            app.PROTOCOLDropDown.Tooltip = {'Select the Matlab file that should be executed on each window calculating the next feedback. '};
            app.PROTOCOLDropDown.Layout.Row = 1;
            app.PROTOCOLDropDown.Layout.Column = 2;
            app.PROTOCOLDropDown.Value = {};

            % Create CHANNELSFORCORRECTIONEditFieldLabel
            app.CHANNELSFORCORRECTIONEditFieldLabel = uilabel(app.GridLayout2);
            app.CHANNELSFORCORRECTIONEditFieldLabel.HorizontalAlignment = 'center';
            app.CHANNELSFORCORRECTIONEditFieldLabel.FontSize = 11;
            app.CHANNELSFORCORRECTIONEditFieldLabel.Layout.Row = 3;
            app.CHANNELSFORCORRECTIONEditFieldLabel.Layout.Column = 1;
            app.CHANNELSFORCORRECTIONEditFieldLabel.Text = 'CHANNELS FOR CORRECTION';

            % Create CHANNELSFORCORRECTIONEditField
            app.CHANNELSFORCORRECTIONEditField = uieditfield(app.GridLayout2, 'text');
            app.CHANNELSFORCORRECTIONEditField.ValueChangedFcn = createCallbackFcn(app, @CHANNELSFORCORRECTIONEditFieldValueChanged, true);
            app.CHANNELSFORCORRECTIONEditField.Enable = 'off';
            app.CHANNELSFORCORRECTIONEditField.Tooltip = {'Enter comma separated numeric values larger than zero and less or equal to LSL channels.'};
            app.CHANNELSFORCORRECTIONEditField.Layout.Row = 3;
            app.CHANNELSFORCORRECTIONEditField.Layout.Column = 2;
            app.CHANNELSFORCORRECTIONEditField.Value = '3';

            % Create CHANNELSButton
            app.CHANNELSButton = uibutton(app.GridLayout2, 'push');
            app.CHANNELSButton.ButtonPushedFcn = createCallbackFcn(app, @CHANNELSButtonPushed, true);
            app.CHANNELSButton.Layout.Row = 6;
            app.CHANNELSButton.Layout.Column = 2;
            app.CHANNELSButton.Text = 'SELECT';

            % Create STARTButton
            app.STARTButton = uibutton(app.UIFigure, 'push');
            app.STARTButton.ButtonPushedFcn = createCallbackFcn(app, @STARTButtonPushed, true);
            app.STARTButton.Enable = 'off';
            app.STARTButton.Tooltip = {'Start or stop session'};
            app.STARTButton.Position = [18 19 622 22];
            app.STARTButton.Text = 'START';

            % Create SESSIONINFOPanel
            app.SESSIONINFOPanel = uipanel(app.UIFigure);
            app.SESSIONINFOPanel.AutoResizeChildren = 'off';
            app.SESSIONINFOPanel.Title = 'SESSION INFO';
            app.SESSIONINFOPanel.Position = [18 60 473 115];

            % Create GridLayout3
            app.GridLayout3 = uigridlayout(app.SESSIONINFOPanel);
            app.GridLayout3.ColumnWidth = {'0.75x', '1x', '0.75x', '1x'};
            app.GridLayout3.RowHeight = {'1x', '1x', '1x'};

            % Create SESSIONSTARTEDDescLabel
            app.SESSIONSTARTEDDescLabel = uilabel(app.GridLayout3);
            app.SESSIONSTARTEDDescLabel.HorizontalAlignment = 'right';
            app.SESSIONSTARTEDDescLabel.Layout.Row = 2;
            app.SESSIONSTARTEDDescLabel.Layout.Column = 1;
            app.SESSIONSTARTEDDescLabel.Text = 'STARTED:';

            % Create SESSIONSTARTEDLabel
            app.SESSIONSTARTEDLabel = uilabel(app.GridLayout3);
            app.SESSIONSTARTEDLabel.Layout.Row = 2;
            app.SESSIONSTARTEDLabel.Layout.Column = 2;
            app.SESSIONSTARTEDLabel.Text = '-';

            % Create SESSIONENDEDDescLabel
            app.SESSIONENDEDDescLabel = uilabel(app.GridLayout3);
            app.SESSIONENDEDDescLabel.HorizontalAlignment = 'right';
            app.SESSIONENDEDDescLabel.Layout.Row = 3;
            app.SESSIONENDEDDescLabel.Layout.Column = 1;
            app.SESSIONENDEDDescLabel.Text = 'ENDED:';

            % Create SESSIONENDEDLabel
            app.SESSIONENDEDLabel = uilabel(app.GridLayout3);
            app.SESSIONENDEDLabel.Layout.Row = 3;
            app.SESSIONENDEDLabel.Layout.Column = 2;
            app.SESSIONENDEDLabel.Text = '-';

            % Create SESSIONLENGTHSDescLabel
            app.SESSIONLENGTHSDescLabel = uilabel(app.GridLayout3);
            app.SESSIONLENGTHSDescLabel.HorizontalAlignment = 'right';
            app.SESSIONLENGTHSDescLabel.Layout.Row = 1;
            app.SESSIONLENGTHSDescLabel.Layout.Column = 3;
            app.SESSIONLENGTHSDescLabel.Text = 'DURATION:';

            % Create SESSIONLENGTHLabel
            app.SESSIONLENGTHLabel = uilabel(app.GridLayout3);
            app.SESSIONLENGTHLabel.HorizontalAlignment = 'center';
            app.SESSIONLENGTHLabel.Layout.Row = 1;
            app.SESSIONLENGTHLabel.Layout.Column = 4;
            app.SESSIONLENGTHLabel.Text = '-';

            % Create SESSIONSAMPLESLabel
            app.SESSIONSAMPLESLabel = uilabel(app.GridLayout3);
            app.SESSIONSAMPLESLabel.HorizontalAlignment = 'center';
            app.SESSIONSAMPLESLabel.Layout.Row = 2;
            app.SESSIONSAMPLESLabel.Layout.Column = 4;
            app.SESSIONSAMPLESLabel.Text = '-';

            % Create SESSIONDRIFTLabel
            app.SESSIONDRIFTLabel = uilabel(app.GridLayout3);
            app.SESSIONDRIFTLabel.HorizontalAlignment = 'center';
            app.SESSIONDRIFTLabel.Layout.Row = 3;
            app.SESSIONDRIFTLabel.Layout.Column = 4;
            app.SESSIONDRIFTLabel.Text = '-';

            % Create SESSIONSAMPLESDescLabel
            app.SESSIONSAMPLESDescLabel = uilabel(app.GridLayout3);
            app.SESSIONSAMPLESDescLabel.HorizontalAlignment = 'right';
            app.SESSIONSAMPLESDescLabel.Layout.Row = 2;
            app.SESSIONSAMPLESDescLabel.Layout.Column = 3;
            app.SESSIONSAMPLESDescLabel.Text = 'SAMPLES:';

            % Create SESSIONDRIFTDescLabel
            app.SESSIONDRIFTDescLabel = uilabel(app.GridLayout3);
            app.SESSIONDRIFTDescLabel.HorizontalAlignment = 'right';
            app.SESSIONDRIFTDescLabel.Layout.Row = 3;
            app.SESSIONDRIFTDescLabel.Layout.Column = 3;
            app.SESSIONDRIFTDescLabel.Text = 'DRIFT:';

            % Create SESSSIONSTATUSDescLabel
            app.SESSSIONSTATUSDescLabel = uilabel(app.GridLayout3);
            app.SESSSIONSTATUSDescLabel.HorizontalAlignment = 'right';
            app.SESSSIONSTATUSDescLabel.Layout.Row = 1;
            app.SESSSIONSTATUSDescLabel.Layout.Column = 1;
            app.SESSSIONSTATUSDescLabel.Text = 'STATUS:';

            % Create SESSIONSTATUSLabel
            app.SESSIONSTATUSLabel = uilabel(app.GridLayout3);
            app.SESSIONSTATUSLabel.Layout.Row = 1;
            app.SESSIONSTATUSLabel.Layout.Column = 2;
            app.SESSIONSTATUSLabel.Text = 'Stopped';

            % Create EPOCHSPanel
            app.EPOCHSPanel = uipanel(app.UIFigure);
            app.EPOCHSPanel.AutoResizeChildren = 'off';
            app.EPOCHSPanel.Title = 'EPOCHS';
            app.EPOCHSPanel.Position = [20 188 625 185];

            % Create MARKERTable
            app.MARKERTable = uitable(app.EPOCHSPanel);
            app.MARKERTable.ColumnName = {'START (S)'; 'END (S)'; 'MARKER'; 'VISIBLE'; ''; ''; ''};
            app.MARKERTable.ColumnWidth = {'auto', 'auto', 'auto', 64, 1, 1, 1};
            app.MARKERTable.RowName = {};
            app.MARKERTable.ColumnEditable = [true true true true false false false];
            app.MARKERTable.CellEditCallback = createCallbackFcn(app, @MARKERTableCellEdit, true);
            app.MARKERTable.Tooltip = {'Define markers (a value between 1 and 99) for epochs here. An epoch is defined by its start and end time. A trigger will be sent at the beginning of each epoch.'};
            app.MARKERTable.Enable = 'off';
            app.MARKERTable.Position = [11 36 494 120];

            % Create MARKERAddButton
            app.MARKERAddButton = uibutton(app.EPOCHSPanel, 'push');
            app.MARKERAddButton.ButtonPushedFcn = createCallbackFcn(app, @MARKERAddButtonPushed, true);
            app.MARKERAddButton.Enable = 'off';
            app.MARKERAddButton.Tooltip = {'Add an epoch'};
            app.MARKERAddButton.Position = [513 122 100 34];
            app.MARKERAddButton.Text = '+';

            % Create MARKERDelButton
            app.MARKERDelButton = uibutton(app.EPOCHSPanel, 'push');
            app.MARKERDelButton.ButtonPushedFcn = createCallbackFcn(app, @MARKERDelButtonPushed, true);
            app.MARKERDelButton.Enable = 'off';
            app.MARKERDelButton.Tooltip = {'Remove last or selected epochs'};
            app.MARKERDelButton.Position = [513 79 100 34];
            app.MARKERDelButton.Text = '-';

            % Create COLORButton
            app.COLORButton = uibutton(app.EPOCHSPanel, 'push');
            app.COLORButton.ButtonPushedFcn = createCallbackFcn(app, @COLORButtonPushed, true);
            app.COLORButton.Enable = 'off';
            app.COLORButton.Tooltip = {'Select color for selected epochs'};
            app.COLORButton.Position = [513 36 100 34];
            app.COLORButton.Text = 'COLOR';

            % Create IDPanel
            app.IDPanel = uipanel(app.UIFigure);
            app.IDPanel.AutoResizeChildren = 'off';
            app.IDPanel.Title = 'ID';
            app.IDPanel.Position = [401 383 244 205];

            % Create GridLayout4
            app.GridLayout4 = uigridlayout(app.IDPanel);
            app.GridLayout4.ColumnWidth = {'1x', '2x'};
            app.GridLayout4.RowHeight = {'1x', '1x', '1x', '1x'};

            % Create SUBJECTEditFieldLabel
            app.SUBJECTEditFieldLabel = uilabel(app.GridLayout4);
            app.SUBJECTEditFieldLabel.HorizontalAlignment = 'center';
            app.SUBJECTEditFieldLabel.Layout.Row = 2;
            app.SUBJECTEditFieldLabel.Layout.Column = 1;
            app.SUBJECTEditFieldLabel.Text = 'SUBJECT';

            % Create SUBJECTEditField
            app.SUBJECTEditField = uieditfield(app.GridLayout4, 'numeric');
            app.SUBJECTEditField.Limits = [1 10000];
            app.SUBJECTEditField.Enable = 'off';
            app.SUBJECTEditField.Layout.Row = 2;
            app.SUBJECTEditField.Layout.Column = 2;
            app.SUBJECTEditField.Value = 1;

            % Create RUNEditFieldLabel
            app.RUNEditFieldLabel = uilabel(app.GridLayout4);
            app.RUNEditFieldLabel.HorizontalAlignment = 'center';
            app.RUNEditFieldLabel.Layout.Row = 3;
            app.RUNEditFieldLabel.Layout.Column = 1;
            app.RUNEditFieldLabel.Text = 'RUN';

            % Create RUNEditField
            app.RUNEditField = uieditfield(app.GridLayout4, 'numeric');
            app.RUNEditField.Limits = [1 1000];
            app.RUNEditField.Enable = 'off';
            app.RUNEditField.Layout.Row = 3;
            app.RUNEditField.Layout.Column = 2;
            app.RUNEditField.Value = 1;

            % Create STUDYEditFieldLabel
            app.STUDYEditFieldLabel = uilabel(app.GridLayout4);
            app.STUDYEditFieldLabel.HorizontalAlignment = 'center';
            app.STUDYEditFieldLabel.Layout.Row = 1;
            app.STUDYEditFieldLabel.Layout.Column = 1;
            app.STUDYEditFieldLabel.Text = 'STUDY';

            % Create STUDYEditField
            app.STUDYEditField = uieditfield(app.GridLayout4, 'text');
            app.STUDYEditField.Enable = 'off';
            app.STUDYEditField.Tooltip = {''};
            app.STUDYEditField.Layout.Row = 1;
            app.STUDYEditField.Layout.Column = 2;

            % Create PROTOCOLTIMEPanel
            app.PROTOCOLTIMEPanel = uipanel(app.UIFigure);
            app.PROTOCOLTIMEPanel.AutoResizeChildren = 'off';
            app.PROTOCOLTIMEPanel.Title = 'PROTOCOL TIME';
            app.PROTOCOLTIMEPanel.Position = [499 60 146 115];

            % Create GridLayout5
            app.GridLayout5 = uigridlayout(app.PROTOCOLTIMEPanel);
            app.GridLayout5.RowHeight = {'1x', '1x', '1x'};

            % Create PROTOCOLMaxLabel
            app.PROTOCOLMaxLabel = uilabel(app.GridLayout5);
            app.PROTOCOLMaxLabel.HorizontalAlignment = 'center';
            app.PROTOCOLMaxLabel.Layout.Row = 1;
            app.PROTOCOLMaxLabel.Layout.Column = 2;
            app.PROTOCOLMaxLabel.Text = '-';

            % Create PROTOCOLMaxDescLabel
            app.PROTOCOLMaxDescLabel = uilabel(app.GridLayout5);
            app.PROTOCOLMaxDescLabel.HorizontalAlignment = 'center';
            app.PROTOCOLMaxDescLabel.Layout.Row = 1;
            app.PROTOCOLMaxDescLabel.Layout.Column = 1;
            app.PROTOCOLMaxDescLabel.Text = 'MAX:';

            % Create PROTOCOLAvgLabel
            app.PROTOCOLAvgLabel = uilabel(app.GridLayout5);
            app.PROTOCOLAvgLabel.HorizontalAlignment = 'center';
            app.PROTOCOLAvgLabel.Layout.Row = 2;
            app.PROTOCOLAvgLabel.Layout.Column = 2;
            app.PROTOCOLAvgLabel.Text = '-';

            % Create PROTOCOLAvgDescLabel
            app.PROTOCOLAvgDescLabel = uilabel(app.GridLayout5);
            app.PROTOCOLAvgDescLabel.HorizontalAlignment = 'center';
            app.PROTOCOLAvgDescLabel.Layout.Row = 2;
            app.PROTOCOLAvgDescLabel.Layout.Column = 1;
            app.PROTOCOLAvgDescLabel.Text = 'AVG:';

            % Create DEVICEPanel
            app.DEVICEPanel = uipanel(app.UIFigure);
            app.DEVICEPanel.AutoResizeChildren = 'off';
            app.DEVICEPanel.Title = 'DEVICE';
            app.DEVICEPanel.Position = [19 733 626 88];

            % Create GridLayout6
            app.GridLayout6 = uigridlayout(app.DEVICEPanel);
            app.GridLayout6.ColumnWidth = {'1.5x', '2x', '1x'};

            % Create MODELDropDownLabel
            app.MODELDropDownLabel = uilabel(app.GridLayout6);
            app.MODELDropDownLabel.HorizontalAlignment = 'center';
            app.MODELDropDownLabel.Layout.Row = 2;
            app.MODELDropDownLabel.Layout.Column = 1;
            app.MODELDropDownLabel.Text = 'MODEL';

            % Create DEVICEDropDown
            app.DEVICEDropDown = uidropdown(app.GridLayout6);
            app.DEVICEDropDown.Items = {};
            app.DEVICEDropDown.ValueChangedFcn = createCallbackFcn(app, @DEVICEDropDownValueChanged, true);
            app.DEVICEDropDown.Layout.Row = 2;
            app.DEVICEDropDown.Layout.Column = 2;
            app.DEVICEDropDown.Value = {};

            % Create TYPEDropDownLabel
            app.TYPEDropDownLabel = uilabel(app.GridLayout6);
            app.TYPEDropDownLabel.HorizontalAlignment = 'center';
            app.TYPEDropDownLabel.Layout.Row = 1;
            app.TYPEDropDownLabel.Layout.Column = 1;
            app.TYPEDropDownLabel.Text = 'TYPE';

            % Create TYPEDropDown
            app.TYPEDropDown = uidropdown(app.GridLayout6);
            app.TYPEDropDown.Items = {};
            app.TYPEDropDown.ValueChangedFcn = createCallbackFcn(app, @TYPEDropDownValueChanged, true);
            app.TYPEDropDown.Layout.Row = 1;
            app.TYPEDropDown.Layout.Column = 2;
            app.TYPEDropDown.Value = {};

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end