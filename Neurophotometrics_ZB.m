%% Import data:
%Import the data as a numeric matrix where time in on the first column and
%the signals are in all subsequent columns to the right.
%The following code assumes recording sessions should produce 3 csv files (maybe more depending on
%experiment: (1) rawdata; contains photometry data, (2) time; should be a
%vector of time, here we have it as ms in 'time of day', (3) keydown file
%with timestamps. 

%The time and keydown files get imported as a numeric matrix.
% The photometry data get imported as a table. We import as:
% table name: AnimalID, and the columns 0G or 1G (whichever region you're
% recording fm) and change its name to signal.

B4205_refeedchow.time = B4205_refeedchow_time;
FP.rawdata(:,1) = B4205_refeedchow.time(10:end); 
FP.rawdata(:,2) =  B4205_refeedchow.signal(10:end);
%Assign the first time data point of the new table to startpoint.
startpoint = FP.rawdata(1,1);

B4205_refeedchow_keydown = (B4205_refeedchow_keydown - startpoint) ./ 1000;

%Here we normalize the keydown time values to start at zero and convert
%them to seconds, they come in ms originally. 

%Here we do the same thing but for the time column of our data. 
FP.rawdata(:,1) = (FP.rawdata(:,1) - startpoint)./1000; 


%% De Interleaving
    %%%BEFORE Proceeding to next step, check that #of isosbestic are same
        %if not, delete last row of isosbestic

%FP.calcium_dependent(:,1) = downsample(FP.rawdata(:,1),2);
%FP.calcium_dependent(:,2) = downsample(FP.rawdata(:,2),2);
FP.calcium_dependent(:,1) = downsample(FP.rawdata(2:end,1),2); 
FP.calcium_dependent(:,2) = downsample(FP.rawdata(2:end,2),2);

%FP.isosbestic(:,1) = downsample(FP.rawdata(2:end,1),2); 
%FP.isosbestic(:,2) = downsample(FP.rawdata(2:end,2),2);
FP.isosbestic(:,1) = downsample(FP.rawdata(:,1),2);
FP.isosbestic(:,2) = downsample(FP.rawdata(:,2),2);

f3 = figure;

 subplot(2,1,1)
 plot(FP.calcium_dependent(:,1),FP.calcium_dependent(:,2),'b')
 
 subplot(2,1,2)
 plot(FP.isosbestic(:,1),FP.isosbestic(:,2),'r')
 
 f6 = figure;
 
yyaxis left
plot(FP.calcium_dependent(:,1),FP.calcium_dependent(:,2),'b')
yyaxis right 
plot(FP.isosbestic(:,1),FP.isosbestic(:,2),'r');
%xline(FP.inj);


 
 %% Methods of neural data processing: 
 
 % If going to use mutant control sensors, go to MUT Normalizing section

 %Method 1: Substracting a running average over a long period of time from
%your data. This works well -- for quick and dirty tests -- but is a bit of
%a hack. It also tends to fail if you have shorter recordings and higher
%SNR. ie Your recording in fiber 2. Let's use that as an example for the
%different methods.


f4 = figure;
subplot(5,1,1)
plot(FP.calcium_dependent(:,1),FP.calcium_dependent(:,2));
title('Deinterleaved Raw Data')
xlabel('Time of day in total ms')


subplot(5,1,2)
plot(FP.calcium_dependent(:,1),FP.calcium_dependent(:,2)-smooth(FP.calcium_dependent(:,2),5455));
title('Linearize by Smoothing')
xlabel('Time of day in total ms')

ylabel('F')


%Another method is to fit the data with a biexponential and subtract that
%fit from the data. This is nicer, since it is based on biology (bleaching
%is monoexponential + bleaching of fiber / heat mediated LED decay gives
%you the second exponential.

%The fiber bleaching + heat mediated decay can be minimized experimentally
%by "pre bleaching" the fiber and pre-heating the LED (you can do this all
%at once -- just set the light power to 100% for ~10 minutes before your
%experient while you are getting everything else set up.)

subplot(5,1,3)
temp_fit = fit(FP.calcium_dependent(:,1),FP.calcium_dependent(:,2),'exp2');
plot(FP.calcium_dependent(:,1),FP.calcium_dependent(:,2)-temp_fit(FP.calcium_dependent(:,1)));
title('Linearize by Fitting with Biexponential')
xlabel('Time of day in total ms')
ylabel('F')


% You can also fit, scale, and subtract the isosbestic signal from the
% calcium dependent signal. This is probably the "best" of the three
% methods desribed here -- as it is less affected by having good signal (ie
% the former 2 methods get wonky when your SNR is super high and your
% recording is short -- as it starts to fit the signal, rather than the
% slow decay, which is bad news bears)

subplot(5,1,4)
%fit isosbestic
temp_fit = fit(FP.calcium_dependent(:,1),FP.isosbestic(:,2),'exp2'); %note, in this case, I am ignoring the first 2000 points where there is this weird fast decay to get a better fit. experimentally, i normally set things up so this isn't an important time in the recording / animal is habituating.
%scale fit to calcium dependent data
fit2 = fitlm(temp_fit(FP.calcium_dependent(:,1)),FP.calcium_dependent(:,2));
%calculate a crude dF/F by subtracting and then dividing by the fit
figure(2)
subplot(3,1,3)
plot(FP.calcium_dependent(:,1),100*(FP.calcium_dependent(:,2)-(fit2.Fitted))./(fit2.Fitted))
xlabel('Time (seconds)')
ylabel('dF/F (%)')
title('A5521 CA1 - processed and traces subtracted')


FP.corrected_data = FP.calcium_dependent(:,1),100*(FP.calcium_dependent(:,2)-(fit2.Fitted))./(fit2.Fitted);
%NOTE: To get a normalized measurement (ie dF/F) you will need to know what
%the background is. For example, if you subtracted this fit from the raw
%data and then divided by the fit -- it would look super wonky -- as you
%are subtracting numbers above and below 0.

%One way to try and get at this, is record for a second without any
%excitation lights on. The signal will never be 0 -- but this will be a
%low-end of what your background signal is. True "background" would be your
%recording with the excitation lights on when no neurons are active (which
%is hard to get). The former works great.

%If your data are clean, the last method is probably the best (imho) -- but
%there is an issue. We now have dF/F values that are less than 0 which
%can't happen. Stupid fix is to add the absolute value of the lowest number
%to the entire vector. Best method is to have some estimate of background
%subtraction.

%For argument's sake, let's say the background for the isosbestic signal
%was 5000.
subplot(5,1,4)
FP.fakebackground =0;
%fit isosbestic
temp_fit = fit(FP.calcium_dependent(:,1),FP.isosbestic(:,2),'exp2'); %note, in this case, I am ignoring the first 2000 points where there is this weird fast decay to get a better fit. experimentally, i normally set things up so this isn't an important time in the recording / animal is habituating.
%scale fit to calcium dependent data
fit2 = fitlm(temp_fit(FP.calcium_dependent(:,1)),FP.calcium_dependent(:,2));
%calculate a crude dF/F by subtracting and then dividing by the fit

plot(FP.calcium_dependent(:,1),100*(FP.calcium_dependent(:,2)-((fit2.Fitted)-FP.fakebackground))./(fit2.Fitted-FP.fakebackground))
xlabel('Time of day in total ms')
ylabel('dF/F (%)')
title('Linearizing + Normalizing Using Isosbestic + Background Subtracting')


%Now, if the ultimate goal is to show short sections of data chopped up
%around an event, then it doesn't make a whole heap of difference which
%method you use. In most cases, even uncorrected data, over 30 second
%segments, looks fine at a shorter time scale (since bleaching occurs over
%many minutes). However, it is good practice + necessary if you want to say
%something like "signal later on in the trial was of a different magnitude
%than signal earlier in the trial."

FP.corrected_data(:,1) = FP.calcium_dependent(:,1); %we'll keep the time vector in the first column to make things easier



temp_fit = fit(FP.calcium_dependent(:,1),FP.isosbestic(:,2),'exp2'); %note, in this case, I am ignoring the first 2000 points where there is this weird fast decay to get a better fit. experimentally, i normally set things up so this isn't an important time in the recording / animal is habituating.
%scale fit to calcium dependent data
    fit2 = fitlm(temp_fit(FP.calcium_dependent(:,1)),FP.calcium_dependent(:,2));
%calculate a crude dF/F by subtracting and then dividing by the fit

    FP.corrected_data(:,2) = 100*(FP.calcium_dependent(:,2)-((fit2.Fitted)-FP.fakebackground))./(fit2.Fitted-FP.fakebackground);
clear temp_fit fit2


f5 = figure;
    subplot(2,1,1)
   
    plot(FP.corrected_data(:,1),FP.corrected_data(:,2))
     title('Corrected Data')
     xlabel('time (seconds)')
     ylabel('dF/F')
     
FP.corrected_data(:,1) = FP.corrected_data(:,1);
FP.corrected_data(:,2) = FP.corrected_data(:,2);


%note, there is still some wonky stuff going on (ie not super duper linear.
%this is partially due to using a fake background (not in subplot 4 of
%previous graph, you don't really see this) -- and partially some artifact
%of the fit function. it tends to work better if you fit with corrected
%time data (ie not time of day in total ms -- but relative time in seconds)
%-- not sure why that is, but didn't want to muddy the waters here
%% GRAB DA MUT Normalizing
% To be run instead of "methods of neural processing" for expts involving
% mutant sensors that cannot bind biological molecule and thus have lower
% raw fluorescence than the isosbestic channel 
% FIT using only Biexponential to make corrected trace

subplot(5,1,3)
temp_fit = fit(FP.calcium_dependent(:,1),FP.calcium_dependent(:,2),'exp2');
plot(FP.calcium_dependent(:,1),FP.calcium_dependent(:,2)-temp_fit(FP.calcium_dependent(:,1)));
title('Linearize by Fitting with Biexponential')
xlabel('Time of day in total ms')
ylabel('F')

subplot(5,1,4) = figure;
    subplot(2,1,1)
    
FP.corrected_data(:,1) = FP.calcium_dependent(:,1); %time 
FP.corrected_data(:,2) =FP.calcium_dependent(:,2)-temp_fit(FP.calcium_dependent(:,1));

plot(FP.corrected_data(:,1),FP.corrected_data(:,2))
title('Corrected Data')
     xlabel('time (seconds)')
     ylabel('dF/F')
%% Referencing behaviors (STANDARD REFEED)
%1) Indexing: Find datapoint in FP data that is closest to behavioral
%timestamp
%2) Chop up data about these points
%3) Make dope graphs
%4) Profit

%For this, since the FP and keystroke data are in the same "time space" (ie
%timestamped by the same computer in the same format, we are going to loop
%through each keystroke timestamp and go from there

FP.bl = 12000; %number of datapoints to look at before keydown
FP.seg_dur = 48000; %number of datapoints to look at after keydown
t = [];
temp = [];
FP.refeedchow.B4205_refeeding = []; %necessary if you re-run this part of the code changing baseline or seg_dur
for i = 1
        t  = find(FP.corrected_data(:,1) >= B4205_refeedchow_keydown(i)); %find all FP data indices that are greater than or equal to keystroke timestampe
        temp(i,:) = t(1); %take the first one        
   
        
        %note, these data were already corrected -- so, theoretically, the
        %differences in baseline activity are real. if you'd like to baseline
        %correct these data, you can subtract the mean of the bs period

        %FP.ERF.data(:,i) = FP.ERF.data(:,i) - mean(FP.ERF.data(1:FP.bl,i));
end
new_start = [];
for ii = 1 % 8 is the number of csp and csn trials in a session. 
FP.refeedchow.B4205_refeeding(1,:) = FP.corrected_data(temp(ii)-FP.bl:temp(ii)+FP.seg_dur,2)
end


