classdef About < Viewer.Viewer
  properties (SetAccess = private)
  end

  methods
    %% Constructor
    function obj = About(varargin)
      obj = obj@Viewer.Viewer(varargin{:});
    end
    
    %% Open window
    function open(obj)
      obj.isOpen = true;
      % Load license
      fileID = fopen('+Viewer/gpl_license.txt');
      licenseText = textscan(fileID,'%s','Delimiter','\n');
      licenseText = licenseText{1};
      fclose(fileID);
      
      mainText = {
        obj.tr('title')
        '© Lehrstuhl und Institut für Nachrichtentechnik 2016'
        'RWTH Aachen University'
        ' '
        'Max Bläser, Johannes Fabry, Christian Rohlfing'
        ' '
        ' '        
     };
     
     mainText = [mainText; licenseText];
      % Open figure
      obj.handles.fig = figure('Menubar','none','Units','normalized',...
            'Position',[0.4,0.4,0.3,0.2],...
            'Name',[obj.tr('about') ' ' obj.tr('title')],'NumberTitle','off','CloseRequestFcn',@obj.ClickButtonCancelHandler);

      % Create GUI elements
      obj.handles.ax = axes('Parent',obj.handles.fig',...
        'Units','normalized','Position',[0,0.5,1,0.5],'XColor','none','YColor','none');
      
      [I,~,mask]=imread('+Viewer/rwth_ient_logo.png');
      obj.handles.logo = imshow(I);
      obj.handles.logo.AlphaData = mask;
      
      obj.handles.text = uicontrol('Parent',obj.handles.fig,...
          'Units','normalized','Style', 'edit','HorizontalAlignment','left', 'Enable','inactive','Max',100,...
          'String',mainText,'Position',[0.05,0.1,0.9,0.4]);
    end
    
    %% Click handler
    function ClickButtonCancelHandler(obj,handle,event) %#ok<INUSD>
      obj.isOpen = false;
      delete(obj);
    end
    
    %% Destructor
    function delete(obj,handle,event) %#ok<INUSD>
      delete(obj.handles.fig)
    end
  end
    
end