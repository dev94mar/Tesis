% set integration range
[xi , xf ] = deal(0,4);

% initialize variables
[x,y] = deal(xi,1);

% set step size and determine number of calculations steps
dx = .0001; nc = (xf-xi)/dx;
for i = 1:nc
    dydx = -2*x^3+12*x^2-20*x+8.5;
    y = y + dydx*dx;
    x = x + dx;
    fprintf('%.4f %.4f\n ',x,y)
end
