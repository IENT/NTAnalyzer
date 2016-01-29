%% InputJack
% calls a given handle to fetch input stream

classdef InputJack < Model.Model
  properties
    inputStreamHandle
  end
  methods
    %% Constructor
    function obj = InputJack(handle,varargin)
      % Parent constructor
      obj = obj@Model.Model(varargin{:});
      
      % Set handle to fetch input stream
      obj.inputStreamHandle = handle;
    end
    
    %% Get stream
    % Input stream function called by nodes: pass tag to identify channel
    function s = getStream(obj)
      s = obj.inputStreamHandle(obj.tag);
    end
  end
end