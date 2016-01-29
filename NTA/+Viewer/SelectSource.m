%% SelectSource
%  Edits signal properties for a digital source

classdef SelectSource < Viewer.Viewer
  properties (SetAccess = private)
    sourceTag
    modesValues
    modesLabels
  end

  methods
    %% Constructor
    function obj = SelectSource(varargin)
      
      obj = obj@Viewer.Viewer(varargin{:});

      obj.modesLabels = {...
        obj.tr('sig:const'),obj.tr('sig:tri'),...
        obj.tr('sig:rect'),obj.tr('sig:sine'),...
        obj.tr('sig:binary'),obj.tr('sig:gaussian'),...
        obj.tr('sig:uniform')...
      };
      obj.modesValues = {'const',  'tri', 'rect','sine',...
        'bin_rand', 'gauss_noise', 'uni_noise'};
    end

    
    %% Open window
    function open(obj, sourceTag,modeVal,freqVal,ampVal,dutyVal)
      if(nargin < 3), modeVal = 'none'; end
      if(nargin < 4), freqVal = 100; end
      if(nargin < 5), ampVal = 1; end
      if(nargin < 6), dutyVal = 0.25; end
      
      % Parameter
      obj.sourceTag = sourceTag;
      modeVal = find(ismember(obj.modesValues,modeVal));
      if(isempty(modeVal)), modeVal = 1; end
      
      sourceNum = strrep(obj.sourceTag,'Osc','');
      
      % Openfigure
      obj.isOpen = true;
      obj.handles.fig = figure('Menubar','none','Units','normalized',...
            'Position',[0.4,0.4,0.2,0.3],...
            'Name',[obj.tr('settings') ' ' obj.tr('source') ' ' sourceNum],...
            'NumberTitle','off',...
            'CloseRequestFcn',@obj.CloseRequestHandler,'KeyPressFcn',@obj.keyPressHandler);
      Tools.WinOnTop(obj.handles.fig);

      % Create GUI elements
      obj.handles.modeLabel = uicontrol('Parent',obj.handles.fig,...
          'Style','text',...
          'Units','normalized','Position',[0.05, 0.8, 0.45, 0.1],...
          'String',obj.tr('signaltype'),'HorizontalAlignment','left');
        
      obj.handles.mode = uicontrol('Parent',obj.handles.fig,...
          'Units','normalized','Style', 'popupmenu',...
          'String',obj.modesLabels,'Position',[0.05,0.7,0.45,0.1],...
          'Value',modeVal,'callback',@obj.modeChangedHandler);	

      obj.handles.panel = uipanel('Parent',obj.handles.fig,'FontSize',12,...
        'Position',[.55 .2 .4 .7]);


      obj.handles.ampLabel = uicontrol('Parent',obj.handles.panel,...
          'Style','text',...
          'Units','normalized','Position',[0.05, 0.85, 0.8, 0.1],...
          'String',obj.tr('amplitude'),'HorizontalAlignment','left');
      obj.handles.amp = uicontrol('Parent',obj.handles.panel,'Style','edit',...
          'Units','normalized','Position',[0.05,0.7,0.8,0.15],...
          'String',num2str(ampVal),'HorizontalAlignment','left');

      obj.handles.freqLabel = uicontrol('Parent',obj.handles.panel,...
          'Style','text',...
          'Units','normalized','Position',[0.05, 0.55, 0.8, 0.1],...
          'String',[obj.tr('frequency') ' [Hz]'],'HorizontalAlignment','left');
      obj.handles.freq = uicontrol('Parent',obj.handles.panel,'Style','edit',...
          'Units','normalized','Position',[0.05, 0.4, 0.8, 0.15],...
          'String',num2str(freqVal),'HorizontalAlignment','left');

      obj.handles.dutyLabel = uicontrol('Parent',obj.handles.panel,...
          'Style','text',...
          'Units','normalized','Position',[0.05, 0.2, 0.8, 0.1],...
          'String',obj.tr('duty'),'HorizontalAlignment','left');
      obj.handles.duty = uicontrol('Parent',obj.handles.panel,'Style','edit',...
          'Units','normalized','Position',[0.05, 0.05, 0.8, 0.15],...
          'String',num2str(dutyVal),'HorizontalAlignment','left');


      obj.handles.buttonSelect = uicontrol('Parent',obj.handles.fig,...
          'Units','normalized','Style','pushbutton','String',...
          obj.tr('select'),'Position',[0.05,0.025,0.3,0.1],'callback',@obj.clickButtonSelectHandler);
        
      obj.handles.buttonCancel = uicontrol('Parent',obj.handles.fig,...
        'Units','normalized','Style','pushbutton',...
        'String', obj.tr('cancel'),'Position',[0.4,0.025,0.3,0.1],'callback',@obj.CloseRequestHandler);
      obj.modeChangedHandler();
    end
    
    %% Handler
    % Handler for click button events
    function clickButtonSelectHandler(obj,handle,event) %#ok<INUSD>
      freq = str2double(strrep(get(obj.handles.freq,'String'),',','.'));
      amp = str2double(strrep(get(obj.handles.amp,'String'),',','.'));
      duty = str2double(strrep(get(obj.handles.duty,'String'),',','.'));
      mode = obj.modesValues{get(obj.handles.mode,'Value')};
              
      if ~isnan(freq) && ~isnan(amp)
        if amp < 0, amp = 1; end
        if freq < 0, freq = 1; end
        if duty < 0, duty = 0; end
        if duty > 1, duty = 1; end
        
        obj.hController.changeOscillatorParameter(obj.sourceTag, mode, freq, amp, duty)
        obj.CloseRequestHandler();
      else
        obj.hController.DisplayStatus(obj.tr('msg:unvalidvalues'))
      end
    end
    
    % Handler changed mode
    function modeChangedHandler(obj, handles, event) %#ok<INUSD>
      modeVal = get(obj.handles.mode,'Value');
      modeVal = obj.modesValues{modeVal};
      
      % Default setting
      obj.handles.amp.Enable = 'on';
      obj.handles.freq.Enable = 'on';
      obj.handles.duty.Enable = 'off';
      
      % Mode specific settings
      switch modeVal
        case 'const'
          obj.handles.freq.Enable = 'off';
        case {'bin_rand','gauss_noise','uni_noise'}
          obj.handles.freq.Enable = 'off';
          obj.handles.amp.Enable = 'off';
        case 'data_signal'
          obj.handles.amp.Enable = 'off';
          obj.handles.freq.Enable = 'off';
        case 'rect'
          obj.handles.duty.Enable = 'on';
      end
    end
    
    % Handler for keyboard event
    function keyPressHandler(obj,handle,event)
      switch event.Key
        case 'escape'
          obj.CloseRequestHandler(handle,event);
        case 'return'
          obj.clickButtonSelectHandler(handle,event);
      end
    end
    
  end
    
end