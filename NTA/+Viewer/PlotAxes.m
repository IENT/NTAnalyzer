%% PlotAxes
classdef PlotAxes < Viewer.Viewer
  
  properties
    % Plot Window (parent)
    pw = 0;
    
    % Type of data to be plotted
    type = ''; 
    
    % Long-time measurement buffer
    longTimeCounter = {};
    longTimeMean = {};
    
    % Y-limits buffer to smoothen the adaptive y-limits of the axes
    limBuffer = {};
    NLimBuffer = 32;
    
    % Plot data type: YDATA, ZDATA or CDATA
    plotDataType = '';
  end
  
  
  methods
    %% Constructor
    function obj = PlotAxes(pw, type,pos,varargin)
      obj@Viewer.Viewer(varargin{:})
      
      % Plot window
      obj.pw = pw;
      
      % Signal type to plot
      obj.type = type;
      
      % Create axes
      obj.handles.ax =  axes('Parent',obj.pw.handles.fig, ...
        'Units','normalized', 'Position',pos,...
        'NextPlot','replacechildren');
      
      % String of node numbers
      nodesStringAll = cellfun(@(x)x.tag,obj.pw.nodes,'UniformOutput',false);
      nodesString = strjoin(cellfun(@num2str,nodesStringAll,'UniformOutput',false),', ');
      
      % Determine axis labels
      switch obj.type
        case 'time'
          labelXString = '$t$ [s]';
          labelYString = ['$s_' nodesString '(t)$'];
        case 'magnitude'
          labelXString = '$f$ [Hz]';
          labelYString = ['$|S_' nodesString '(f)|$'];
        case 'phase'
          labelXString = '$f$ [Hz]';
          labelYString = ['$\angle S_' nodesString '(f)$'];
        case {'pdf','jpdf'}
          if length(obj.pw.nodes) == 1
            labelXString = '$x$';
            labelYString = ['$p_' nodesString '(x)$'];
          else
            labelXString = ['$x_' (nodesStringAll{1}) '$'];
            labelYString = ['$x_' (nodesStringAll{2}) '$'];

            obj.pw.data.nodesString = nodesString;
            obj.pw.data.nodesStringAll = nodesStringAll;
          end
        case 'pf'
          labelXString = '$x$';
          labelYString = ['$P_' nodesString '(x)$'];
        case 'ccf'
          labelXString = '$\tau$ [ms]';
          labelYString = ['$\varphi_{' nodesString '}(\tau)$'];
        case {'mcpsd','psd'}
          labelXString = '$f$ [Hz]';
          labelYString = ['$|\phi_{' nodesString '}(f)|$'];
        case 'pcpsd'
          labelXString = '$f$ [Hz]';
          labelYString = ['$\angle \phi_{' nodesString '}(f)$'];
        case 'acf'
          labelXString = '$\tau$ [ms]';
          labelYString = ['$\varphi_' nodesString '(\tau)$'];

        otherwise
          error('Unknown signal type');
      end

      % Update labels
      xlabel(obj.handles.ax,labelXString,'HandleVisibility','off','Interpreter','LaTex');
      ylabel(obj.handles.ax,labelYString,'HandleVisibility','off','Interpreter','LaTex');

      % Update title
      titleString = [obj.tr('node') ' ' nodesString,' : ' obj.tr(['fcn:' obj.type])];
      title(obj.handles.ax, titleString)
      grid(obj.handles.ax, 'on');

      % Calculate x limits
      x = obj.pw.getXDATA(obj.type);
      
      xlims = cell(size(x));
      for n=1:length(x)
        xlims{n} = [x{n}(1), x{n}(end)];
        xlims{n}(1) = min(x{n}(1), 0);
      end

      % Create limits buffer
      obj.limBuffer = zeros(obj.NLimBuffer,2);

      % Create plot handle and set x limits
      if length(x) == 1
        obj.handles.plot = plot(obj.handles.ax, x{1}, zeros(size(x{1})) );
        set(obj.handles.ax,'XLim',xlims{1})
        obj.plotDataType = 'YData';
      else
        plotType = obj.hController.settings.GetValues('Plot','matrixPlotType', 'imagesc');
        switch plotType
          case 'imagesc'
            obj.handles.plot = image(x{end:-1:1}, zeros(length(x{1})),...
              'Parent',obj.handles.ax);
            obj.plotDataType = 'CData';
          case 'surf'
            obj.handles.plot = surf(x{end:-1:1}, zeros(length(x{1})),...
              'Parent',obj.handles.ax);
            obj.plotDataType = 'ZData';
        end

        % Set limits
        set(obj.handles.ax,'XLim',xlims{2},'YLim',xlims{1});
        set(obj.handles.plot, 'HitTest','off');
      end
      
      % Create mouse hover listener
      iptSetPointerBehavior(obj.handles.ax, @(f, cp)set(f, 'Pointer', 'arrow'));
    end
    
    
    %% Update plot
    % Gets called very frequently. Should not be too time-consuming
    function updatePlot(obj,y)
      
      % Update frame buffer for long time measurement
      if strcmp(obj.pw.runMode,'long') && ~strcmp(obj.type,'time')

        % Create the buffer if necessary
        if isempty(obj.longTimeMean) || size(y,1) ~=  size(obj.longTimeMean,1)
          obj.longTimeMean = zeros(size(y));
          obj.longTimeCounter = 0;
        end

        % Update buffer
        obj.longTimeCounter = obj.longTimeCounter+1;
        y = (obj.longTimeMean*(obj.longTimeCounter-1)+y) / obj.longTimeCounter;

        % Save the current one for future use
        obj.longTimeMean = y;

      else
        obj.longTimeCounter = 0;
        obj.longTimeMean = [];
      end


      % Axes limits and plot
      if isvector(y)
        % Calculate new limits
        miny = min(y(:));
        maxy = max(y(:));
        ylims = [miny - 0.1*abs(miny), maxy + 0.1*abs(maxy)];
        if length(obj.limBuffer) >= 1

          % Append new limits
          obj.limBuffer(:,:) = [ylims;obj.limBuffer(1:end-1,:)];

          % Mean over all limits
          ylims = mean(obj.limBuffer,1);
        end

        % Special cases for limits
        ylims(1) = min(ylims(1),0);
        if diff(ylims) < eps
          ylims(1) = ylims(1)-0.1;
          ylims(2) = ylims(2)+0.1;
        end

        % Plot vector
        set(obj.handles.plot,obj.plotDataType,y);
        set(obj.handles.ax,'YLim',ylims);
      else
        % Plot matrix
        set(obj.handles.plot,obj.plotDataType,y);
      end

    end

    %% Destructor
    function delete(obj)
      delete(obj.handles.ax);
    end
  end
end