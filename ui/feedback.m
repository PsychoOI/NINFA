classdef feedback < handle
    %FEEDBACK Visualization of feedback using a blue/red bar

    properties(Constant)
        figwidth  = 512;
        figheight = 1024;
        barwidth  = 256;
        barheight = 768;
    end
    
    properties
        hFig     matlab.ui.Figure;
        hBarRed  matlab.graphics.chart.primitive.Bar;
        hBarBlue matlab.graphics.chart.primitive.Bar;
        hAxes    matlab.graphics.axis.Axes;
        hLines   cell = cell(9,1);
    end
    
    methods
        function self = feedback()

            % create figure
            self.hFig             = figure();
            self.hFig.Visible     = 'off';
            self.hFig.Name        = 'Feedback';
            self.hFig.Color       = [0.0 0.0 0.0];
            self.hFig.MenuBar     = 'none';
            self.hFig.Units       = 'pixels';
            self.hFig.NumberTitle = 'off';
            self.hFig.Position    = [0, 0, ...
                feedback.figwidth, ... 
                feedback.figheight];

            % create axes in the figure
            self.hAxes = axes(self.hFig); % Create axes as a child of the figure
            
            % create red bar
            self.hBarRed = bar(self.hAxes, 0);
            self.hBarRed.FaceColor = [0.8500 0.3250 0.0980];
            hold on;

            % create blue bar
            self.hBarBlue = bar(self.hAxes, 0);
            self.hBarBlue.FaceColor = [0 0.4470 0.7410];
            hold off;

            % get axes
            self.hAxes = self.hFig.CurrentAxes;
            
            % setup axes
            axis(self.hAxes, 'tight');
            self.hAxes.YLim = [0 1];
            self.hAxes.YTickLabel = [];
            self.hAxes.YTick = [];  
            self.hAxes.XTickLabel = [];
            self.hAxes.XTick = [];
            self.hAxes.Units = 'pixels';

            % draw horizontal lines
            for idx = 1:length(self.hLines)
                self.hLines{idx} = yline(self.hAxes, idx*0.1);
            end

            % center on screen
            movegui(self.hFig,'center');

            % center bar on figure and show
            self.setFeedback(0.5);
            self.centerBar();
            self.hideBar();
            self.hFig.Visible = 'on';
        end
        
        function centerBar(self)
            if ~isvalid(self.hAxes) || ~isvalid(self.hFig)
                return;
            end
            
            xpos = (self.hFig.Position(3)-feedback.barwidth)*0.5;
            ypos = (self.hFig.Position(4)-feedback.barheight)*0.5;

            self.hAxes.Position = [xpos, ypos, ...
                feedback.barwidth, feedback.barheight];
        end
        
        function hideBar(self)
            if isvalid(self.hBarRed);  self.hBarRed.Visible  = 'off'; end
            if isvalid(self.hBarBlue); self.hBarBlue.Visible = 'off'; end
            if isvalid(self.hAxes);    self.hAxes.Visible    = 'off'; end
            for i = 1:length(self.hLines)
                if isvalid(self.hLines{i})
                    self.hLines{i}.Visible = 'off';
                end
            end
        end
        
        function showBar(self)
            if isvalid(self.hBarRed);  self.hBarRed.Visible  = 'on'; end
            if isvalid(self.hBarBlue); self.hBarBlue.Visible = 'on'; end
            if isvalid(self.hAxes);    self.hAxes.Visible    = 'on'; end
            for i = 1:length(self.hLines)
                if isvalid(self.hLines{i})
                    self.hLines{i}.Visible = 'on';
                end
            end
        end
        
        function setBackground(self, color)
            if isvalid(self.hFig)
                self.hFig.Color = color;
            end
        end
        
        function setFeedback(self, v)
            if ~isvalid(self.hBarRed) || ~isvalid(self.hBarBlue)
                return;
            end
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