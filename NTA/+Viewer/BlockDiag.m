%% BlockDiag
% Creates the block diagram

classdef BlockDiag < Viewer.Viewer
  properties
    bdHandles %handles for all block diagram blocks
  end
  
  methods
    %% Constructor
    function [obj] = BlockDiag(ctrl,lang,fig)
      
      if nargin < 3,
        ctrl = [];
        lang = '';
      end
      
      % Parent constructor
      obj = obj@Viewer.Viewer(ctrl,lang);
      if nargin < 3,
        fig = figure('Units','normalized','OuterPosition',[0,0.025,1,0.4]);
        obj.tr = @(x)x;
      end
      obj.handles.fig = fig;
      
      set(obj.handles.fig,'Units','Pixel');
      figPos = get(obj.handles.fig,'Position');
      set(obj.handles.fig,'Units','normalized');
      
      Lx = 26;
      Ly = 10;
      
      % Create axes
      wy = figPos(4);
      wx = round(wy*Lx/Ly);
      axPos = [0,0,wx/figPos(3),1];
      
      obj.handles.ax = axes('Parent',obj.handles.fig,'XTick',[],'YTick',[],...
        'Units','normalized','Position',axPos,...
        'XLim', [0,Lx], 'YLim',[0,Ly],'DataAspectRatio',[1 1 1],'XColor','none','YColor','none');
      
      
      % Grid
      obj.plotGrid(Lx, Ly);
      
      % Block diagram handles
      obj.bdHandles = struct();      
      
      % Input jacks
      obj.bdHandles.sources{1} = Viewer.BD.Jack(0.33,0.33,1, 8);
      obj.plot(obj.bdHandles.sources{1});
      
      obj.bdHandles.sources{2} = Viewer.BD.Jack(0.33,0.33, ...
        obj.bdHandles.sources{1}.cx, obj.bdHandles.sources{1}.cy-2);
      obj.plot(obj.bdHandles.sources{2});
      
      
      % Sources
      obj.bdHandles.sources{3} = Viewer.BD.Block([obj.tr('source') ' 1'],...
        2,1,obj.bdHandles.sources{1}.cx+3.5, obj.bdHandles.sources{2}.cy-2,...
        @obj.clickSourceHandler,'Osc1',obj.tr('none'));
      obj.plot(obj.bdHandles.sources{3});
      
      obj.bdHandles.sources{4} = Viewer.BD.Block([obj.tr('source') ' 2'],...
        2,1,obj.bdHandles.sources{3}.cx, obj.bdHandles.sources{3}.cy-2,...
        @obj.clickSourceHandler,'Osc2',obj.tr('none'));
      obj.plot(obj.bdHandles.sources{4});
      
      
      % Nodes
      cx = obj.bdHandles.sources{1}.cx + 6;
      
      for n=1:4
        nodeString = num2str(n);
        obj.bdHandles.nodes{n} = Viewer.BD.Node(nodeString, 0.33,0.33,...
          cx,obj.bdHandles.sources{n}.cy, @obj.clickNodeHandler,nodeString);
        obj.plot(obj.bdHandles.nodes{n});
      end
      
      cx = obj.bdHandles.nodes{1}.cx + 16;
      for n=5:8
        nodeString = num2str(n);
        obj.bdHandles.nodes{n} = Viewer.BD.Node(nodeString, 0.33,0.33,...
          cx,obj.bdHandles.nodes{n-4}.cy,@obj.clickNodeHandler,nodeString);
        obj.plot(obj.bdHandles.nodes{n});
      end
            
      % Output jacks
      obj.bdHandles.sinks{1} = Viewer.BD.Jack(0.33,0.33,...
        obj.bdHandles.nodes{7}.cx+2,obj.bdHandles.nodes{7}.cy);
      obj.plot(obj.bdHandles.sinks{1});
      
      obj.bdHandles.sinks{2} = Viewer.BD.Jack(0.33,0.33, ...
        obj.bdHandles.sinks{1}.cx, obj.bdHandles.nodes{8}.cy);
      obj.plot(obj.bdHandles.sinks{2});
      
      
      % Connections
      for n=1:4
        obj.connectLR(obj.bdHandles.sources{n},obj.bdHandles.nodes{n});
      end
      obj.connectLR(obj.bdHandles.nodes{7},obj.bdHandles.sinks{1});
      obj.connectLR(obj.bdHandles.nodes{8},obj.bdHandles.sinks{2});
      
      
      % Plot experiment specific block diagram
      obj.plotExperimentSpecific();
      
      
      % Bounding box
      rectangle('Position',[obj.bdHandles.sources{1}.cx+1,obj.bdHandles.nodes{4}.cy-1,22,8],...
        'Curvature',[0.05 0.1],'Parent',obj.handles.ax);
      
      % Create pointer manager for mouse hover events
      iptPointerManager(obj.handles.fig);
    end
    
    
    %% Experiment specific blocks
    function obj = plotExperimentSpecific(obj,experiment,blackboxnumber)
      
      if nargin<2, experiment = '4.1'; end
      if nargin<3, blackboxnumber = 0;  end
      
      % Clean up all handles that are not used by default
      obj.cleanUp();
      
      % Group for experiment specific blocks (esb)
      if(isfield(obj.handles,'esb_hg')), delete(obj.handles.esb_hg); end
      obj.handles.esb_hg = hggroup('Parent',obj.handles.ax);
      
      
      switch experiment
        
        case '2' % one delay element
          
          % Filters
          obj.bdHandles.filters{1} = Viewer.BD.Block('10 Ta',...
            1,1,0,obj.bdHandles.nodes{2}.cy);
          obj.bdHandles.filters{1}.west(obj.bdHandles.nodes{2}.cx+7);
          plot(obj.bdHandles.filters{1},obj.handles.esb_hg);
          
          % Connection points
          obj.bdHandles.points{1} = Viewer.BD.Point(0.1,0.1,...
              obj.bdHandles.nodes{1}.cx+4, obj.bdHandles.nodes{1}.cy);
          plot(obj.bdHandles.points{1},obj.handles.esb_hg);
          
          obj.bdHandles.points{2} = Viewer.BD.Point(0.1,0.1,...
              obj.bdHandles.points{1}.cx, obj.bdHandles.filters{1}.cy);
            
          % Connections          
          obj.connectLR(obj.bdHandles.nodes{1},obj.bdHandles.nodes{5},obj.handles.esb_hg);
          
          obj.line2P(obj.bdHandles.points{1}.cx,obj.bdHandles.points{1}.cy,...
            obj.bdHandles.points{2}.cx,obj.bdHandles.points{2}.cy,obj.handles.esb_hg);
          obj.arrow2P(obj.bdHandles.points{2}.cx,obj.bdHandles.points{2}.cy,...
            obj.bdHandles.filters{1}.west,obj.bdHandles.filters{1}.cy,obj.handles.esb_hg);
          obj.connectLR(obj.bdHandles.filters{1},obj.bdHandles.nodes{6},obj.handles.esb_hg);
          
          obj.connectLR(obj.bdHandles.nodes{3},obj.bdHandles.nodes{7},obj.handles.esb_hg);
          obj.connectLR(obj.bdHandles.nodes{4},obj.bdHandles.nodes{8},obj.handles.esb_hg);
          
          
        case '3' % 4 delay elements
          
          xPos = obj.bdHandles.nodes{1}.cx + [4 , 2.5];
          xInc = 2;
          filterNums = 9:12;
          for n=1:length(filterNums)
            fn = filterNums(n);
            
            % Symbol
            obj.bdHandles.symbols{n} = Viewer.BD.Symbol('+',...
              0.5,0.5, xPos(1),obj.bdHandles.nodes{1}.cy);
            plot(obj.bdHandles.symbols{n},obj.handles.esb_hg);
            
            % Node
            obj.bdHandles.nodes{fn} = Viewer.BD.Node(num2str(fn),...
              0.33,0.33, xPos(1)+1,obj.bdHandles.nodes{1}.cy,...
              @obj.clickNodeHandler,num2str(fn));
            plot(obj.bdHandles.nodes{fn},obj.handles.esb_hg);
            
            % Filter
            obj.bdHandles.filters{n} = Viewer.BD.Block('20 Ta',...
              1,1,0,obj.bdHandles.nodes{2}.cy);
            obj.bdHandles.filters{n}.west(xPos(2));
            plot(obj.bdHandles.filters{n},obj.handles.esb_hg);
            
            % Connection points
            obj.bdHandles.points{n} = Viewer.BD.Point(0.1,0.1,...
              obj.bdHandles.symbols{n}.cx, obj.bdHandles.filters{n}.cy);
            if(n~=length(filterNums))
              plot(obj.bdHandles.points{n},obj.handles.esb_hg);
            end
            
            % Increment position
            xPos = xPos + xInc;
          end
          
          % Multiplicator
          obj.bdHandles.symbols{5} = Viewer.BD.Symbol('k',...
            0.75,0.75,obj.bdHandles.nodes{12}.cx+1.5,obj.bdHandles.nodes{12}.cy);
          plot(obj.bdHandles.symbols{5},obj.handles.esb_hg);
          
          % Connections
          % Points for connections
          obj.bdHandles.points{5} = Viewer.BD.Point(0.1,0.1,...
            obj.bdHandles.nodes{3}.cx+1, obj.bdHandles.nodes{3}.cy);
          
          obj.bdHandles.points{6} = Viewer.BD.Point(0.1,0.1,...
            obj.bdHandles.points{5}.cx, obj.bdHandles.nodes{2}.cy);
          plot(obj.bdHandles.points{6},obj.handles.esb_hg);
          
          obj.bdHandles.points{7} = Viewer.BD.Point(0.1,0.1,...
            obj.bdHandles.points{5}.cx, obj.bdHandles.nodes{1}.cy);
          
          obj.line2P(obj.bdHandles.nodes{3}.east,obj.bdHandles.nodes{3}.cy,...
            obj.bdHandles.points{5}.cx,obj.bdHandles.points{5}.cy,obj.handles.esb_hg);
          
          obj.line2P(obj.bdHandles.points{5}.cx,obj.bdHandles.points{5}.cy,...
            obj.bdHandles.points{7}.cx,obj.bdHandles.points{7}.cy,obj.handles.esb_hg);
          
          obj.arrow2P(obj.bdHandles.points{7}.cx,obj.bdHandles.points{7}.cy,...
            obj.bdHandles.symbols{1}.west,obj.bdHandles.symbols{1}.cy,obj.handles.esb_hg);
          obj.connectLR(obj.bdHandles.points{6}, obj.bdHandles.filters{1},obj.handles.esb_hg);
          
          
          for n=1:length(filterNums)
            fn = filterNums(n);
            obj.connectLR(obj.bdHandles.symbols{n}, obj.bdHandles.nodes{fn},obj.handles.esb_hg);
            obj.connectLR(obj.bdHandles.nodes{fn}, obj.bdHandles.symbols{n+1},obj.handles.esb_hg);
            
            obj.arrow2P(obj.bdHandles.points{n}.cx,obj.bdHandles.points{n}.cy,...
              obj.bdHandles.symbols{n}.cx,obj.bdHandles.symbols{n}.south,obj.handles.esb_hg);
            
            if(n~=length(filterNums))
              obj.connectLR(obj.bdHandles.filters{n}, obj.bdHandles.filters{n+1},obj.handles.esb_hg);
            else
              obj.line2P(obj.bdHandles.filters{n}.east,obj.bdHandles.filters{n}.cy,...
                obj.bdHandles.points{n}.cx,obj.bdHandles.points{n}.cy,obj.handles.esb_hg);
            end
          end
          
          obj.connectLR(obj.bdHandles.symbols{5}, obj.bdHandles.nodes{5},obj.handles.esb_hg);
          
          
        case '4' % Blackbox
          % NOTE: For debugging purposes, the blackbox inputs are nodes 3
          % and 4 for now
          inNodes = [3 4]; % inNodes = [1 2];
          outNodes = [7 8]; % outNodes = [5 6];
          obj.bdHandles.filters{1} = Viewer.BD.Block('Blackbox',...
            4,2.5,obj.bdHandles.nodes{inNodes(1)}.cx+7,0, @obj.clickBlackBoxHandler,'blackbox');
          obj.bdHandles.filters{1}.north(obj.bdHandles.nodes{inNodes(1)}.cy+0.25);
          plot(obj.bdHandles.filters{1},obj.handles.esb_hg);
          
          % Connections
          obj.arrow2P(obj.bdHandles.nodes{inNodes(1)}.east, obj.bdHandles.nodes{inNodes(1)}.cy,...
            obj.bdHandles.filters{1}.west,obj.bdHandles.nodes{inNodes(1)}.cy,obj.handles.esb_hg);
          obj.arrow2P(obj.bdHandles.filters{1}.east,obj.bdHandles.nodes{inNodes(1)}.cy,...
            obj.bdHandles.nodes{outNodes(1)}.west, obj.bdHandles.nodes{outNodes(1)}.cy,obj.handles.esb_hg);
          
          % Plot extra connections (if necessary)
          tmp = floor(blackboxnumber/100);
          switch(tmp)
            case 2
              obj.arrow2P(obj.bdHandles.filters{1}.east,obj.bdHandles.nodes{inNodes(2)}.cy,...
                obj.bdHandles.nodes{outNodes(2)}.west, obj.bdHandles.nodes{outNodes(2)}.cy,obj.handles.esb_hg);
            case 3
              obj.arrow2P(obj.bdHandles.nodes{inNodes(2)}.east, obj.bdHandles.nodes{inNodes(2)}.cy,...
                obj.bdHandles.filters{1}.west,obj.bdHandles.nodes{inNodes(2)}.cy,obj.handles.esb_hg);
          end
          obj.bdHandles.filters{1}.plotDescription(num2str(blackboxnumber));
          
        case 'LP' % Lowpass
          % Filters
          obj.bdHandles.filters{1} = Viewer.BD.Block(obj.tr('lp'),...
            1,1,0,obj.bdHandles.nodes{3}.cy);
          obj.bdHandles.filters{1}.west(obj.bdHandles.nodes{3}.cx+6);
          plot(obj.bdHandles.filters{1},obj.handles.esb_hg);
          
          % Connections          
          obj.connectLR(obj.bdHandles.nodes{3},obj.bdHandles.filters{1},obj.handles.esb_hg);
          obj.connectLR(obj.bdHandles.filters{1},obj.bdHandles.nodes{7},obj.handles.esb_hg);
          
          obj.connectLR(obj.bdHandles.nodes{1},obj.bdHandles.nodes{5},obj.handles.esb_hg);
          obj.connectLR(obj.bdHandles.nodes{2},obj.bdHandles.nodes{6},obj.handles.esb_hg);
          obj.connectLR(obj.bdHandles.nodes{4},obj.bdHandles.nodes{8},obj.handles.esb_hg);
          
          
        case 'debug'
          % Filters
          obj.bdHandles.filters{1} = Viewer.BD.Block('H1(z)',...
            1,1,0,obj.bdHandles.nodes{3}.cy);
          obj.bdHandles.filters{1}.west(obj.bdHandles.nodes{3}.cx+7);
          plot(obj.bdHandles.filters{1},obj.handles.esb_hg);
          
          obj.bdHandles.filters{2} = Viewer.BD.Block('H2(z)',...
            1,1,obj.bdHandles.filters{1}.cx,obj.bdHandles.nodes{4}.cy);
          plot(obj.bdHandles.filters{2},obj.handles.esb_hg);
          
          % Connections
          obj.connectLR(obj.bdHandles.nodes{1},obj.bdHandles.nodes{5},obj.handles.esb_hg);
          obj.connectLR(obj.bdHandles.nodes{2},obj.bdHandles.nodes{6},obj.handles.esb_hg);
          
          obj.connectLR(obj.bdHandles.nodes{3},obj.bdHandles.filters{1},obj.handles.esb_hg);
          obj.connectLR(obj.bdHandles.nodes{4},obj.bdHandles.filters{2},obj.handles.esb_hg);
          
          obj.connectLR(obj.bdHandles.filters{1},obj.bdHandles.nodes{7},obj.handles.esb_hg);
          obj.connectLR(obj.bdHandles.filters{2},obj.bdHandles.nodes{8},obj.handles.esb_hg);
          
        otherwise % connect input nodes with output nodes
          
          % Connections
          for n=1:4
            obj.connectLR(obj.bdHandles.nodes{n},obj.bdHandles.nodes{n+4},obj.handles.esb_hg);
          end
          
      end
    end
    
    
    %% Get element by tag
    function el = getElementByTag(obj,tag,elementType)
      % Get specified list
      list = obj.bdHandles.(elementType);

      % Get all tags
      allTags = cellfun(@(x)x.tag, list, 'UniformOutput',false);
      
      % Return specified element
      mask = ismember(allTags,tag);
      if any(mask)
        el = list{mask};
      else
        el = [];
      end
    end
    
    
    %% Callbacks
    function clickNodeHandler(obj, handles, event) %#ok<INUSD>
      tmp = guidata(handles);
      elem = tmp.lastClickedElement;
      obj.hController.openSelectPlot(elem.tag);
    end
    
    function clickSourceHandler(obj, handles, event) %#ok<INUSD>
      tmp = guidata(handles);
      elem = tmp.lastClickedElement;
      obj.hController.openSelectSource(elem.tag);
    end
    
    function clickBlackBoxHandler(obj, handles, event) %#ok<INUSD>
        prompt = {obj.tr('dp:blackbox')};
        dlg_title = obj.tr('dt:blackbox');
        num_lines = 1;
        def = {''};
        answer = Tools.newid(prompt,dlg_title,num_lines,def);
        
        answer(cellfun(@isempty,answer)) = [];
        
        if(isempty(answer)), return; end
        
        % German decimal point notation (comma) to English conversion
        % (point)
        answerClean = strrep(answer,',','.'); 
        
        % Parsing and rounding
        answerClean = round(str2double(answerClean));
        
        if(any(isnan(answerClean)) || any(answerClean < 100) || ...
            any(answerClean > 103))
          return;
        end
        
        % Notify controller
        obj.hController.connectExperiment('4',answerClean);
    end
    
    
    %% Plot functions
    function plotNodeDescription(obj, nodeNum, nodeLabel)
      node = obj.getElementByTag(nodeNum,'nodes');
      if ~isempty(node)
        node.plotDescription(strjoin(nodeLabel,', '));
      end
    end
    
    function changeNodeColor(obj,nodeNum)
      cellfun(@(x)x.setCircleColor([0 0 1]),obj.bdHandles.nodes,'UniformOutput',false);
      
      node = obj.getElementByTag(nodeNum,'nodes');
      if ~isempty(node)
        node.setCircleColor([0 .4 1]);
      end
    end
    
    function resetNodeDescriptions(obj)
      for iter = 1:length(obj.bdHandles.nodes)
        obj.plotNodeDescription(obj.bdHandles.nodes{iter}.tag,{''});
      end
    end
    
    % Custom plot wrapper
    % Wrapper so all elements get plotted into the object's axes
    function plot(obj,plotObj)
      plotObj.plot(obj.handles.ax);
    end
    
    % Plot grid
    function plotGrid(obj,Lx, Ly)
      Nx = round(Lx);
      Ny = round(Ly);
      
      nx = 0:(Nx);
      line([nx; nx],[zeros(size(nx)); Ny*ones(size(nx))],...
        'LineStyle','-','Color',0.9*[1 1 1],...
        'Parent', obj.handles.ax);
      
      ny = 0:(Ny);
      line([zeros(size(ny)); Nx*ones(size(ny))], [ny; ny],...
        'LineStyle','-','Color',0.9*[1 1 1],...
        'Parent', obj.handles.ax);
    end
    
    % Connect blocks
    function h = connectLR(obj,lObj,rObj,par)
      if(nargin <4)
        par = obj.handles.ax;
      end
      h = Viewer.BD.arrow([lObj.east,lObj.cy], [rObj.west,rObj.cy],...
        'Parent', par);
    end
    
    % Plot line
    function h = line2P(obj,x1,y1,x2,y2,par)
      if(nargin < 6)
        par = obj.handles.ax;
      end
      h = Viewer.BD.arrow([x1,y1], [x2,y2],'Length',0,...
        'Parent', par);
    end
    
    % Plot arrow
    function h = arrow2P(obj,x1,y1,x2,y2,par)
      if(nargin < 6)
        par = obj.handles.ax;
      end
      h = Viewer.BD.arrow([x1,y1], [x2,y2],...
        'Parent', par);
    end
    
    %% Clean up function
    function cleanUp(obj)
      % Get the fieldnames, but leave out 'sinks' and 'sources'
      types = fieldnames(obj.bdHandles);
      types = types( ~ismember(types,{'sinks','sources'}));
      
      for i = 1:length(types)
          t = types{i};
          
          start = 1;
          if strcmp(types(i),'nodes'), start = 9; end
          
          % Clear list
          obj.bdHandles.(t)(start:length(obj.bdHandles.(t))) = [];
      end
    end
    
  end

end