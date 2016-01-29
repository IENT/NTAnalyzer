% Jack (connector)
% Not clickable
classdef Jack < Viewer.BD.Element
  
  properties
    ratio = 0.4;
  end
  
  methods
    % Constructor
    function obj = Jack(varargin)
      obj@Viewer.BD.Element(varargin{:});
    end

    % Plot
    function obj = plot(obj,varargin)

      obj.preparePlot(varargin{:});
      
      % Plot circle
      obj.handles.outerCircle = rectangle('Position',[obj.west obj.south obj.w obj.h], ...
        'Curvature', [1 1], 'FaceColor',[1 1 1],...
        'Parent',obj.ax);
      
      % Draw smaller circle inside
      obj.handles.innerCircle = rectangle('Position',...
        [obj.west + obj.ratio*obj.w, obj.south + obj.ratio*obj.h,...
          (1-2*obj.ratio)*obj.w, (1-2*obj.ratio)*obj.h], ...
        'Curvature', [1 1], 'Parent',obj.ax);
      
      if ~isempty(obj.clickCallback)
        % Publish callback
        obj.publishClickCallback(obj.clickCallback);
      end
    end
  end
  
end

