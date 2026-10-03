function [tnew, ynew] = rk4(t0,y0, h,odefun)

    % Calculate the four intermediate slopes
    k_1 = odefun(t0, y0);   
    k_2 = odefun(t0 + 0.5 * h, y0 + 0.5 * h * k_1);
    k_3 = odefun(t0 + 0.5 * h, y0 + 0.5 * h * k_2);
    k_4 = odefun(t0 + h, y0 + h * k_3);

    % Calculate the next value of y using the weighted average
    ynew = y0 + (h / 6) * (k_1 + 2 * k_2 + 2 * k_3 + k_4);
    tnew = t0 + h;
end
