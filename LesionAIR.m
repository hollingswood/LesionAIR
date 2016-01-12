clc
clear all
close all

%% Initialization
usrID = inputdlg('What is the user ID? ','User ID'); %Identify results
DataFolder = usrID{:};
dataDirPath = 'C:\Users\Tyer\Desktop\LesionAIR\Data\';
splashDirPath = 'Splash/';
mkdir(dataDirPath,DataFolder);
ResultsFolder = [dataDirPath,DataFolder];

figureHandle = figure('Name','LesionAIR Camera Preview'); % ,'Position', [80, 80, 400, 200]);
%hImage = imshow(['/Users/TylerWortman/Dropbox (MIT)/PhD Research/MATLAB/_LesionAIR Device/Splash/' num2str(floor(rand()*10)) '.jpg'],'Border','tight');
hImage = imshow([splashDirPath num2str(9) '.jpg'],'Border','tight');

txt = uicontrol('Style','text','Position',[0 0 926 60],'String','Initializing Lesionair and Treehopper Pins','FontSize',24,'FontName','Helvetica Neue','FontWeight','Light');
drawnow;

%Initialize PCB
Treehopper('open');
vBus = 4.94;

%Initialize Pins
Treehopper('makeAnalogIn',1); %Pressure Transducer, Analog Read, Pin 1
Treehopper('makeDigitalOut',6); %Vacuum Pump, Digital Out, Pin 6
Treehopper('digitalWrite', 6, false); %False/Low to Turn off Pump
Treehopper('makeDigitalOut',8); %Projector On/Off, Digital Out, Pin 8, True to turn off LED
Treehopper('digitalWrite', 8, false); %False/Low to Turn off LED
Treehopper('makePWM',2); %Projector Brightness, Increase Duty Cycle to Dim
Treehopper('pwmWrite',2,0); %0 = brightest, 1 = dimmest
Treehopper('makeDigitalOut',5); %Ring Light, Digital Out, Pin 5

%Initialize Button
Treehopper('makeDigitalOut', 10);
Treehopper('digitalWrite', 10, true); %Pin 3 is normally pulled high
 
Treehopper('makeDigitalOut', 9);
Treehopper('digitalWrite', 9, false);
 
Treehopper('makeDigitalIn', 3);

%Initialize Camera
set(txt,'String','Initializing Camera...');
drawnow;
vid = videoinput('gige', 1, 'Mono8');  %Initialize camera
src = getselectedsource(vid);
src.PacketDelay = 1.9662e+04; %Set Packet Delay
src.PacketSize = 9005; %Set Packet Size
src.Gain = 0; %Set ISO Gain
src.AcquisitionFrameRateAbs = 5; %Set Frame Rate
%src.ExposureTimeAbs = 60000; %*** BEST FOR STRUCTURED LIGHT
src.ExposureTimeAbs = 20000; %*** BEST FOR VISIBLE LIGHT
%imaqmem(3000000000); %Set reserved memory
handles.video.FramesPerTrigger = Inf; % Capture frames until we manually stop it

%% Centering of Device
set(txt,'String','Turning on Ring Light');
drawnow;
Treehopper('digitalWrite',5,true);

set(txt,'String','Turning on Live Video Feed for Preview');
drawnow;


%vidRes = vid.VideoResolution;
%nBands = vid.NumberOfBands;
%hImage = image( zeros(vidRes(2), vidRes(1), nBands) );
% Display the video data in your GUI.
% drawnow;
% hold on;
% r= 20;
% x = 1388/2;
% y = 1038/2;
% th = 0:pi/50:2*pi;
% xunit = r * cos(th) + x;
% yunit = r * sin(th) + y;
set(txt,'String','Center Image over the Region of Interest. Press Button to Start');
% plot(xunit, yunit,'LineWidth',3);
preview(vid, hImage);
uicontrol('Style','text','Position',[450 450 8 8],'String','','BackgroundColor','r');
uicontrol('Style','text','Position',[450 350 8 8],'String','','BackgroundColor','r');
uicontrol('Style','text','Position',[550 350 8 8],'String','','BackgroundColor','r');
uicontrol('Style','text','Position',[550 450 8 8],'String','','BackgroundColor','r');
drawnow;

%% Start
    while Treehopper('digitalRead', 3) == 1 %When button is pressed Pin 3 goes low
    pause(0.1);
    end
   
set(txt,'String','Turning off Ring Light');
drawnow;
Treehopper('digitalWrite',5,false);

%stoppreview(vid);
%closepreview(vid);

%% Data Collection
Pressure = []; %Initialize Pressure Variable

