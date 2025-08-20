classdef feedback < handle
    % FEEDBACK Visual thermometer driven by a normalized [0..1] value.

    % Public API for feedback visualization
    %   - setFeedback(v) : updates bar heights only (no visibility changes).
    %   - showBar()      : shows the full thermometer (frame + bars).
    %   - hideBar()      : hides the thermometer completely.
    %   - setBackground(c): sets figure background color.
    %   - centerBar()     : keeps the thermometer centered when window changes.
    % Modes:
    %   - hidden: nothing visible
    %   - frameOnly : show axes + grid lines, hide both bars (for transfer)
    %   - live  : axes + lines + bars visible; bars update with value

    properties(Constant)
        figwidth  = 512; % window width (px)
        figheight = 1024; % window height (px)
        barwidth  = 256; % drawing area (axes) width (px)
        barheight = 768; % drawing area (axes) height (px)
    end
    
    properties
        hFig     matlab.ui.Figure; % figure window
        hBarRed  matlab.graphics.chart.primitive.Bar; % red bar object
        hBarBlue matlab.graphics.chart.primitive.Bar; % blue bar object
        hAxes    matlab.graphics.axis.Axes; % axes hosting bars/lines
        hLines   cell = cell(9,1); % 9 horizontal reference lines
    end

    properties (Access = private)
        mode     (1,1) string = "hidden";   % "hidden" | "frameOnly" | "live"
        lastValue (1,1) double = 0.5;        % Cached normalized value
    end
    
    methods
        function self = feedback()
            % Constructor: build the window & plot objects, then show the window
            % with content initially hidden.

            % Create and configure the figure (kept hidden while building)
            self.hFig             = figure();
            self.hFig.Visible     = 'off';
            self.hFig.Name        = 'Feedback';
            self.hFig.Color       = [0.0 0.0 0.0]; % black background
            self.hFig.MenuBar     = 'none';
            self.hFig.Units       = 'pixels';
            self.hFig.NumberTitle = 'off';
            self.hFig.Position    = [0, 0, feedback.figwidth, feedback.figheight];

            %% Create bars (both attached to this figure's current axes)
            % Create the red bar
            self.hBarRed = bar(self.hFig);  % first bar call creates axes
            self.hBarRed.FaceColor = [0.8500 0.3250 0.0980]; % reddish
            hold on;

            % Create the blue bar
            self.hBarBlue = bar(self.hFig);
            self.hBarBlue.FaceColor = [0 0.4470 0.7410]; % bluish
            hold off;

            % Cache axes handle (created by the first bar)
            self.hAxes = self.hFig.CurrentAxes;
            
            % Axes styling: numeric range and hide all ticks/labels
            axis(self.hAxes, 'tight');
            self.hAxes.YLim = [0 1];
            self.hAxes.YTickLabel = [];
            self.hAxes.YTick = [];  
            self.hAxes.XTickLabel = [];
            self.hAxes.XTick = [];
            self.hAxes.Units = 'pixels'; % Positioning by pixels

            % Add faint horizontal reference lines at 0.1 steps
            for idx = 1:length(self.hLines)
                self.hLines{idx} = yline(self.hAxes, idx*0.1);
            end

            % Layout, initial state
            movegui(self.hFig,'center');
            self.centerBar();


            % - setFeedback(0.5)   : cache + draw bars
            % - hideBar()          : everything hidden
            % - figure visible on
            self.setFeedback(0.5);
            self.hideBar();
            self.hFig.Visible = 'on';
        end
        %-----------------------
        % Layout / appearance
        %-----------------------
        function centerBar(self)
            % CENTERBAR: Center the axes area within the figure window.
            % Uses pixel geometry for precise placement.
            if ~isvalid(self.hAxes) || ~isvalid(self.hFig), return; end
            
            xpos = (self.hFig.Position(3)-feedback.barwidth)*0.5;
            ypos = (self.hFig.Position(4)-feedback.barheight)*0.5;
            self.hAxes.Position = [xpos, ypos, feedback.barwidth, feedback.barheight];
        end

        function setBackground(self, color)
            % SETBACKGROUND: Set the figure (window) background color.
            if isvalid(self.hFig)
                self.hFig.Color = color;
            end
        end

        %-----------------------
        % Visibility control
        %-----------------------
        function hideBar(self)
           % hide everything
            self.setMode("hidden");
        end
        
        function showBar(self)
            % show full thermometer with live bars
            self.setMode("live");
        end

        function setMode(self, newMode, varargin)
            % Centralized mode setter
            m = string(newMode);
            if m == "live" && ~isempty(varargin)
                self.lastValue = double(varargin{1});
            end
            self.mode = m;
            self.applyMode_();
            % If we are in live mode, (re)draw bars to reflect lastValue
            if self.mode == "live"
                self.renderValue_(self.lastValue);
            end
        end

        %-----------------------
        % Value updates
        %-----------------------
        function setFeedback(self, v)
            % Backward-compatible: update bar heights only.
            % No visibility changes, no clamping here.
            self.lastValue = double(v);
            self.renderValue_(self.lastValue);   % draws even if currently hidden
        end
    end

    methods (Access=private)
         function applyMode_(self)
            % Turn graphics on/off according to the current mode.
            switch self.mode
                case "hidden"
                    self.setVis_(self.hAxes,    'off');
                    self.setVis_(self.hBarRed,  'off');
                    self.setVis_(self.hBarBlue, 'off');
                    self.setLinesVis_('off');

                case "frameOnly"
                    % Axes + grid visible, bars hidden
                    self.setVis_(self.hAxes,    'on');
                    self.setVis_(self.hBarRed,  'off');
                    self.setVis_(self.hBarBlue, 'off');
                    self.setLinesVis_('on');

                case "live"
                    % Everything visible (bars + frame)
                    self.setVis_(self.hAxes,    'on');
                    self.setVis_(self.hBarRed,  'on');
                    self.setVis_(self.hBarBlue, 'on');
                    self.setLinesVis_('on');

                otherwise
                    % Fallback to hidden if unknown
                    self.setVis_(self.hAxes,    'off');
                    self.setVis_(self.hBarRed,  'off');
                    self.setVis_(self.hBarBlue, 'off');
                    self.setLinesVis_('off');
            end
         end

         function setLinesVis_(self, state)
            for i = 1:numel(self.hLines)
                if isvalid(self.hLines{i}), self.hLines{i}.Visible = state; end
            end
         end

         function setVis_(~, h, state)
            if isvalid(h), h.Visible = state; end
         end

         function renderValue_(self, v)
            % Draw bars for the given (already-normalized) value v.
            % Same visual rule as your original class:
            %   - If v > 0.5: red bar = v, blue bar = 0.5 (baseline)
            %   - Else:       red bar = 0, blue bar = v
            if ~isvalid(self.hBarRed) || ~isvalid(self.hBarBlue), return; end

            if v > 0.5
                self.hBarRed.YData  = v;
                self.hBarBlue.YData = 0.5;
            else
                self.hBarRed.YData  = 0.0;
                self.hBarBlue.YData = v;
            end
        end
    end
end

