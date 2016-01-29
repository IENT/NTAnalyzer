function INSTALL()

  % Copy example.ini to settings.ini
  fprintf('\n\n\nNTAnalyzer Installation Routine\n\n\n')

  if ~isunix, 
    fprintf('TODO-List:\n-\tPlease install ASIO drivers for your sound card\n-\tSelect ASIO in MATLAB Preferences -> DSP System Toolbox\n-\tRoute DAW channels 1:4 to outputs 1:4\n\n');
    input('Please read the above lines and press ENTER afterwards :)')
  end

  disp('Copying .ini-file');
  copyfile('example.ini','settings.ini')

  if exist('state.mat','file')
    delete 'state.mat'
  end

%   % Set MATLABs character encoding to utf-8
%   disp('Setting Character Encoding to UTF-8');
%   slCharacterEncoding('UTF-8')

  % Compile blackbox
  current = pwd;
  cd('+Model/+Blackbox');
  if exist('filter_call','file')~=3
    disp('Compiling blackbox filter');
    try
      mex 'filter_call.cpp';
    catch e
      disp(['mex error: ' e.message])
    end
  end
  
  % Cleanup
  disp('Cleaning up');
%   if exist('filter_call.cpp','file')
%     delete 'filter_call.cpp';
%   end
%   if exist('Eval.m','file')
%     delete 'Eval.m';
%   end
  if exist('state.mat','file')
    delete 'state.mat';
  end
  cd(current);
  
  % Delete this file
%   delete 'INSTALL.m';
end