function [Io]=imhist3(I,n)
%imhist3(I) displays a histogram for the intensity 3D image I 
%imhist3(I,n) displays a histogram for the intensity 3D image I. n is the
%number of bins in the histogram
%imhist3(X,map) displays a histogram for the indexed 3D image X and map is 
%colormap map 
m=size(I);
I=reshape(I,m(1)*m(2)*m(3),1);
if (nargout == 0)
    if (nargin == 1) plot(imhist(I)); else plot(imhist(I,n)); end
else
    if (nargin == 1) Io=imhist(I);   else  Io=imhist(I,n);   end
end
