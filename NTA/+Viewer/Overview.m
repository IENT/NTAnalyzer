%% Overview window
% Handles controlls and block diagram

classdef Overview < Viewer.Viewer
	properties
    blockDiagram
    subExpsLabels
    subExpsValues
    statusTimer
  end
  
	methods
    %% Constructor
		function obj = Overview(controller,tr,keyPressHandler)
			obj = obj@Viewer.Viewer(controller,tr);
      
      % Magic number for Windows taskbar offset (bottom of screen)
      bottomTaskbarOffset = 0;
      if ~isunix, bottomTaskbarOffset = controller.settings.GetValues('Plot','taskbarOffset',0.025); end
      
			obj.handles.fig = figure('Units','normalized','OuterPosition',[0,bottomTaskbarOffset,1,0.4],...
        'Name',obj.tr('title'),'NumberTitle','off',...
        'menuBar','none','CloseRequestFcn',@obj.CloseRequestHandler,'KeyPressFcn',keyPressHandler);

      % Create block diagram
      [obj.blockDiagram] = Viewer.BlockDiag(controller,tr,obj.handles.fig);
      
			
      % Create controll panel
      bdPos = get(obj.blockDiagram.handles.ax,'Position');
      obj.handles.mainPanel = uipanel('Parent',obj.handles.fig,'FontSize',12,...
        'Units','normalized','Position',[bdPos(3) 0.2 1-bdPos(3) 0.8]);
      
      % Buttons
      obj.handles.short = uicontrol('Parent',obj.handles.mainPanel,'Style','pushbutton',...
        'Tag','short','String', obj.tr('short'),'Units','normalized','Position',[0.025,0.025,0.25,0.1],...
        'callback',@obj.ClickButtonHandler,'KeyPressFcn',keyPressHandler);
        
      obj.handles.long = uicontrol('Parent',obj.handles.mainPanel,'Style','pushbutton',...
        'Tag','long','String',obj.tr('long'),'Units','normalized','Position',[0.325,0.025,0.25,0.1],...
        'callback',@obj.ClickButtonHandler,'KeyPressFcn',keyPressHandler);
      
      obj.handles.stop = uicontrol('Parent',obj.handles.mainPanel,'Style','pushbutton',...
        'Tag','stop','String',obj.tr('stop'),'Units','normalized','Position',[0.625,0.025,0.25,0.1],...
        'callback',@obj.ClickButtonHandler,'KeyPressFcn',keyPressHandler);

      % Experiment menu
      obj.subExpsValues = {...
        '1',...
        '2',...
        '3',...
        '4',...
      };
    
      obj.subExpsLabels = cellfun(@(x)horzcat([obj.tr('subexp') ' '],x),...
        obj.subExpsValues,'UniformOutput',false);

      obj.handles.subExp = uicontrol('Parent',obj.handles.mainPanel,'Style', 'popupmenu',...
        'Units','normalized','Position',[0.05,0.85,0.45,0.1],...
        'String',obj.subExpsLabels,'callback',@obj.SubExpChangedHandler);%,'Value',modeVal);	
      
      obj.handles.statusText = uicontrol('Style','text','Parent',obj.handles.fig,...
        'Units','normalized','Position', [bdPos(3) 0 1-bdPos(3) 0.075],...
        'Enable','inactive',...
        'String','');
      
      obj.handles.settings = uicontrol('Parent', obj.handles.mainPanel,'Style','pushbutton',...
        'Tag','settings','String',obj.tr('settings'),'Units','normalized','Position',[0.55,0.85,0.2,0.1],...
        'callback',@obj.openSettings,'KeyPressFcn',keyPressHandler);
      
      obj.handles.about = uicontrol('Parent', obj.handles.mainPanel,'Style','pushbutton',...
        'Tag','about','String',obj.tr('about'),'Units','normalized','Position',[0.775,0.85,0.1,0.1],...
        'callback',@obj.openAbout,'KeyPressFcn',keyPressHandler);
      
      obj.handles.volume = uicontrol('Parent',obj.handles.mainPanel,'Style','slider',...
        'Units','normalized','Position',[0.0500 0.2000 0.8000 0.0400],...
        'String','Volume','Value',0.5,'callback',@obj.VolumeChangedHandler);
      
      obj.handles.volumeLabel = uicontrol('Parent',obj.handles.mainPanel,'Style','text',...
        'Units','normalized','Position',[0.05 0.25 0.8 0.04],...
        'String',obj.tr('volume'),'HorizontalAlignment','Left');
      
      obj.ToggleButtonColor('stop');
      obj.isOpen = true;
    end
    
    
    %% Callbacks
    function ClickButtonHandler(obj, handles, event) %#ok<INUSD>
      % Get mode by button tag
      runMode = handles.Tag;
      
      % Notify controller
			obj.hController.changeRunMode(runMode);
    end
    
    function openSettings(obj,handles,event) %#ok<INUSD>
      obj.hController.openSettings();
    end
    
    function openAbout(obj,handles,event) %#ok<INUSD>
      obj.hController.openAbout();
    end
    
    function ToggleButtonColor(obj, buttonName)
      % Set colors of all buttons to black
      set(obj.handles.short,'ForegroundColor','k');
      set(obj.handles.long, 'ForegroundColor','k');
      set(obj.handles.stop, 'ForegroundColor','k');
      
      % Change only the color of the specified button
      if ~ismember({'long','short','stop'},buttonName), error('Wrong button name to toggle'); end
      
      set(obj.handles.(buttonName),'ForegroundColor','b');
    end
    
    function SubExpChangedHandler(obj, handles, event) %#ok<INUSD>
      % Get current value
      subExpVal = get(obj.handles.subExp,'Value');
      subExpVal = obj.subExpsValues{subExpVal};
      
      % Notify controller
      obj.hController.connectExperiment(subExpVal);
    end
    
    function VolumeChangedHandler(obj, handles, event) %#ok<INUSD>
      volumeVal = obj.handles.volume.Value;
      volumeVal = round(volumeVal*100)/100;
      
      obj.hController.volumeChanged(volumeVal);
    end
    
    %% Connect experiment
    function connectExperiment(obj,varargin)
      
      % Update block diagram
      obj.blockDiagram.plotExperimentSpecific(varargin{:});
      
      % Update select
      obj.setSubExp(varargin{1});
    end
    
    %% Set functions
    function setSubExp(obj,subExpVal)
      mask = ismember(obj.subExpsValues,subExpVal);
      if ~any(mask)
        mask = 1;
      end
      obj.handles.subExp.Value = find(mask);
    end
    
    function setVolume(obj,volumeVal)
      obj.handles.volume.Value = volumeVal;
    end
    
    %% Close request
    function CloseRequestHandler(obj, handles, event) %#ok<INUSD>      
      
      % Delete the status timer
      obj.isOpen = false;
      if ~isempty(obj.statusTimer) && strcmp(obj.statusTimer.Running,'on')
        stop(obj.statusTimer);
      end
      delete(obj.statusTimer);
      delete(obj.handles.fig);
      delete(obj.hController);
    end
    
    %% Displays status text for 3 seconds
    function DisplayStatus(obj,text)
      obj.handles.statusText.String = text;
      if ~isempty(obj.statusTimer)
        if strcmp(obj.statusTimer.Running,'on')
          stop(obj.statusTimer);
        end
        delete(obj.statusTimer);
      end
      
      obj.statusTimer = timer('StartDelay',3,'UserData',obj.handles.statusText,...
        'TimerFcn',@(timerObj,~)(set(timerObj.UserData,'String', '')));
      start(obj.statusTimer);
    end
    
    %% Update text in new language
    function updateText(obj)
      set(obj.handles.short,'String',obj.tr('short'));
      set(obj.handles.stop,'String',obj.tr('stop'));
      set(obj.handles.long,'String',obj.tr('long'));
      set(obj.handles.settings,'String',obj.tr('settings'));
      set(obj.handles.volumeLabel,'String',obj.tr('volume'));
    
      obj.subExpsLabels = cellfun(@(x)horzcat([obj.tr('subexp') ' '],x),...
        obj.subExpsValues,'UniformOutput',false);
      set(obj.handles.subExp,'String',obj.subExpsLabels);
    end
    
	end
end
