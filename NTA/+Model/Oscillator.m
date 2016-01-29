%% Oscillator
% digital signal source
classdef Oscillator < Model.Model
  properties
    mode
    freq
    amp
    duty
    phase
    noiseAmp
  end
  
  methods
    %% Constructor
    function obj = Oscillator(mode,freq,amp,duty,noiseAmp,varargin)
      obj = obj@Model.Model(varargin{:});
      if nargin < 5, noiseAmp = 0.1; end
      if nargin < 4, duty = 0.25; end
      if nargin < 3, amp = 0.1; end
      if nargin < 2, freq = 440; end
      if nargin < 1, mode = 'const'; end
      
      obj.freq = freq;
      obj.amp = amp;
      obj.mode = mode;
      obj.phase = 0;
      obj.duty = duty;
      obj.noiseAmp = noiseAmp;
      
    end
    
    
    %% Update stream
    function updateStream(obj)
      a = obj.amp;
      switch obj.mode
        case 'const'
          tmp = a*ones(length(obj.stream),1);
        case 'tri' 
          phaseVec = obj.updatePhaseVec();
          tmp = a*2*(abs(phaseVec/pi-1) - 0.5);
        case 'rect' % rect signal
          phaseVec = obj.updatePhaseVec();
          val = 1.*(phaseVec<=2*pi*obj.duty)-1.*(phaseVec>2*pi*obj.duty);
          tmp = a.*val;
        case 'sine' % sine wave
          phaseVec = obj.updatePhaseVec();
          tmp = a*sin(phaseVec);
        case 'bin_rand' % binary random
          val = obj.noiseAmp*2.*(randn(length(obj.stream),1)>0)-1;
          tmp = val;
        case 'gauss_noise' % Gaussian distribution
          tmp = obj.noiseAmp*randn(length(obj.stream),1);
        case 'uni_noise' % Uniform distribution
          smin = -obj.noiseAmp;
          smax = obj.noiseAmp;
          tmp = smin + (smax-smin).*rand(length(obj.stream),1);
        case 'data_signal'
          obj.freq = 1000;
          phase0 = obj.phase; % initial phase
          [~ ,phaseInc] = obj.updatePhaseVec(); % update phase
          T = round(obj.Fs/obj.freq); % samples per cycle
          N = ceil(length(obj.stream)/T)+1; % number of rects (a little bit more)
          coeffs = (4.*(randn(N,1)>0)-1)/3; % random coefficients
          tmp = reshape(repmat(coeffs,1,T)',1,[]); % generate rects
          
          % Shift rects according to phase offset (estimated ...)
          Noffset = length(0:phaseInc:phase0);
          tmp(1:Noffset) = [];
          
          % Cut to buffer size
          tmp = obj.noiseAmp*tmp(1:length(obj.stream))';
        otherwise
          tmp = zeros(length(obj.stream),1);
      end
      obj.stream = tmp;
      
      % Notify output models
      updateStream@Model.Model(obj);
    end
    
    %% Update phase
    function [phaseVec,phaseInc] = updatePhaseVec(obj)
      phaseInc = 2*pi*obj.freq/obj.Fs;
      phaseVec = (obj.phase + (1:length(obj.stream)).*phaseInc)';
      phaseVec = mod(phaseVec,2*pi);
      obj.phase = phaseVec(end);
    end
    
  end
  
end