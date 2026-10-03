function [xnew, ynew] = midpoint(x,y,h,derivs)
    
    if nargin(derivs)==1
        k2 = feval(derivs,x+h/2);
    else
        k1 = feval(derivs,x,y);
        ym = y + k1*h/2;
        k2 = feval(derivs,x+h/2,ym);
    end

    ynew = y +k2*h;
    xnew = x + h;
end

   