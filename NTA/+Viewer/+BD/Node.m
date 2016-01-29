% Clickable node (marked blue)
classdef Node < Viewer.BD.Element
  
  properties
    % Name field (of type bdBlock)
    name = [];
  end
  
  methods
    % Constructor
    function obj = Node(txt,varargin)
      obj@Viewer.BD.Element(varargin{:});
      if(nargin < 1), txt = ''; end
      
      % Publish text
      obj.name = Viewer.BD.Block(txt);
    end
    
    % Destructor
%     function delete(obj)
%       delete(obj.name);
%     end
    
    % Plot
    function obj = plot(obj,varargin)

      obj.preparePlot(varargin{:});
      if ~isempty(obj.name), obj.name.clearHandles(); end
      
      % Plot circle
      obj.handles.circle = rectangle('Position',[obj.west obj.south obj.w obj.h], ...
        'Curvature', [1 1], 'Parent',obj.ax);
      obj.setCircleColor([0 0 0]);
      
      % Plot node name
      hasName = (~isempty(obj.name) && ~isempty(obj.name.txt));
      if(hasName)
        obj.name.w = obj.w*1.1;
        obj.name.h = obj.h*1.1;
        obj.name.cx = obj.cx;
        obj.name.cy = obj.north+obj.name.h;
        
        obj.name.plot(obj.ax,{'Curvature',[1 1]},{'FontSize', 8});
      end
      
      if(~isempty(obj.clickCallback))
        % Publish callback
        obj.publishClickCallback(obj.clickCallback);
        
        % Mark node blue
        obj.setCircleColor([0 0 1]);
        if(hasName)
          obj.name.publishClickCallback(obj.clickCallback);
          set(obj.name.handles.rect, 'EdgeColor', 0.5*[1 1 1]);
        end
      end
      
      obj.plotDescription();
      
    end
    
    function setCircleColor(obj,color)
      set(obj.handles.circle,'EdgeColor',[0 0 0]);
      set(obj.handles.circle,'FaceColor',color);
    end
    
  end
  
end

