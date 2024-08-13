%%
uSplit  = ipPlot(ipSplit,'horizontal line luminance',[1 626],'no figure');
uRGB    = ipPlot(ipRGB,'horizontal line luminance',[1 626],'no figure');
uSplit2 = ipPlot(ipSplit2,'horizontal line luminance',[1 626],'no figure');


rgbSplit = ipGet(ipSplit,'srgb');
ieNewGraphWin; imagesc(rgbSplit);

rgbRGB = ipGet(ipRGB,'srgb');
ieNewGraphWin; imagesc(rgbRGB);

%%
start = 1500;

ieNewGraphWin;
plot(uSplit.pos(start:end),uSplit.data(start:end),'ko', ...
    uSplit2.pos(start:end),uSplit2.data(start:end),'k-'); 
grid on;
title('OVT 3-capture')

%%
ieNewGraphWin;
plot(uRGB.pos(start:end),uRGB.data(start:end),'ko',...
    uSplit2.pos(start:end),uSplit2.data(start:end),'k-'); 
grid on;
title('RGB')

%%