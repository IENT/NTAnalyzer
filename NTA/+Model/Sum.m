%% Sum block
% summation of multiple node's signals
classdef Sum < Model.Model
	
	methods    
    %% Constructor
		function obj = Sum(varargin)
			obj = obj@Model.Model(varargin{:});
    end
		
    
    %% Update streams
		function updateStream(obj)
      
      % Get all input streams
      s = obj.getInStreams();
      
      % Sum them up!
      % Threre should be at least one input stream ...
      obj.stream = zeros(size(s{1}));
      for n=1:length(s)
        obj.stream = obj.stream + s{n};
      end
			
      % Notify output models
      updateStream@Model.Model(obj);
		end
	end	
end
