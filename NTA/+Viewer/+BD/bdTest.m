% Block diagram test
function bdTest()
  close all;
  
  %% Parameter
  % Grid distance
  ux = 1;
  uy = 1;
  
  % Grid length
  Lx = 30;
  Ly = 10;
  
  
  %% Figure and axes
  fi = figure('Units','normalized','Position',[0,0,1,1],'menuBar','none');
  ax = axes('Parent',fi,'Position',[0,0,1,1],...
      'XTick',[],'YTick',[],'xcolor',[1 1 1],'ycolor',[1 1 1],... % make x-axis and y-axis disappear
      'XLim', [0,Lx], 'YLim',[0,Ly], 'DataAspectRatio',[1 1 1]);  % 

  % Plot grid
  plotGrid(ux, uy, Lx, Ly, ax);
  
  rectangle('Position',[6,1,18,8],'Curvature',[0.05 0.1])
  
  
  %% Blocks
  % line 1
  j1 = BlockDiagram.Jack(.5*ux,.5*uy, 1*ux,8*uy);
  plot(j1,ax);
 
  tp1 = BlockDiagram.Block('TP',ux,uy,0,j1.cy);
  tp1.west(j1.east+0.75*ux);
  plot(tp1,ax);

  ad1 = BlockDiagram.Block('AD 1', ux*1.5,uy,0,tp1.cy);
  ad1.west(tp1.east+ux);
  plot(ad1,ax);
  
  n1 = BlockDiagram.Node('1',0.33*ux,0.33*uy, ad1.east+4.5*ux,ad1.cy, @clickFun2);
  plot(n1,ax);
 
  % line 2
  j2 = BlockDiagram.Jack(.5*ux,.5*uy,j1.cx,j1.cy-2*uy);
  plot(j2,ax);
  
  tp2 = BlockDiagram.Block('TP',ux,uy,tp1.cx,j2.cy);
  plot(tp2,ax);
  
  ad2 = BlockDiagram.Block('AD 2', ux*1.5,uy,ad1.cx,j2.cy);
  plot(ad2,ax);
  
  n2 = BlockDiagram.Node('2',0.33*ux,0.33*uy, n1.cx,ad2.cy, @clickFun2);
  plot(n2,ax);
  
  % line 3 (digital)
  sq1 = BlockDiagram.Block('Sig.Q.1', ux*2,uy,ad1.east+2*ux,ad2.south-1.5*uy, @clickFun1);
  plot(sq1,ax);
  
  n3 = BlockDiagram.Node('3',0.33*ux,0.33*uy, n1.cx,sq1.cy, @clickFun2);
  plot(n3,ax);
  
  % line 4 (digital)
  sq2 = BlockDiagram.Block('Sig.Q.2', ux*2,uy,sq1.cx,sq1.south-1.5*uy, @clickFun1);
  plot(sq2,ax);
  
  n4 = BlockDiagram.Node('4',0.33*ux,0.33*uy, n1.cx,sq2.cy, @clickFun2);
  plot(n4,ax);
  
  % Interchangable stuff
  n5 = BlockDiagram.Node('5',0.33*ux,0.33*uy, n1.cx+10*ux,n1.cy, @clickFun2);
  plot(n5,ax);
  
  d1 = BlockDiagram.Block('10 T_a',1.5*ux,uy, n2.cx+5*ux, n2.cy);
  plot(d1,ax);
  
  p1 = BlockDiagram.Point(0,0,n1.cx+3*ux,n1.cy);
  p2 = BlockDiagram.Point(0,0,p1.cx,d1.cy);
  
  n6 = BlockDiagram.Node('6',0.33*ux,0.33*uy, n5.cx, n2.cy, @clickFun2);
  plot(n6,ax);
  
  
  %% Connections
  BlockDiagram.arrow([j1.east,j1.cy],[tp1.west,tp1.cy]);
  BlockDiagram.arrow([tp1.east,tp1.cy],[ad1.west,ad1.cy]);
  BlockDiagram.arrow([ad1.east,ad1.cy],[n1.west,n1.cy]);
  
  BlockDiagram.arrow([j2.east,j2.cy],[tp2.west,tp2.cy]);
  BlockDiagram.arrow([tp2.east,tp2.cy],[ad2.west,ad2.cy]);
  BlockDiagram.arrow([ad2.east,ad2.cy],[n2.west,n2.cy]);
  
  BlockDiagram.arrow([sq1.east,sq1.cy],[n3.west,n3.cy]);
  
  BlockDiagram.arrow([sq2.east,sq2.cy],[n4.west,n4.cy]);
  
  BlockDiagram.arrow([n1.east,n1.cy],[n5.west,n5.cy]);
  BlockDiagram.arrow([n1.east,n1.cy],[n5.west,n5.cy]);
  
  BlockDiagram.arrow([p1.cx p1.cy],[p2.cx p2.cy],'Length',0);
  BlockDiagram.arrow([p2.cx p2.cy],[d1.west d1.cy]);
  BlockDiagram.arrow([d1.east d1.cy],[n6.west n6.cy]);
%   BlockDiagram.arrow([n2.east,n2.cy],[d1.west,d1.cy]);
  
  %% Description test
  n1.plotDescription('KKF mit 5');
end


%% Click handlers
function clickFun1(hObject,eventData)
  msgbox('schnogo','Klick');
end
  
function clickFun2(hObject,eventData)
  msgbox('bogo','say what?');
end


function plotGrid(ux, uy, Lx, Ly, ax)

  
  Nx = round(Lx/ux);
  Ny = round(Ly/uy);
  
  for nx = 1:(Nx-1)
    h=line([nx nx],[0 Ny],...
      'LineStyle','-','Color',0.9*[1 1 1],...
      'Parent', ax);
  end
  
  for ny = 1:(Ny-1)
    line([0, Nx], [ny ny],...
      'LineStyle','-','Color',0.9*[1 1 1],...
      'Parent', ax);
  end
  
end