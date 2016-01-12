%Initialize PCB
%Treehopper('open');

%Initialize Pins
Treehopper('makeAnalogIn',1); %Pressure Transducer, Analog Read, Pin 1
Treehopper('makeDigitalOut',6); %Vacuum Pump, Digital Out, Pin 6
Treehopper('digitalWrite', 6, false); %True/High to Turn off Pump
Treehopper('makeDigitalOut',8); %Projector On/Off, Digital Out, Pin 8, True to turn off LED
Treehopper('digitalWrite', 8, true); %True/High to Turn off LED
%Treehopper('digitalWrite', 8, false); %Turn On Projector LED
Treehopper('makePWM',2); %Projector Brightness, Increase Duty Cycle to Dim
Treehopper('makeDigitalOut',5); %Ring Light, Digital Out, Pin 5
%Treehopper('digitalWrite', 5, true); %Turn on Ring Light

%Initialize Button
Treehopper('makeDigitalOut', 10);
Treehopper('digitalWrite', 10, true); %Pin 3 is normally pulled low
 
Treehopper('makeDigitalOut', 9);
Treehopper('digitalWrite', 9, false);
 
Treehopper('makeDigitalIn', 3);

disp('Waiting for Button Press to Start...');
    while Treehopper('digitalRead', 3) == 1 %When button is pressed Pin 3 goes LOW
    end


figure
title('LESIONAIR PRESSURE')
xlabel('Time (s)')
ylabel('Pressure (mbar)')
Treehopper('digitalWrite', 6, true);
for i=1:20
x(i)=Treehopper('analogReadVoltage',1)/5*1013.25;
plot(x)
drawnow
pause(0.5);
end
Treehopper('digitalWrite', 6, false);
for i=20:40
x(i)=Treehopper('analogReadVoltage',1)/5*1013.25;
plot(x)
drawnow
pause(0.5);
end