for i=1:6
    set(txt,'String',['Recording Data for Iteration ' num2str(i)]);
    drawnow;
    
    %Structured Light Image
    disp('Ring Light Off');
    Treehopper('digitalWrite',5,false);
    disp('Projector On');
    Treehopper('digitalWrite', 8, true);
    disp('Capturing Structured Light Image');
    src.ExposureTimeAbs = 150000; %%% CODE TO CAPTURE IMAGE Fully bright LED = 80000
    pause(0.5);
    SLimg=getsnapshot(vid);
    imwrite(SLimg,[ResultsFolder '/' usrID{:} '_SL_' num2str(i) '.png'],'png');
    disp('Projector Off');
    Treehopper('digitalWrite', 8, false);
    
    %Visible Light Image
    disp('Ring Light On');
    Treehopper('digitalWrite',5,true);
    disp('Capturing Visible Light Image');
    src.ExposureTimeAbs = 20000;%%%CODE TO CAPTURE IMAGE
    pause(0.5);
    VLimg=getsnapshot(vid);
    imwrite(VLimg,[ResultsFolder '/' usrID{:} '_VL_' num2str(i) '.png'],'png');
    
    %Record Pressure
    disp('Recording Pressure');
    PressureVoltage(i) = Treehopper('analogReadVoltage',1); %Record Ambient Pressure, Value = 0-5
    Pressure(i) = (PressureVoltage(i)/vBus)*1013.25; %Normalize Pressure Value = 0-1 %Conversion to millibars
    disp(['Pressure is: ' num2str(Pressure(i))]);
    
    %Apply 20mbar Vacuum
    disp('Vacuum Pump On');
    Treehopper('digitalWrite',6,true)
    while ((Treehopper('analogReadVoltage',1)/vBus)*1013.25)>(Pressure(1)-20*(i))
        set(txt,'String',['Current Pressure: ' num2str((Treehopper('analogReadVoltage',1)/vBus)*1013.25)]);
        drawnow;
        pause(0.1);
    end
    %pause(3.5);
    disp('Vacuum Pump Off');
    Treehopper('digitalWrite',6,false)
    
    %pause(0.1);
end

%% Finish
disp('Ring Light Off');
Treehopper('digitalWrite',5,false);
save([ResultsFolder '/' usrID{:} '_Pressure.txt'],'Pressure','-ascii','-tabs') %Save Pressure Readings to Text File
set(txt,'String','Terminating connection to LesionAIR');
drawnow;
closepreview(vid);
close all;
Treehopper('close');
clear vid;
disp('Displaying Recorded Data')

VL1 = imread([ResultsFolder '/' usrID{:} '_VL_1.png']);
SL1 = imread([ResultsFolder '/' usrID{:} '_SL_1.png']);
L1 = [VL1 SL1];

VL2 = imread([ResultsFolder '/' usrID{:} '_VL_2.png']);
SL2 = imread([ResultsFolder '/' usrID{:} '_SL_2.png']);
L2 = [VL2 SL2];

VL3 = imread([ResultsFolder '/' usrID{:} '_VL_3.png']);
SL3 = imread([ResultsFolder '/' usrID{:} '_SL_3.png']);
L3 = [VL3 SL3];

VL4 = imread([ResultsFolder '/' usrID{:} '_VL_4.png']);
SL4 = imread([ResultsFolder '/' usrID{:} '_SL_4.png']);
L4 = [VL4 SL4];

VL5 = imread([ResultsFolder '/' usrID{:} '_VL_5.png']);
SL5 = imread([ResultsFolder '/' usrID{:} '_SL_5.png']);
L5 = [VL5 SL5];

VL6 = imread([ResultsFolder '/' usrID{:} '_VL_6.png']);
SL6 = imread([ResultsFolder '/' usrID{:} '_SL_6.png']);
L6 = [VL6 SL6];

figure('Name','LesionAIR Images','Position', [50, 30, 1100, 750]);
subplot_tight(3,2,1,.01)
imshow(L1);
title('Vacuum Pressure = 0.0 mbar','FontSize',18,'FontWeight','bold')
subplot_tight(3,2,2,.01)
imshow(L2);
title(['Vacuum Pressure = ' num2str(Pressure(1)-Pressure(2),'%.1f') ' mbar'],'FontSize',18,'FontWeight','bold')
subplot_tight(3,2,3,.01)
imshow(L3);
title(['Vacuum Pressure = ' num2str(Pressure(1)-Pressure(3),'%.1f') ' mbar'],'FontSize',18,'FontWeight','bold')
subplot_tight(3,2,4,.01)
imshow(L4);
title(['Vacuum Pressure = ' num2str(Pressure(1)-Pressure(4),'%.1f') ' mbar'],'FontSize',18,'FontWeight','bold')
subplot_tight(3,2,5,.01)
imshow(L5);
title(['Vacuum Pressure = ' num2str(Pressure(1)-Pressure(5),'%.1f') ' mbar'],'FontSize',18,'FontWeight','bold')
subplot_tight(3,2,6,.01)
imshow(L6);
title(['Vacuum Pressure = ' num2str(Pressure(1)-Pressure(6),'%.1f') ' mbar'],'FontSize',18,'FontWeight','bold')
