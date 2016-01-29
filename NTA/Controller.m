%% Controller
%  Controls the whole data exchange between the GUI elements and the Models

classdef Controller < handle
  
  %% Properties
  properties
    hTimers = struct();  % plot and model timers
    windows = struct();  % all windows (plot and dialog)
    figureReady = false; % flag to disable plot while model is altered
    runMode = ''; % simulation run mode
    selectedExperiment = '1'; % current experiment
    tr; % translation object
    settings; % settings from ini
    hBlockDiag % block diagram
    hLayout % block layout
  end
  
  
  %% Methods
  methods
    %% Constructor
    function obj = Controller(iniFile)
      
      % Set default ini file
      if nargin < 1, iniFile = 'settings.ini'; end
            
      % Parent constructor call
      obj@handle();
      
      % Check MATLAB version
      if ~strcmp(version('-release'),'2014b'),
        error('Unsupported MATLAB release. I work only with R2014b.');
      end
      
      % Force UTF8 encoding
      feature('DefaultCharacterSet', 'UTF8');
      
      % Try to load settings
      obj.settings = Tools.IniConfig;
      if ~obj.settings.ReadFile(iniFile)
        warning(['Could not read ini file ' iniFile]);
      end

      % Parameter
      buffersize = obj.settings.GetValues('Audio','buffersize',2048);
      Fs = obj.settings.GetValues('Audio','samplingrate',44100);

      lang = obj.settings.GetValues('General','language','de');
      loadPreviousStateFlag = obj.settings.GetValues('General','loadPreviousState','on');
      
      timerPeriodPlot = obj.settings.GetValues('Timer','plotPeriod',0.25);
      timerPeriodGet = obj.settings.GetValues('Timer','getPeriod','auto');
			
      % Set values
      timerModeGet = 'fixedSpacing';
      if strcmp(timerPeriodGet,'auto')
        switch timerModeGet
          case 'fixedRate'
            timerPeriodGet = buffersize/Fs;
            timerPeriodGet = floor(timerPeriodGet*1000)/1000;
          case 'fixedSpacing'
            % Small pause between two queue function calls
            timerPeriodGet = 0.01;
        end
      end
      
      % Display parameter
      fprintf('Starting controller with buffersize=%d, samplingrate=%dHz, plotPeriod=%2.3fs, getPeriod=%2.3fs \n',...
        buffersize,Fs,timerPeriodPlot,timerPeriodGet);
      
      % Create translation object
      obj.tr = i18n(lang);
      
      % Overview window
      obj.windows.overview = Viewer.Overview(obj,obj.tr,@obj.keyPressHandler);
      obj.hBlockDiag = obj.windows.overview.blockDiagram;
      
      % Figures
      obj.windows.plotWindows = {};
      
      % Windows
      obj.windows.selectSource = Viewer.SelectSource(obj,obj.tr);
      obj.windows.selectPlot = Viewer.SelectPlot(obj,obj.tr);
      obj.windows.settings = Viewer.Settings(obj,obj.tr);
      obj.windows.about = Viewer.About(obj,obj.tr);
      
      % Model
      obj.hLayout = Model.Layout(Fs,buffersize,obj.settings);
      obj.connectExperiment(obj.selectedExperiment);
      obj.volumeChanged(0.5);
      
      % Try to load state of previous GUI run
      pause(0.1)
      if strcmp(loadPreviousStateFlag,'on')
        obj.loadState();
      end
      
      % Unlock figure
      obj.figureReady = true;
      
      % Setup and start timers
      obj.hTimers.plotter = timer('BusyMode','drop',...
        'ExecutionMode','fixedRate','Name','plotter',...
        'Period',timerPeriodPlot,'TimerFcn',@obj.updatePlotWindows);
      obj.hTimers.getter = timer('BusyMode','drop',...
        'ExecutionMode',timerModeGet,'Name','getter',...
        'Period',timerPeriodGet,'TimerFcn',@obj.updateSources);
      
      obj.changeRunMode('stop');
      start(obj.hTimers.getter);
    end
    
    
    %% Connect experiment
    function connectExperiment(obj,varargin)
      
      % Lock plot windows
      obj.figureReady = false;
      
      % Update layout
      obj.selectedExperiment = varargin{1};
			obj.hLayout.connectExperiment(varargin{:});
      
      % Update GUI
      obj.windows.overview.connectExperiment(varargin{:});      
      
      % Update plot windows (delete if nodes are not available anymore)
      if ~isempty(obj.windows.plotWindows)
        allLayoutNodeTags = cellfun(@(x)x.tag, obj.hLayout.hNodes,'UniformOutput',false);
        
        % List of windows to be closed
        toClose = {};
        for n=1:length(obj.windows.plotWindows)
          w = obj.windows.plotWindows{n};
          plotNodeTags = cellfun(@(x)x.tag, w.nodes,'UniformOutput',false);
          if any(~ismember(plotNodeTags,allLayoutNodeTags))
            toClose{end+1} = w; %#ok<AGROW>
          end
        end
        
        % Close all windows whose nodes are not available
        for n=1:length(toClose)
          obj.plotClose(toClose{n});
        end
      end
      
      % Release plot windows
      obj.figureReady = true;
    end
    
    
    %% Listen to node callback
    function listenToNode(obj,nodeTag)
      try
        obj.hLayout.listenToNode(nodeTag);
        obj.hBlockDiag.changeNodeColor(nodeTag);
      catch e
        disp(['Cannot listen to node ',nodeTag]);
        disp(e.message);
        disp(e.stack(1))
      end
    end
    
    
    %% Update plots
    function updatePlotWindows(obj, handle, event)  %#ok<INUSD>
      if ~isempty(obj.windows.plotWindows) && obj.figureReady
        for i = 1:length(obj.windows.plotWindows)
          try
            obj.windows.plotWindows{i}.updateAxes();
          catch plotErr
            disp('Error. Stopping plotter.');
            disp(plotErr.message);
            disp(plotErr.stack(1))
            obj.changeTimerMode('stop','plotter');
          end
        end
      end
    end
    
    
    %% Update buffers
    function updateSources(obj, handles, event)  %#ok<INUSD>
      try
        obj.hLayout.updateSources();
      catch getErr
        disp('Error. Stopping getter. Please restart program.');
        disp(getErr.message);
        disp(getErr.stack(1))
        obj.changeTimerMode('stop','getter');
      end
    end
    
    
    %% Open windows
    function openSelectPlot(obj,num)
      if ~obj.windows.selectPlot.isOpen
        % Open window
        obj.windows.selectPlot.open(num);
      else
        % Move to foreground
        figure(obj.windows.selectPlot.handles.fig);
      end
    end
    
    function openSelectSource(obj,tag)
      if ~obj.windows.selectSource.isOpen
        % Get source
        source = obj.hLayout.getModelByTag(tag,'sources');

        % Open window
        obj.windows.selectSource.open(tag, source.mode, source.freq, ...
          source.amp, source.duty);
      else
        % Move to foreground
        figure(obj.windows.selectSource.handles.fig);
      end
    end
    
    function openSettings(obj)
      if ~obj.windows.settings.isOpen
        % Open
        obj.windows.settings.open();
      else
        % Move to foreground
        figure(obj.windows.settings.handles.fig);
      end
    end
    
    function openAbout(obj)
      if ~obj.windows.about.isOpen
        % Open
        obj.windows.about.open();
      else
        % Move to foreground
        figure(obj.windows.about.handles.fig);
      end
    end
    
    
    %% Change oscillator parameter
    function changeOscillatorParameter(obj, oscTag, mode, freq, amp, duty)
      
      osc = obj.hLayout.getModelByTag(oscTag,'sources');
      osc.mode = mode;
      osc.freq = freq;
      osc.amp = amp;
      osc.duty = duty;
      
      mask = ismember(obj.windows.selectSource.modesValues,mode);
      if ~any(mask)
        modeLabel = obj.tr('none');
      else
        modeLabel = obj.windows.selectSource.modesLabels{mask};
      end
      
      % Notify block diagram
      bdOsc = obj.hBlockDiag.getElementByTag(oscTag,'sources');
      bdOsc.plotDescription(modeLabel);
    end
    
    
    %% Fix node-annotations in block diagram
    function updateNodeAnnotations(obj)
      % Reset the block diagram
      obj.hBlockDiag.resetNodeDescriptions();
      
      % Get all node tags
      allNodes = cellfun(@(x)x.nodes{1}, obj.windows.plotWindows, 'UniformOutput',false);
      
      if isempty(allNodes), return; end
      
      allNodeTags = cellfun(@(x)x.tag, allNodes, 'UniformOutput',false);
      allNodeTagsUnique = unique(allNodeTags);
      
      % Add annotation to every node
      for n=1:length(allNodeTagsUnique)
        % Current node
        nodeTag = allNodeTagsUnique(n);
        
        % All associated window types
        typeValues = cellfun(@(x)x.baseType,obj.windows.plotWindows(...
          ismember(allNodeTags,nodeTag)));
        
        typeLabels = obj.windows.selectPlot.typesLabelsAll(...
          ismember(obj.windows.selectPlot.typesValuesAll,typeValues));
        
        % Plot the annotation
        obj.hBlockDiag.plotNodeDescription(nodeTag,typeLabels);
      end
    end
    
    
    %% Open a new plot window
    function addPlotWindow(obj,type,nodeTag)
      % Lock figures
      obj.figureReady = false;
      
      % Check if too many windows would be opened
      numMaxPlotWindows = obj.settings.GetValues('Plot','numMaxPlotWindows',8);
      if length(obj.windows.plotWindows) >= numMaxPlotWindows
        obj.DisplayStatus(obj.tr('msg:toomanywindows'));
        return;
      end
      
      % Check if this window already exists
      allTypes = cellfun(@(x)x.baseType,obj.windows.plotWindows);
      if ~isempty(allTypes)
        windowSubset = obj.windows.plotWindows(ismember(allTypes,type));
        nodeTags = cellfun(@(x)x.nodes{1}.tag,windowSubset,'UniformOutput',false);
        
        alreadyOpened = false;
        if any(ismember(nodeTags,nodeTag(1)))
          if length(nodeTag) > 1 % for ccf or jpdf
            nodeTags2 = cellfun(@(x)x.nodes{2}.tag,windowSubset,'UniformOutput',false);
            if any(ismember(nodeTags2,nodeTag(2)))
              alreadyOpened = true;
            end
          else
            alreadyOpened = true;
          end
        end
        
        if alreadyOpened
          obj.DisplayStatus(obj.tr('msg:windowalreadyopened'));
          obj.figureReady = true;
          return;
        end
      end
      
      % Get all node tags
      allNodeTags = cellfun(@(x)x.tag,obj.hLayout.hNodes,'UniformOutput',false);
      
      % Find selected nodes
      [mask,order] = ismember(allNodeTags,nodeTag);
      if ~any(mask)
        % Node not found
        obj.figureReady = true;
        return;
      end
      
      nodes = obj.hLayout.hNodes(mask);
      
      % Order
      tmp = order(mask);
      if tmp > length(nodes), tmp=length(nodes); end
      nodes = nodes(tmp);
      
      % Create new plot window
      figObj = Viewer.PlotWindow(type,nodes,@obj.keyPressHandler,obj.runMode,obj,obj.tr);
      
      % Publish figure to figures list
      obj.windows.plotWindows{end+1} = figObj;
      
      % Update block diagram
      obj.updateNodeAnnotations();
      
      % Notify GUI
      obj.DisplayStatus(obj.tr('msg:addedwindow'));
      
      % Sort opened plot windows
      obj.sortPlotWindows('single');
      obj.figureReady = true;
    end
    
    
    %% Arrange plot windows
    % if number of windows > 4: sort in 2 rows
    function sortPlotWindows(obj,columnMode)
      numWindows = size(obj.windows.plotWindows,2);
      
      % Lock windows
      for iter=1:numWindows
        obj.windows.plotWindows{iter}.figureReady = 0;
      end
      
      % Position of overview window
      overviewPos = obj.windows.overview.handles.fig.OuterPosition;
      
      % Magic number for Gnome taskbar (top of screen)
      topTaskbarOffset = 0;
      if isunix, topTaskbarOffset =  obj.settings.GetValues('Plot','taskbarOffset',0.025); end
      
      % General offsets for plot windws
      offsetX = 0;
      offsetY = overviewPos(1,2)+overviewPos(1,4);
      if offsetY > 0.8, offsetY = 0.5; end
      
      % Width and height of space to fill up with plot windows
      totalWidth = 1;
      totalHeight = 1-offsetY-topTaskbarOffset;
      
      % Number of columns
      if strcmp(columnMode,'multi')
        numColumns = min(2,numWindows);
      else
        numColumns = 1; 
      end
      
      % Number of rows
      numRows = ceil(numWindows/numColumns);
      
      % Width and height of single plot window
      width = totalWidth/numRows;
      height = totalHeight/numColumns;

      % Deal with too small space for plot windows
      if width < 0.2, width = 0.5; end
      if height < 0.2, height = 0.5; end
      
      % Overview window to front
      figure(obj.windows.overview.handles.fig);
      
      columnIter = numColumns-1;
      rowIter = 1;
      for n = 1:numWindows
        % Determine position of plot window
        xPos = offsetX+(rowIter-1)*width;
        yPos = offsetY+(columnIter)*height;
        f = obj.windows.plotWindows{n}.handles.fig;
        
        % Change figure's position
        f.OuterPosition = [xPos,yPos,width,height];
        
        % Bring figure to front
        figure(f); 
        
        if rowIter == numRows % new column
          columnIter = columnIter-1;
          rowIter = 0;
        end
        rowIter = rowIter+1;
        
        % Unlock window
        obj.windows.plotWindows{n}.figureReady = 1;
      end
    end
    
    
    %% Handler for keyboard events
    function keyPressHandler(obj,handle,event)  %#ok<INUSL>
      switch(event.Key)
        case 'f1'
          obj.changeRunMode('short');
        case 'f2'
          obj.changeRunMode('long');
        case 'f4' % stop
          obj.changeRunMode('stop');
        case 'f6' % Sort plot windows
          obj.sortPlotWindows('single');
				case 'f7' % Sort plot windows with multiple columns
					obj.sortPlotWindows('multi');
      end
    end
    
    
    %% Change run mode
    function changeRunMode(obj,runMode)
      obj.runMode = runMode;
      
      % Reset audio devices
      obj.hLayout.resetAD();
      
      % Toggle timer
      if strcmp(obj.runMode,'stop')
        obj.changeTimerMode('stop');
        statusMsg = obj.tr('msg:measurestop');
      else
        obj.changeTimerMode('start');
        statusMsg = obj.tr('msg:measurestart');
      end
      
      % Notify GUI
      obj.windows.overview.ToggleButtonColor(runMode);
      
      for iter = 1:length(obj.windows.plotWindows)
        obj.windows.plotWindows{iter}.setRunMode(obj.runMode);
      end
      
      obj.DisplayStatus(statusMsg);
    end
    
    %% Set volume
    function volumeChanged(obj,volumeVal)
      obj.hLayout.adOutputVolume = volumeVal;
      obj.windows.overview.setVolume(volumeVal);
    end
    
    %% Change timer mode
    function changeTimerMode(obj, funName,timerNames)
      if nargin < 2, funName = 'start'; end
      if nargin < 3, timerNames = {'plotter'}; end
      
      % Convert function name string to actual function handle
      funHandle = str2func(funName);
      
      % Determine previous running state
      runningMode = 'off';
      if strcmp(funName,'stop'), runningMode = 'on'; end
      
      % Iterate over all given timer names
      for iter=1:length(timerNames)
        if isfield(obj.hTimers,timerNames{iter});
          t = obj.hTimers.(timerNames{iter});
          
          % Change the running state
          if isvalid(t) && strcmp(t.Running, runningMode);
            funHandle(t);
          end
        end
      end
    end
    
    
    %% Close plot handler
    function plotClose(obj, plotWindow)
      % TODO: delete annotation in block diagram!
      
      % Find all indices of figures
      figIndices = cellfun(@(x)x.handles.fig.Number,obj.windows.plotWindows);
      
      % Locate figure to close
      index = find(figIndices == plotWindow.handles.fig.Number);
      
      % Overwrite handles
      if(length(obj.windows.plotWindows) > 1 && index ~= length(obj.windows.plotWindows))
        obj.windows.plotWindows(index:end-1) = obj.windows.plotWindows(index+1:end);
      end
      obj.windows.plotWindows(end) = [];
      
      % Finally delete figure to close
      delete(plotWindow);
      obj.updateNodeAnnotations();
    end
    
    
    %% Get model streams
    function s = getModelNodeStreams(obj,nodes) %#ok<INUSL>
      s = cellfun(@(x)x.getStream(),...
        nodes,'UniformOutput',false);
    end
    
    
    %% Update status text window
    function DisplayStatus(obj,txt)
      obj.windows.overview.DisplayStatus(txt);
    end
    
    
    %% Delete function
    function delete(obj)
      % Save current state
      obj.saveState();
      
      % Stop and delete timers
      obj.changeTimerMode('stop');
      fn = fieldnames(obj.hTimers);
      for n=1:length(fn)
        if strcmp(obj.hTimers.(fn{n}).Running, 'on')
          stop(obj.hTimers.(fn{n}));
        end
        delete(obj.hTimers.(fn{n}));
      end
      
      % Release sound card
      obj.hLayout.releaseAD();
      
      % Close all plot windows
      for n=1:length(obj.windows.plotWindows)
        delete(obj.windows.plotWindows{n});
      end
      
      % Close settings window
      if obj.windows.settings.isOpen
        delete(obj.windows.settings);
      end
    end
    
    
    %% Save GUI state
    function saveState(obj)
      state = struct();
      
      % Selected experiment
      state.selectedExperiment = obj.selectedExperiment;
      
      state.adOutputVolume = obj.hLayout.adOutputVolume;
      
      % Two oscillators
      paramToSave = {'tag','mode','freq','amp','duty'};
      for dummy=1:2
        state.oscillators{dummy} = struct();
        for n=1:length(paramToSave)
          paramName = paramToSave{n};
          state.oscillators{dummy}.(paramName) = ...
            obj.hLayout.hSources{dummy+2}.(paramName);
        end
      end
      
      % Plot windows
      state.plotWindows = cell(size(obj.windows.plotWindows));
      for n=1:length(obj.windows.plotWindows)
        w = obj.windows.plotWindows{n};
        state.plotWindows{n}.baseType = w.baseType;
        state.plotWindows{n}.nodes = cellfun(@(x)x.tag,w.nodes,'UniformOutput',false);
      end
      save('state.mat','state');
    end
    
    
    %% Load previous state
    function loadState(obj)
      try
        tmp = load('state.mat');
        state = tmp.state;
      catch
        disp('No previous saved states found');
        return;
      end
      
      % Selected experiment
      obj.connectExperiment(state.selectedExperiment);
      
      % Volume
      obj.volumeChanged(state.adOutputVolume);
      
      % Two oscillators
      for dummy=1:2
        o = state.oscillators{dummy};
        obj.changeOscillatorParameter(o.tag, ...
          o.mode, o.freq, o.amp, o.duty)
      end
      
      % Plot windows
      for n=1:length(state.plotWindows)
        obj.addPlotWindow(state.plotWindows{n}.baseType,...
          state.plotWindows{n}.nodes);
      end
      obj.updateNodeAnnotations();
    end
    
    
    %% Save to ini functions
    function changeSettings(obj,tags)
      % iterate over tag
      for i = 1:size(tags,1)
        if strcmp(tags{i,2},'plotPeriod')
          % check for useful plotPeriod values
          val = str2double(tags{i,3});
          if val < 0.01,
            val = 0.1;
          end

          if val > 1,
            val = 1;
          end
          disp('SETTINGS: Plot period settings were out of borders.')
          
          val = num2str(val);
        elseif strcmp(tags{i,2},'pdfHistogramLimit')
          % check for useful Histogram-Limit values
          val = str2double(tags{i,3});
          if val < 0.1
            val = 0.1;
          elseif val > 10
            val = 10;
          end
          disp('SETTINGS: Histogram-Limit settings were out of borders.')
          
          val = num2str(val);
        else
          val = tags{i,3};
        end
        % Set the settings
        obj.settings.SetValues(tags{i,1},tags{i,2},val);
      end
      
      % write to the .ini file
      obj.settings.WriteFile('settings.ini');
    end
  end
end
