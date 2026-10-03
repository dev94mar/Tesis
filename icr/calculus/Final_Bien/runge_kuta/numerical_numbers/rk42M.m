function [xnew, ynew] = rk42M(x,y,h,derivs)

    k1 = feval(derivs,x,y);
    ym = y + k1*h/2;
    
    k2 = feval(derivs,x + h/2,ym);
    ym = y + k2*h/2;

    k3 = feval(derivs,x + h/2,ym);
    ye = y + k3*h;

    k4 = feval(derivs,x,ye);
    slope = (k1 + 2*(k2 + k3) + k4)/6;
    
    ynew = y + slope*h;
    xnew = x + h;

end

