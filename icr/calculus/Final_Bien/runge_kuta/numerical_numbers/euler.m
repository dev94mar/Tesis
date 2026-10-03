% function [xnew, ynewi] = euler(x,y,h,derivs)
% 
%     n = length(derivs);
%     [k1i, ynewi] = deal(zeros(1,n));
% 
%     if nargin(derivs)==1
%         k1i=arrayfun(derivs);    
%     else
%         for i=1:n
%             k1i(i,1) = feval(derivs(i,1),x,y);
%         end   
%     end
% 
%     for i=1:n
%             ynewi(i,1) = y + k1i(i,1)*h;
%     end 
%     xnew = x + h;
% 
% end

function [xnew, ynewi] = euler(x, y, h, derivs)
    n = size(y, 1);  % Assuming y is a column vector with multiple states
    m = size(y, 2);  % Number of different initial conditions (columns)

    % Preallocate output arrays
    k1i = zeros(n, m);
    ynewi = zeros(n, m);

    % Evaluate the derivatives for each column in y
    if nargin(derivs) == 1
        % If derivs is a function handle that works for a single input
        for j = 1:m
            k1i(:, j) = derivs(y(:, j));  % Apply derivs for each column of y
        end
    else
        % Assuming derivs is a function handle that accepts x, y as input
        for j = 1:m
            k1i(:, j) = feval(derivs, x, y(:, j));  % Evaluate for each column vector
        end
    end

    % Euler's method update: ynew = y + h*k1i
    ynewi = y + h * k1i;  % Element-wise update

    % Update x
    xnew = x + h;
end
