% Block with bounding box and a text field
classdef Block < Viewer.BD.Element
  
  properties
    txt = '';
  end
  
  methods
    % Constructor
    function obj = Block(txt,varargin)
      obj@Viewer.BD.Element(varargin{:});
      obj.txt = txt;
    end

    % Plot
    function obj = plot(obj,ax,rectArguments,textArguments)
      if(nargin < 2), ax = gca; end
      if(nargin < 3), rectArguments = {}; end
      if(nargin < 4), textArguments = {}; end
      
      obj.preparePlot(ax);
      
      % Plot rectangle
      obj.handles.rect = rectangle('Position',[obj.west() obj.south() obj.w obj.h], ...
        'FaceColor',[1 1 1],...
        'Parent',ax, rectArguments{:});

      % Display text
      if(~isempty(obj.txt))        
        obj.handles.text = text(obj.cx,obj.cy,obj.txt,...
          'Interpreter','none',...
          'VerticalAlignment','middle',...
          'HorizontalAlignment','center',...
          'FontSize',10,...
          'Parent',ax,textArguments{:} ...
        );

        % Refinement of text position
        Viewer.BD.Block.refineTextPosition(obj.handles.text,obj.cx,obj.cy);
        
        % Debug: Mark text background
        if(obj.DEBUG)
          set(obj.handles.text,'BackgroundColor',[.7 .9 .7]);
        end
                
      end
      
      % Mark center point if debug is on
      if(obj.DEBUG)
        obj.handles.centerMarker = line(obj.cx, obj.cy, 'Marker','x', 'Color','r','Parent',ax);
      end
      
      % Publish callback
      if(~isempty(obj.clickCallback))
        obj.publishClickCallback(obj.clickCallback);
        set(obj.handles.rect, 'EdgeColor', [0 0 1]);
      end
    end
    
  end
  
end

