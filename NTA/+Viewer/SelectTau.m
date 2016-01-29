%% SelectTau
% For joint PDF

classdef SelectTau < Viewer.Viewer
  properties
    Fs = 1;
    tau = 20;
    deltaLabels = {'-10' '-1' '+1' '+10'};
  end

  methods
    %% Constructor
    function obj = SelectTau(tau,Fs,varargin)
      
      obj = obj@Viewer.Viewer(varargin{:});
      obj.tau = tau;
      obj.Fs = Fs;
      
      % Openfigure
      obj.isOpen = true;
      obj.handles.fig = figure('Menubar','none','Units','normalized',...
            'Position',[0.4,0.4,0.2,0.3],...
            'Name',obj.tr('dt:selecttau') ,'NumberTitle','off',...
            'CloseRequestFcn',@obj.CloseRequestHandler,'KeyPressFcn',@obj.keyPressHandler);
      Tools.WinOnTop(obj.handles.fig);

      % Create GUI elements
      obj.handles.ax = axes('Parent',obj.handles.fig,'Units','normalized',...
        'Position',[.05 .85 .9 .1]);
      axis(obj.handles.ax,'off');
      
      % Status text
      obj.publishTau();
      
      % Button panel
      obj.handles.panel = uipanel('Parent',obj.handles.fig,'FontSize',12,...
        'Position',[.05 .2 .9 .5]);
      
      obj.handles.deltaButtons = cell(1,length(obj.deltaLabels));
      x = .025;
      xDelta = 0.25;
      for n=1:length(obj.deltaLabels)
        obj.handles.typeButtons{n} = uicontrol('Parent',obj.handles.panel,'Style','pushbutton',...
        'Tag',obj.deltaLabels{n}, 'String',obj.deltaLabels{n},...
        'Units','normalized','Position',[x,0.55,0.2,0.35],...
        'callback',@obj.clickButtonDeltaHandler);
        x = x+xDelta;
      end
      obj.handles.reset = uicontrol('Parent',obj.handles.panel,'Style','pushbutton',...
        'String', obj.tr('reset'),...
        'Units','normalized','Position',[0.275,0.1,0.45,0.35],...
        'callback',@obj.clickButtonResetHandler);
      
      
      % Buttons
      obj.handles.close = uicontrol('Parent',obj.handles.fig,'Style','pushbutton',...
        'Units','normalized',...
        'String', obj.tr('close'),'Position',[0.05,0.025,0.3,0.1],'callback',@obj.CloseRequestHandler);
    end
    
    %% Send tau value to GUI
    function publishTau(obj)
      Ta = 1/obj.Fs;
      texts = {...
        sprintf('$$\\tau \\ = \\ %d \\  T_a \\ = \\ %2.2f\\  ms$$',...
          obj.tau,obj.tau*Ta*1000), ...
        sprintf('%s $$T_a \\  = \\ %2.2f \\ \\mu s$$ ',obj.tr('samplingperiod'),(Ta*1e6)) ...
      };
      if isfield(obj.handles,'texts')
        delete(obj.handles.texts)
        obj.handles=rmfield(obj.handles,'texts');
      end
      obj.handles.texts = text('Parent',obj.handles.ax,...
        'String',texts,'Interpreter','LaTex','FontSize',12,...
        'HorizontalAlignment','left');
      
      obj.hController.setTau(obj.tau);
    end
    
    
    
    %% Handler
    function clickButtonDeltaHandler(obj,handle,event) %#ok<INUSD>
      obj.tau = obj.tau + str2double(handle.String);
      obj.publishTau();
    end
    
    function clickButtonResetHandler(obj,handle,event) %#ok<INUSD>
      obj.tau = 0;
      obj.publishTau();
    end
    
    function keyPressHandler(obj,handle,event) %#ok<INUSL>
      switch event.Key
        case {'escape','return'}
          obj.CloseRequestHandler();
      end
    end
    
  end
    
end