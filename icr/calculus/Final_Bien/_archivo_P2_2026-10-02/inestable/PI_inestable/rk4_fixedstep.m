function [t, x] = rk4_fixedstep(f, tspan, x0, h)
    t = tspan(1):h:tspan(2);
    x = zeros(length(t), length(x0));
    x(1,:) = x0;

    for k = 1:length(t)-1
        k1 = f(t(k), x(k,:)');
        k2 = f(t(k) + h/2, x(k,:)' + h*k1/2);
        k3 = f(t(k) + h/2, x(k,:)' + h*k2/2);
        k4 = f(t(k) + h,   x(k,:)' + h*k3);

        x(k+1,:) = x(k,:) + h*(k1 + 2*k2 + 2*k3 + k4)'/6;
    end
end
