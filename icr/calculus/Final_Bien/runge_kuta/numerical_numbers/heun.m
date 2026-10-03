function [xnew, ynew] = heun(x,y,h,derivs)
    
    if nargin(derivs)==1
        k1 = feval(derivs,x);
        k2 = feval(derivs,x+h);
    else
        k1 = feval(derivs,x,y);
        ye = y + k1*h;
        k2 = feval(derivs,x+h,ye);
    end

    slope = mean([k1,k2]);
    ynew = y + slope*h;
    xnew = x + h;

end