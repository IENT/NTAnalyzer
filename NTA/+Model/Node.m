classdef Node < Model.Model
	
	methods
    %% Constructor
		function obj = Node(varargin)
			obj = obj@Model.Model(varargin{:});
    end
		
    %% Get stream
		function s = getStream(obj,varargin)
			% Get stream from input model
      s = obj.getInStreams();
      
      % A node with more than one input doesn't make sense and also if
      % there is no input model at all. Just return zeros. 
      if length(s) ~= 1
        s = obj.stream;
        return;
      end
      
      % Unwrap stream
      s = s{1};
    end
  end		
end
