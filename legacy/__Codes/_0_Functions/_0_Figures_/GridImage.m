function GridImage(im)

im = im  - min(im(;));
im = im ./ max(im(;));

imshow(im)

hold on

M = size(im,1);
N = size(im,2);

for k = 1:2:M
    x = [1 N];
    y = [k k];
    plot(x,y,'Color','r','LineStyle','-');
    plot(x,y,'Color','r','LineStyle',':');
end

for k = 1:2:N
    x = [k k];
    y = [1 M];
    plot(x,y,'Color','r','LineStyle','-');
    plot(x,y,'Color','r','LineStyle',':');
end

hold off