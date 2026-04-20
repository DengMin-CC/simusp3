function ch_y=lag(l_x,l_y,t)
%拉格朗日插值
%---------input---------
% l_x 插值节点（GPS时）,l_y 插值节点值
% t待差值点（GPS时）
%---------output--------
%ch_y插值后的值 
n=10;%拉格朗日插值阶数9次
ch_y=0;
for j=1:n
    p=1; %拉格朗日初值
    for i=1:n
        if i~=j
            p=p*(t-l_x(i))/(l_x(j)-l_x(i));%拉格朗日插值函数
        end
    end
    ch_y=ch_y+p*l_y(j);
end
end
