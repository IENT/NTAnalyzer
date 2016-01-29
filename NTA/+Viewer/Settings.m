%% Settings window
classdef Settings < Viewer.Viewer
  properties (SetAccess = private)
  end

  methods
    %% Constructor
    function obj = Settings(varargin)
      obj = obj@Viewer.Viewer(varargin{:});
    end
    
    %% Open window
    function open(obj)
      obj.isOpen = true;
      % Openfigure
      obj.handles.fig = figure('Menubar','none','Units','normalized',...
            'Position',[0.4,0.4,0.2,0.3],...
            'Name',obj.tr('settings'),'NumberTitle','off',...
            'CloseRequestFcn',@obj.ClickButtonCancelHandler,...
            'KeyPressFcn', @obj.keyPressHandler);

      % Create GUI elements
      plotTypes = {'imagesc','surf'};
      obj.handles.langLabel = uicontrol('Parent',obj.handles.fig,...
          'Units','normalized','Style', 'text','HorizontalAlignment','left',...
          'String',[obj.tr('selectLang') ': '],'Position',[0.05,0.8,0.45,0.1]);
      obj.handles.lang = uicontrol('Parent',obj.handles.fig,...
          'Units','normalized','Style', 'popupmenu',...
          'String',obj.tr.langs,'Position',[0.5,0.8,0.45,0.1],...
          'callback',@obj.selectLanguageHandler);
        
      obj.handles.plotTypeLabel = uicontrol('Parent',obj.handles.fig,...
          'Units','normalized','Style', 'text','HorizontalAlignment','left',...
          'String',[obj.tr('matplottype') ': '],'Position',[0.05,0.65,0.45,0.1]);
      obj.handles.plotType = uicontrol('Parent',obj.handles.fig,...
          'Units','normalized','Style', 'popupmenu',...
          'String',plotTypes,'Position',[0.5,0.65,0.45,0.1]);
        
     obj.handles.plotPeriodLabel = uicontrol('Parent',obj.handles.fig,...
          'Style','text',...
          'Units','normalized','Position',[0.05, 0.5, 0.8, 0.1],...
          'String',obj.tr('plotperiod'),'HorizontalAlignment','left');
      obj.handles.plotPeriod = uicontrol('Parent',obj.handles.fig,'Style','edit',...
          'Units','normalized','Position',[0.5,0.5,0.25,0.1],...
          'String',num2str(0.25),'HorizontalAlignment','left');
      obj.handles.plotPeriodUnit = uicontrol('Parent',obj.handles.fig,...
          'Style','text',...
          'Units','normalized','Position',[0.775, 0.475, 0.1, 0.1],...
          'String','[s]','HorizontalAlignment','left');
      
      obj.handles.histLimitLabel = uicontrol('Parent',obj.handles.fig,...
          'Style','text',...
          'Units','normalized','Position',[0.05, 0.35, 0.8, 0.1],...
          'String',obj.tr('histLimit'),'HorizontalAlignment','left');
      obj.handles.histLimit = uicontrol('Parent',obj.handles.fig,'Style','edit',...
          'Units','normalized','Position',[0.5,0.35,0.25,0.1],...
          'String',num2str(0.5),'HorizontalAlignment','left');
        
      % Buttons
      obj.handles.save = uicontrol('Parent',obj.handles.fig,...
        'Style','pushbutton','Tag','save','String',obj.tr('save'),...
        'Units','normalized','Position',[0.05,0.025,0.3,0.1],...
        'callback',@obj.ClickButtonSaveHandler);
      obj.handles.cancel = uicontrol('Parent',obj.handles.fig,...
        'Style','pushbutton','Tag','cancel','String',obj.tr('cancel'),...
        'Units','normalized','Position',[0.4,0.025,0.3,0.1],...
        'callback',@obj.ClickButtonCancelHandler);
      
      % Select current language
      set(obj.handles.lang,'Value',find(ismember(obj.tr.langs,obj.tr.lang)));
      
      % Select current plottype
      type = obj.hController.settings.GetValues('Plot','matrixPlotType');
      if ~isempty(type)
        set(obj.handles.plotType,'Value',find(ismember(plotTypes,type)));
      end
      
      plotPeriod = obj.hController.settings.GetValues('Timer','plotPeriod');
      if ~isempty(plotPeriod)
        set(obj.handles.plotPeriod,'String',num2str(plotPeriod));
      end
    end

    %% Handler
    function selectLanguageHandler(obj,handle,event)
      obj.tr.setLang(obj.handles.lang.String(obj.handles.lang.Value));

      set(obj.handles.cancel,'String',obj.tr('cancel'));
      set(obj.handles.save,'String',obj.tr('save'));
      set(obj.handles.langLabel,'String',obj.tr('selectLang'));
      set(obj.handles.plotPeriodLabel,'String',obj.tr('plotperiod'));
      set(obj.handles.plotTypeLabel,'String',obj.tr('matplottype'));
      set(obj.handles.histLimitLabel,'String',obj.tr('histLimit'));
    end
    
    function ClickButtonSaveHandler(obj,handle,event)
      tags = cell(4,3);
      
      tags{1,1} = 'General';
      tags{2,1} = 'Plot';
      tags{3,1} = 'Timer';
      tags{4,1} = 'Plot';
      
      tags{1,2} = 'language';
      tags{2,2} = 'matrixPlotType';
      tags{3,2} = 'plotPeriod';
      tags{4,2} = 'pdfHistogramLimit';
      
      tags{1,3} = obj.handles.lang.String(obj.handles.lang.Value);
      tags{2,3} = obj.handles.plotType.String(obj.handles.plotType.Value);
      tags{3,3} = obj.handles.plotPeriod.String;
      tags{4,3} = obj.handles.histLimit.String;
      
      obj.hController.changeSettings(tags);
      
      % Close GUI
      delete(obj);
      obj.hController.windows.overview.CloseRequestHandler();
      obj.hController.delete();

      % Restart controller with new settings
      Controller();
    end
    
    function ClickButtonCancelHandler(obj,handle,event)
      obj.isOpen = false;
      delete(obj);
    end
    
    function keyPressHandler(obj,handle,event)
      switch event.Key
        case 'escape'
          close(obj.handles.fig);
        case 'return'
          obj.ClickButtonSaveHandler(handle,event);
      end
    end
    
    %% Destructor
    function delete(obj,handle,event) %#ok<INUSD>
      delete(obj.handles.fig)
    end
    
    function obj = enableCloseOnEnterPress(obj)
      if isfield(obj.handles,'fig')    
      end
    end


  end
    
end