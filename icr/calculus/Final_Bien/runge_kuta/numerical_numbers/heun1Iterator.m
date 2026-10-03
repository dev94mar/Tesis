function [xnew, ynew] = heun1Iterator(x,y,h,derivs)
    
    k1 = feval(derivs,x);
    ye = y + k1*h;
    k2 = feval(derivs,x+h);
    slope = mean([k1,k2]);
    ynew = y + slope*h;
    
    es=.01; ea=(abs((ye-ynew)/ye))*100;   
    if ea >= es
        error("Fail by error tolerance")
    end
    xnew = x + h;
end

