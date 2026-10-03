%{

Assing values for
xi = initial value independent variable
yi = initial value dependent variable array
h = calculation step size
xend = output interval

%}

derivs = @(x)(-2*x^3 + 12*x^2 - 20*x + 8.5);
% derivs = @(x,y)( 4*exp(.8*x)-.5*y );
% derivs = @(y) [y(1); -16.1*y(2)];

[xi,yi,h,xend] = deal(0,1,.5,4);

[y_final] = integrator(xi,yi,h,xend,derivs,"heun");
% plot(xpm,ypm)