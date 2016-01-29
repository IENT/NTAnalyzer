%% Gain

classdef Gain < Model.Model
	properties (SetAccess = private)
		gain; % scalar gain value
	end
	
	methods
    %% Constructor
		function obj = Gain(gain,varargin)
			obj = obj@Model.Model(varargin{:});
			obj.gain = gain;
    end
		
    
    %% Update streams
		function updateStream(obj)
      % Get all input streams
      s = obj.getInStreams();
      s = s{1};
      
      % Multiply
      obj.stream = s*obj.gain;
			
      % Notify output models
      updateStream@Model.Model(obj);
		end
	end	
end
