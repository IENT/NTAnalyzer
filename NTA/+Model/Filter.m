%% Filter

classdef Filter < Model.Model
  properties (SetAccess = private)
    coef = struct();
    lastFilterStates = [];
  end
  
  methods
    %% Constructor
    function obj = Filter(b,a,varargin)
      % Parent constructor
      obj = obj@Model.Model(varargin{:});
      
      % Filter coefficients
      obj.coef.b = b;
      obj.coef.a = a;
      
      % Last filter states
      obj.lastFilterStates = zeros(max(length(b),length(a))-1,1);
    end
    
    
    %% Update stream by filtering
    function updateStream(obj)
      % Get input stream
      s = obj.getInStreams();
      if length(s) > 1, error('Filter can only handle one input!'); end
      s = s{1};
      
      % Filter
      [obj.stream ,obj.lastFilterStates] = ...
        filter(obj.coef.b, obj.coef.a, s, obj.lastFilterStates);
      
      % Notify output models
      updateStream@Model.Model(obj);
    end
    
  end
end
