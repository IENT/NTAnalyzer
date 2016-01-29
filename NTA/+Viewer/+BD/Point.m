% Single point coordinate
classdef Point < Viewer.BD.Element
  
  methods
    % Constructor
    function obj = Point(varargin)
      obj@Viewer.BD.Element(varargin{:});
    end

    % Plot
    function obj = plot(obj,varargin)
      
      obj.preparePlot(varargin{:});
      
      % Plot point
%       obj.handles.point = line(obj.cx, obj.cy, 'Marker','x','Color','r',...
%         lineArguments{:},'Parent',ax);
      obj.handles.circle = rectangle('Position',[obj.west obj.south obj.w obj.h], ...
        'EdgeColor', [0 0 0], 'FaceColor', [0 0 0],...
        'Curvature', [1 1], 'Parent',obj.ax);
    end
  end
  
end

