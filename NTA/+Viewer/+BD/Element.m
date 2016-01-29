% Abstract element base class
% Defines coordinates and methods to handle plot-handles and click
% callbacks
classdef Element < handle

  properties
    % Center x coordinate
    cx = 0; 
    
    % Center y coordinate
    cy = 0; 
    
    % Width
    w = 0;
    
    % Height
    h = 0;
    
    % Plot axes
    ax = [];
    
    % Plot handles
    handles = struct(); 
    
    % Click callback
    clickCallback = []; 
    
    % Description text
    description = ''; 
    
    % ID tag
    tag = '';
    
    % Debug flag
    DEBUG = 0;
  end
  
  methods (Abstract)
    % Draw element
    plot(obj)
  end
  
  methods
    % Constructor
    function obj = Element(w,h,cx,cy,clickCallback,tag,description,ax)
      
      if nargin<1, w=10; end
      if nargin<2, h=10; end
      if nargin<3, cx=0; end
      if nargin<4, cy=0; end
      if nargin<5, clickCallback = []; end
      if nargin<6, tag = ''; end
      if nargin<7, description = ''; end
      if nargin<8, ax = []; end
      
      
      obj@handle();
      
      obj.w = w;
      obj.h = h;
      
      obj.cx = cx;
      obj.cy = cy;
      
      obj.clickCallback = clickCallback;
      obj.description = description;
      
      obj.ax = ax;
      
      obj.tag = tag;
      
      obj.DEBUG = 0;
    end
    
    % Destructor
%     function delete(obj)
%       obj.clearHandles();
%     end
    
    % West position
    function [x] = west(obj,tmp)
      if nargin < 2
        x = obj.cx - obj.w/2;
      else
        obj.cx = tmp + obj.w/2;
      end
    end
    
    % South position
    function [y] = south(obj,tmp)
      if(nargin < 2)
        y = obj.cy - obj.h/2;
      else
        obj.cy = tmp + obj.h/2;
      end
    end
    
    % North position
    function [y] = north(obj,tmp)
      if(nargin < 2)
        y = obj.cy + obj.h/2;
      else
        obj.cy = tmp - obj.h/2;
      end
    end
    
    % East position
    function [x] = east(obj,tmp)
      if nargin < 2
        x = obj.cx + obj.w/2;
      else
        obj.cx = tmp-obj.w/2;
      end
    end
    
    % Delete handles
    function obj = clearHandles(obj)
      fn = fieldnames(obj.handles);
      if ~isempty(fn)
        for n=1:length(fn)
          delete(obj.handles.(fn{n}));
          obj.handles = rmfield(obj.handles,fn{n});
        end
      end
    end
    
    % Publish click callback
    function obj = publishClickCallback(obj,fun)
      if nargin < 2, fun = obj.clickCallback; end
      
      obj.clickCallback = fun;
      
      fn = fieldnames(obj.handles);
      for n=1:length(fn)
        % Get current handle
        hn = obj.handles.(fn{n});
        
        % Set click callback
        set(hn,'ButtonDownFcn',@obj.clickCallbackWrapper);
        
        % Enable mouse hover curser change
        iptSetPointerBehavior(hn, @(f, cp)set(f, 'Pointer', 'hand'));
      end
    end
    
    function clickCallbackWrapper(obj, handles, event)
      tmp = guidata(handles);
      tmp.lastClickedElement = obj;
      guidata(handles,tmp);
      obj.clickCallback(handles,event);
    end
    
    % Prepare plot
    function obj = preparePlot(obj,ax)
      if nargin < 2, ax = gca; end
      
      % Publish ax
      obj.ax = ax;
      
      % Clear handles
      obj.clearHandles();
      
      % Plot description
      obj.plotDescription();
    end
    
    % Plot description text under the element
    function obj = plotDescription(obj,description,ax)
      % Update description if necessary
      if nargin < 2, description = obj.description; end
      if nargin < 3, ax = obj.ax; end
      
      obj.description = description;
      
      % Remove old field
      if isfield(obj.handles, 'description')
        delete(obj.handles.description);
        obj.handles = rmfield(obj.handles,'description');
      end
      
      % Show text field
      if ~isempty(obj.description)
        obj.handles.description = text(obj.cx,obj.south+5,obj.description,'FontSize',10,'Parent',ax,'Interpreter','none');
        ext = get(obj.handles.description,'Extent');
        Viewer.BD.Element.refineTextPosition(obj.handles.description, obj.cx,obj.south-ext(4));
      end
    end
  end
  
  methods (Static)
    % Position text mor accurate
    function refineTextPosition(txtHandle, cx, cy)
      pos = get(txtHandle,'Position');
      ext = get(txtHandle,'Extent');
      mar = pos(1:2)-ext(1:2); % Margin
      set(txtHandle,'Position',[cx-ext(3)/2+mar(1) cy-ext(4)/2+mar(2)  0]);
    end
  end
    
end

