%%sanity check x-y- distributions of data
function []=sanityCheck(dataset)

%%grab fixations for that dataset
fix=grabFixations(dataset);

if strcmp(dataset, 'Asher2013')
        aspectRatio=0.8;
elseif strcmp(dataset, 'Asher2009')
    aspectRatio=1;
else
        aspectRatio=0.75;
end

%%calculate saccade amplitudes
saccs = convertFixToSacc(fix,aspectRatio);
x=saccs((find(saccs(:,4)<1 & saccs(:,4)>-1 & saccs(:,1)~=1)),4);
y=saccs((find(saccs(:,5)<0.75 & saccs(:,5)>-0.75 & saccs(:,1)~=1)),5);


%%for the distributions - leave in ones outside the scene edges
%%plot x distribution
subplot(3,2,1)
hist(x,20)
title('x distribution')

%%plot y distribution
subplot(3,2,2)
hist(y,20)
title('y distribution')




saccs(:,6)=sqrt(((saccs(:,2)-saccs(:,4)).^2)+((saccs(:,3)-saccs(:,5)).^2));
%%plot saccade amplitude dsitributions
subplot(3,2,3)
hist(saccs(:,6))
title('saccade amplitude distribution')


%%plot saccade amplitudes by index but only do up to when there are 10
%%saccades (to avoid stupid error bars)

%calculate frequencies of saccade index
tbl = tabulate(saccs(:,1));
%find times where there are less than 10 saccades
remrefs=find(tbl(:,2)<10);
%make subset of data with only these cases
saccs2=saccs(saccs(:,1)<remrefs(1),:);
%plot sac amps across fixation index
subplot(3,2,4)
grpstats(saccs2(:,6),saccs2(:,1),0.05);
title('saccade amplitude with fixation index')



% Estimate a continuous pdf from the discrete data
%%just subset cases where x>-1 and x<1



[pdfx xi]= ksdensity(x);
[pdfy yi]= ksdensity(y);
% Create 2-d grid of coordinates and function values, suitable for 3-d plotting
[xxi,yyi]     = meshgrid(xi,yi);
[pdfxx,pdfyy] = meshgrid(pdfx,pdfy);
% Calculate combined pdf, under assumption of independence
pdfxy = pdfxx.*pdfyy; 
% Plot the results
subplot(3,2,5)
imagesc(pdfxy)
colormap('hot')
title('fixation plot')

subplot(3,2,6)
mesh(xxi,yyi,pdfxy)
colormap('hot')
set(gca,'XLim',[-1 1])
set(gca,'YLim',[-aspectRatio aspectRatio])
title('fixation surface plot')







end