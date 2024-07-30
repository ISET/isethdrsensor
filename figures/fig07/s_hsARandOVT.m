%{
%% Here is a standard sensor ON Semi

sensorRGB = sensorCreate('ar0132at',[],'rgb');
sensorRGB = sensorSet(sensorRGB,'match oi',oiInput);
sensorRGB = sensorSet(sensorRGB,'exp time',expTime);
sensorRGB = sensorSet(sensorRGB,'noise flag',2);
sensorRGB = sensorCompute(sensorRGB,oiInput);

sensorWindow(sensorRGB,'gamma',0.3);

% Save out the RGB image
rgb = sensorGet(sensorRGB,'rgb');
imName = sprintf('ar0132atSensor.png');
imwrite(rgb,fullfile(isethdrsensorRootPath,'local',imName));

%{
% Have a close look, if you want.
sensorShowImage(sensorRGB,sensorGet(sensorRGB,'gamma'),true,ieNewGraphWin);
truesize
%}

%% Turn off the noise, recompute, and show the noise.


% No noise.
sensorRGB2 = sensorSet(sensorRGB,'noise flag',0);
sensorRGB2 = sensorSet(sensorRGB2,'name','no noise');
sensorRGB2 = sensorCompute(sensorRGB2,oiInput);
% sensorWindow(sensorRGB2,'gamma',0.3);

uDataRGB  = sensorPlot(sensorRGB,'volts hline',[1 whichLine],'no fig',true);
uDataRGB2 = sensorPlot(sensorRGB2,'volts hline',[1 whichLine],'no fig',true);

% The red channel
channel = 1;
x = uDataRGB.data{channel};
y = uDataRGB2.data{channel};
s  = mean(x,'all','omitnan');
s2 = mean(y,'all','omitnan');
peak = 0.98/max(x);

ieNewGraphWin; 
plot(uDataRGB.pos{1},(peak*x),'r-', ...
    uDataRGB2.pos{1},(peak*y)*(s/s2),'k-','LineWidth',2);
grid on;
xlabel('Position (um)')
ylabel('Relative volts');
title('1-capture (ar0132at)');
tmp = sprintf('rgb-%d-noise.pdf',whichLine);
exportgraphics(gcf,fullfile(isethdrsensorRootPath,'local',tmp));

%% Calculate how closely the measurements track the no noise values

% Assuming x and y are your data vectors
X = [ones(length(x), 1), x];  % Add a column of ones for the intercept
[b,~,~,~,stats] = regress(y, X);
fprintf('RGB R_squared" %f\n',stats(1));
%}

%{
ipRGB = ipCreate;
ipRGB = ipCompute(ipRGB,sensorRGB);
ipWindow(ipRGB,'render flag','rgb','gamma',0.25);
rgb = ipGet(ipRGB,'srgb');
fname = fullfile(isethdrsensorRootPath,'local','ip-ar0132at.png');
imwrite(rgb,fname);
%}