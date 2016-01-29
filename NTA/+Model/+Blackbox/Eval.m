classdef Eval
  properties
    Fs;
  end
  methods
    
    function obj=Eval(Fs)
      % design filters for a given sampling rate
      if(nargin < 1)
        obj.Fs = 44100;
      else
        obj.Fs = Fs;
      end
      % plot the impulse and frequency response of our filters
      obj.EvalAll(true);
      % print out filter coefficients for cpp file
      obj.PrintFilterCoeffsC();
    end
    
    function [a, b] = DesignFilters(obj,bb, showplot)
      if nargin < 3
        showplot = 0;
      end
      %% Filter coefficients
      % Convert delay length into samples
      dz500us = obj.getDelayVec(0.5e-3,obj.Fs);
      dz40us = obj.getDelayVec(4e-5,obj.Fs);   
      
      switch bb
        case 'LOW'
          % design a 10th order lowpass with 3kHz cutoff 
          [tmpb,tmpa] = butter(10,3e3/(obj.Fs/2),'low');
          b = {tmpb};
          a = {tmpa};
          
        case 'HIGH'
          % design a 10th order high-pass with 10kHz cutoff
          [tmpb,tmpa] = butter(10,10e3/(obj.Fs/2),'high');
          b = {tmpb};
          a = {tmpa};
        
        case 'IIR'
          % design a simple IIR filter 
          b = {0.014};
          a = {[1 dz40us -0.986]};
                  
        case 'FIR'
          % design a simple FIR filter
          b = {0.5*[1 dz500us 1 dz500us -1 dz500us -1 dz500us 1 dz500us 1 dz500us -1 dz500us -1]};
          a = {1};
          
        otherwise
          error('Wrong blackbox specified');
      end
      
      if (showplot)
        %% Input
        %s = randn(1,1e4); % white gaussian noise
        s = zeros(1,1024); s(1) = 1; % dirac
        
        %% Output
        g = cell(1,length(b));
        for n=1:length(b)
          g{n} = filter(b{n},a{n},s);
        end
        
        g = g{1};
        
        %% Correlation
        [phi_sg,lags] = xcorr(g,s);
        
        %% Power spectral density
        NFFT = 2^nextpow2(length(phi_sg)); % Next power of 2 from length of y
        Phi_sg = fft(phi_sg,NFFT)/length(phi_sg);
        f = obj.Fs/2*linspace(0,1,NFFT/2+1);
        
        %% Plot
        tau = lags/obj.Fs*1000;
        fi=figure;
        ax(1)=subplot(2,1,1,'Parent',fi);
        plot(ax(1),tau,phi_sg)
        xlabel(ax(1),'$\tau$ [ms]','Interpreter','LaTex','FontSize',14)
        title(ax(1),'$\varphi_{\mathrm{sg}}(\tau)$','Interpreter','LaTex','FontSize',14)
        ax(2) = subplot(2,1,2);
        plot(ax(2),f,2*abs(Phi_sg(1:NFFT/2+1)))
        xlabel(ax(2),'Frequency (Hz)','Interpreter','LaTex','FontSize',14)
        title(ax(2),'$\phi_{\mathrm{sg}}(f)$','Interpreter','LaTex','FontSize',14)
      end
    end
    
    function bb = mapNumberToSecretBlackBox(obj,index)
      index = round(index);
      if(index>103 || index < 100), error('Index not in range'); end    
      secretTable = {...
        100, 'LOW';
        101, 'HIGH';
        102, 'FIR';
        103, 'IIR';
        };
      
      for n=1:length(secretTable);
        if(index == secretTable{n,1})
          bb = secretTable{n,2};
          return;
        end
      end
    end
    
    
    function EvalAll(obj, showplot)
      all = [100,101,102,103];
      for index=all
        obj.DesignFilters(obj.mapNumberToSecretBlackBox(index),showplot);
      end
    end
    
    function PrintFilterCoeffsC(obj, varargin)
      if nargin < 2
        all = [100,101,102,103];
      else
        all = varargin{1};
      end
      coeff_a=[];
      coeff_b=[];
      num_a=[];
      num_b=[];
      count=0;
      for index=all
        [tmpa, tmpb]= obj.DesignFilters(obj.mapNumberToSecretBlackBox(index));
        count = count + 1;
        coeff_a{count}=tmpa;
        coeff_b{count}=tmpb;
        num_a{count}=cellfun(@length,tmpa);
        num_b{count}=cellfun(@length,tmpb);
      end
      
      amax_a1={};
      amax_b1={};
      
      for index=1:count
        amax_a1{end+1}=num_a{index}(1);
        amax_b1{end+1}=num_b{index}(1);
      end
      
      l1 = length(amax_a1);
      
      max_a1=max(cell2mat(amax_a1));
      max_b1=max(cell2mat(amax_b1));
      
      out_a1 = zeros(l1,max_a1);
      out_b1 = zeros(l1,max_b1);
      
      kl1=1;
      for index=1:count
        out_a1(kl1,1:num_a{index}(1))=cell2mat(coeff_a{index}(1));
        out_b1(kl1,1:num_b{index}(1))=cell2mat(coeff_b{index}(1));
        kl1 = kl1 + 1;
      end
      
      obj.WriteArrayCStyle('static int','num_a1',cell2mat(amax_a1));
      obj.WriteArrayCStyle('static int','num_b1',cell2mat(amax_b1));
      obj.WriteArrayCStyle('static double','coeff_a1',out_a1);
      obj.WriteArrayCStyle('static double','coeff_b1',out_b1);
      
    end
    
    function WriteArrayCStyle(obj,type,name,array)
      [m,n]=size(array);
      switch type
        case 'static int'
          outtype='%d';
        case 'static double'
          outtype='%f';
      end
      fprintf('\n');
      if (m>1)
        fprintf('%s %s[%d][%d]={',type,name,m,n);
      else
        fprintf('%s %s[%d]=',type,name,n);
      end
      for k=1:m
        fprintf('{');
        for i=1:n
          fprintf(outtype,array(k,i));
          if (i<n)
            fprintf(',');
          end
        end
        if (k<m)
          fprintf('},\n  ');
        end
      end
      if (m>1)
        fprintf('}};');
      else
        fprintf('};');
      end
      fprintf('\n');
    end
    
    function [d]=getDelayVec(obj,delayInS,Fs)
      d=zeros(1,round(delayInS*Fs)-1);
    end
    
  end
end