function [ynew,xpm,ypm] = integrator(t, y, h, xend, derivs,method)
%{

Assing values for
xi = initial value independent variable
yi = initial value dependent variable
h = calculation step size
xend = output interval

%}

m=2;
size = (xend-0)/h;
xpm = zeros(size,1);
ypm = zeros(size,2);
xpm(1)=t;
ypm(1,:)=1;

switch method
    case 'euler'
        method = @euler;

    case 'midpoint'
        method = @midpoint;
        
    case 'heun'
        method = @heun;
       
    case 'heun1Iterator'
        method = @heun1Iterator;

    case 'rk4'
        method = @rk4;
        
    otherwise
        error('Unsupported method. Available methods: euler, midpoint, heun,heun1Iterator,rk4');
end
tic
    while t < xend
        % Adjust step size if overshooting xend
        if t + h > xend
            h = xend - t;
        end
    
        % Compute the next step using Euler method
        [t,y] = method(t, y, h, derivs);
        xpm(m) = t;
        ypm(m) = y;
        m = m + 1;
    end
toc
% Return the final value of y
ynew = y;
xpm = xpm(1:m-1);
ypm = ypm(1:m-1);
end