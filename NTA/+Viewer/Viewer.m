%% Viewer base class
classdef Viewer < handle

    properties
        hController = []; % controller
        handles = struct(); % all handles regarding MATLAB graphics
        tr = []; % language translator
        isOpen = false; % open flag
    end
    
    methods
      %% Constructor
      function obj = Viewer(c, tr)
				obj@handle();

				obj.hController = c;
        obj.tr = tr;
      end
      
      %% Destructor
      function delete(obj)
        if ~isempty(obj.handles) && isfield(obj.handles,'fig')
          delete(obj.handles.fig);
        end
      end

      %% Handler
      function CloseRequestHandler(obj,handle,event) %#ok<INUSD>
        obj.isOpen = false;
        delete(obj.handles.fig)
      end
    end
end
