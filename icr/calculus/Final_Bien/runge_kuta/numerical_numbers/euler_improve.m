%{
    y = initial value dependent variable
    xi = initial value independent variable
    xf = final value indenpendent variable
    dx = calculation step size
%}

[y,xi,xf,dx,xout]=deal();


[x,m,xpm, ypm] = deal(xi,0,x,y);

derivs = @(x,y)(dydx);

while true
    xend = x + xout;
    if xend > xf
        xend = xf;
        h = dx;
        integrator(x)
        m = m + 1;
        xpm = x;
        ypm = y;
    end
    if x >= xf
         break
    end
    disp(ypm)
end



function out = integrator(x,y,h,xend)
    while (xend - x < h)
           h = xend - x;
        
           y=ynew;    
    end
  end



function [ynew] = euler(x,y,h,dydx)
    ynew = y + dydx*h;
    x = x + h;
end

y = ej