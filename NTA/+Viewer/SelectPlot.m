%% SelectPlot window
% opens new plot window
classdef SelectPlot < Viewer.Viewer
  properties (SetAccess = private)
    nodeTag
    status
    typesValues
    typesValuesAll
    typesLabels
    typesLabelsAll
  end
  
  methods
    %% Constructor
    function obj = SelectPlot(varargin)
      obj = obj@Viewer.Viewer(varargin{:});
      
      % Publish properties
      obj.typesValues = {'acf','ccf','pdf','jpdf','time','listen'};
      
      % Labels for select field
      obj.typesLabels = cellfun(@(x)(obj.tr(['fcn:' x])),obj.typesValues,'UniformOutput',false);
      obj.typesValuesAll = [obj.typesValues,{'psd','cpsd','pf','spectrum'}];
      obj.typesLabelsAll = cellfun(@(x)(obj.tr(['fcns:' x])),obj.typesValuesAll,'UniformOutput',false);
    end
    
    %% Open function
    function obj = open(obj,nodeTag)
      obj.nodeTag = nodeTag;
      
      % Figure
      obj.isOpen = true;
      obj.handles.fig = figure('Menubar','none','Units','normalized',...
        'Position',[0.4,0.4,0.2,0.3],...
        'Name',[obj.tr('node') ' ' num2str(obj.nodeTag)],'NumberTitle','off','CloseRequestFcn',@obj.CloseRequestHandler);
      
      % Button list
      obj.handles.typeButtons = cell(1,length(obj.typesValues));
      y = 0.8;
      yDelta = 0.12;
      for n=1:length(obj.typesLabels)
        obj.handles.typeButtons{n} = uicontrol('Parent',obj.handles.fig,'Style','pushbutton',...
          'Tag',obj.typesValues{n}, 'String',obj.typesLabels{n},...
          'Units','normalized','Position',[0.1,y,0.8,0.1],...
          'callback',@obj.selectTypeButtonClickHandler);
        y = y-yDelta;
      end
      
      % Cancel button
      obj.handles.cancel = uicontrol('Parent',obj.handles.fig,'Style','pushbutton',...
        'Units','normalized',...
        'String', obj.tr('cancel'),'Position',[0.2,0.025,0.6,0.1],'callback',@obj.CloseRequestHandler);
      %       obj.handles.go =
      obj.status.type = [];
      obj.status.ax = [];
    end
    
    
    %% Button click handler
    function selectTypeButtonClickHandler(obj,handle,event) %#ok<INUSD>
      % Get button's tag
      type = get(handle,'Tag');
      
      % Get second node
      if strcmp(type,'ccf')||strcmp(type,'jpdf')
        prompt = {['1. ' obj.tr('node')],['2. ' obj.tr('node')]};
        dlg_title = obj.tr('dt:secondnode');
        num_lines = 1;
        def = {obj.nodeTag,''};
        answer = Tools.newid(prompt,dlg_title,num_lines,def);
        
        answer(cellfun(@isempty,answer)) = [];
        
        if isempty(answer)
          return
        end
        
        % German decimal point notation to English conversion
        answerClean = strrep(answer,',','.');
        
        % Parsing and rounding
        answerClean = round(str2double(answerClean));
        
        % Return if parsing went wrong or answer is below 1 (there is no
        % node 0)
        if any(isnan(answerClean)) || any(answerClean < 1),
%           obj.hController.DisplayStatus();
          return;
        end
        
        % Convert to string again
        answerClean = cellfun(@num2str, num2cell(answerClean),...
          'UniformOutput',false);
                
      else
        answerClean = {obj.nodeTag};
      end
      
      if strcmp(type,'listen')
        % Listener
        obj.hController.listenToNode(answerClean);
      else
        % Finally open the plot window
        obj.hController.addPlotWindow({type},answerClean);
      end
      % Close this window
      obj.CloseRequestHandler();
    end
  end
  
end