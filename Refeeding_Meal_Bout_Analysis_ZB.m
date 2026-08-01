%% MEAL BOUT ANALYSIS
% Set up a time vectorx
FP.time = linspace(-10,40,60001);
%Make the first column your corrected data and the second the time vector:

FP.refeedchow.D4020bv_refeeding(:,2) = FP.time;
%BEFORE RUNNING, if you have not already, delete the first and last values (food access keydowns)
% from your keydowns that way all keydowns being analyzed are meal bout
% keydowns

%Convert the keydown values into minutes  and separate bout start and bout
%end into temporar variables:

D4020bv_refeedchow_keydown = (D4020bv_refeedchow_keydown ./ 60) - 15;
D4020bv_refeedchow_keydown(2:2:end) = D4020bv_refeedchow_keydown(2:2:end) - 0.16667;

% CAUTION ^Be sure to turn these two lines off if running this again

FP.refeedchow.D4020bv_boutstart = downsample(D4020bv_refeedchow_keydown(:),2); %temporary variable 
FP.refeedchow.D4020bv_boutend = downsample(D4020bv_refeedchow_keydown(2:end),2);


%Plot the refeeding session data and bout start/end lines:
figure(1)
plot(FP.refeedchow.D4020bv_refeeding(:,2),FP.refeedchow.D4020bv_refeeding(:,1))
for i = 1:length(FP.refeedchow.D4020bv_boutstart)
    xline(0, "LineWidth",2,"LineStyle","--")
    %xline(FP.refeedchow.D4020bv_boutstart(i),"LineWidth",1,"Color",'g')
    %xline(FP.refeedchow.D4020bv_boutend(i),"LineWidth",1,"Color",'r')
    xline(30, "LineWidth",2,"LineStyle","--")

end


%% Refeeding activity bout quantification analysis:
%The following script will be dedicated to quantifying and analyzing the
%activity of a brain region at the beginning of a bout (meal) and compare
%it to the activity at the end of the bout.

%First, we will want to convert the pre-food access period processed and finalized trace of a
%session to its own zscore:
%Pre-food access recordings are 10 minutes long, because processed traces
%are 20 data points per second we want points up to 12001:

% DELETE THE TIME COLUMN IN YOUR FP.refeedchow.ANIMALID_REFEEDING FILE OR
% YOU WILL GET AN ERROR.


FP.refeedchow.zscore_pre.D4020bv_refeeding = zscore(FP.refeedchow.D4020bv_refeeding(1:12001)); 

%The following will extract the standard deviation and mean of period -7min
%to -2min and we will use that standard deviation and mean of this set to normalize period
%where food is accessible: 

FP.refeedchow.zscore_pre.D4020bv_refeeding_7to2_std = std(FP.refeedchow.D4020bv_refeeding(3601:9601));
FP.refeedchow.zscore_pre.D4020bv_refeeding_7to2_mean = mean(FP.refeedchow.D4020bv_refeeding(3601:9601));

%Next we will convert the period where food is available to a zscore using
%the std and mean we extracted above: 

FP.refeedchow.zscore_duringmeal.D4020bv_refeeding_during = (FP.refeedchow.D4020bv_refeeding(12002:end) - FP.refeedchow.zscore_pre.D4020bv_refeeding_7to2_mean) ./ FP.refeedchow.zscore_pre.D4020bv_refeeding_7to2_std;

%We should have successfully normalized the food available period and post
%to a baseline period (pre food), we will now want to connect the two to
%see what it looks like:

FP.refeedchow.zscore_finalized.D4020bv_refeeding = []; %Initialize the variable as an empty matrix

FP.refeedchow.zscore_finalized.D4020bv_refeeding(1:12001) = FP.refeedchow.zscore_pre.D4020bv_refeeding;
FP.refeedchow.zscore_finalized.D4020bv_refeeding(12002:60001) = FP.refeedchow.zscore_duringmeal.D4020bv_refeeding_during;

figure

plot(FP.time,FP.refeedchow.zscore_finalized.D4020bv_refeeding)

FP.refeedchow.zscore_finalized.D4020bv_refeeding = FP.refeedchow.zscore_finalized.D4020bv_refeeding'
FP.refeedchow.zscore_finalized.D4020bv_refeeding(:,2) = FP.time;


%% The following will extract the data 15s after a bout start and average the values, and do the same for 15s before a bout ends:

FP.bl = 300; %number of datapoints to look at before keydown
FP.seg_dur = 300; %number of datapoints to look at after keydown


FP.refeedchow.afterboutstarts.D4020bv_15safterstart = []; 
FP.refeedchow.beforeboutends.D4020bv_15sbeforeend = [];

%% Within bout interval 

% 15 SECONDS AFTER BOUT STARTS

for i = 1:length(FP.refeedchow.D4020bv_boutstart)
       
       t = [];
       temp = [];

       t(1,:)  = find(FP.refeedchow.zscore_finalized.D4020bv_refeeding(:,2) >= FP.refeedchow.D4020bv_boutstart(i)); %find all FP data indices that are greater than or equal to the timestamp of when a bout starts. In this case, the time vector is on the second column because we manually put the FP.time on the variable in the second column.
       temp(1,:) = t(1); %take the first one 
       t = [];

       FP.refeedchow.afterboutstarts.D4020bv_15safterstart(i,:) = FP.refeedchow.zscore_finalized.D4020bv_refeeding(temp(1):temp(1)+FP.seg_dur,1);
       temp = [];

       FP.refeedchow.afterboutstarts.D4020bv_15safterstart_avg = mean(FP.refeedchow.afterboutstarts.D4020bv_15safterstart, 2)
        
end


%15 SECONDS BEFORE BOUT ENDS

for i = 1:length(FP.refeedchow.D4020bv_boutend)
       
       t = [];
       temp = [];

       t(1,:)  = find(FP.refeedchow.zscore_finalized.D4020bv_refeeding(:,2) >= FP.refeedchow.D4020bv_boutend(i)); %find all FP data indices that are greater than or equal to the timestamp of when a bout starts. In this case, the time vector is on the second column because we manually put the FP.time on the variable in the second column.
       temp(1,:) = t(1); %take the first one 
       t = [];

       FP.refeedchow.beforeboutends.D4020bv_15sbeforeend(i,:) = FP.refeedchow.zscore_finalized.D4020bv_refeeding(temp(1)-FP.bl:temp(1),1);
       temp = [];

       FP.refeedchow.beforeboutends.D4020bv_15sbeforeend_avg = mean(FP.refeedchow.beforeboutends.D4020bv_15sbeforeend, 2)
        
end

%% Inter bout interval

%15 SECONDS BEFORE BOUT STARTS

for i = 1:length(FP.refeedchow.D4020bv_boutstart)
       
       t = [];
       temp = [];

       t(1,:)  = find(FP.refeedchow.zscore_finalized.D4020bv_refeeding(:,2) >= FP.refeedchow.D4020bv_boutstart(i)); %find all FP data indices that are greater than or equal to the timestamp of when a bout starts. In this case, the time vector is on the second column because we manually put the FP.time on the variable in the second column.
       temp(1,:) = t(1); %take the first one 
       t = [];

       FP.refeedchow.beforeboutstarts.D4020bv_15sbeforestart(i,:) = FP.refeedchow.zscore_finalized.D4020bv_refeeding(temp(ii)-FP.seg_dur:temp(ii),1);
       temp = [];

       FP.refeedchow.beforeboutstarts.D4020bv_15sbeforestart_avg = mean(FP.refeedchow.beforeboutstarts.D4020bv_15sbeforestart, 2)
        
end


%15 SECONDS AFTER BOUT ENDS

for i = 1:length(FP.refeedchow.D4020bv_boutend)
       
       t = [];
       temp = [];

       t(1,:)  = find(FP.refeedchow.zscore_finalized.D4020bv_refeeding(:,2) >= FP.refeedchow.D4020bv_boutend(i)); %find all FP data indices that are greater than or equal to the timestamp of when a bout starts. In this case, the time vector is on the second column because we manually put the FP.time on the variable in the second column.
       temp(1,:) = t(1); %take the first one 
       t = [];

       FP.refeedchow.afterboutends.D4020bv_15safterend(i,:) = FP.refeedchow.zscore_finalized.D4020bv_refeeding(temp(ii):temp(ii)+FP.bl,1);
       temp = [];

       FP.refeedchow.afterboutends.D4020bv_15safterend_avg = mean(FP.refeedchow.afterboutends.D4020bv_15safterend, 2)
        
end



%% Area under the curve analysis- Pre food and Post food access

%Timepoints
timepoints_5min = [0:5];
timepoints_5min_idx_prefood = [1;1201;2401;3601;4801];
timepoints_5min_idx_postfood = [54001;55201;56401;57601;58801];

for i = 1:length(timepoints_5min_idx_prefood) %Number of seconds being accounted for as shown above.
        
        FP.refeedchow.auc.D4020bv_5min_prefood(i) = FP.refeedchow.zscore_finalized.D4020bv_refeeding((timepoints_5min_idx_prefood(i)),1);
        
end

for i = 1:length(timepoints_5min_idx_postfood) %Number of seconds being accounted for as shown above.
        
        FP.refeedchow.auc.D4020bv_5min_postfood(i) = FP.refeedchow.zscore_finalized.D4020bv_refeeding((timepoints_5min_idx_postfood(i)),1);
        
end

FP.refeedchow.auc.D4020bv_5min_prefood
FP.refeedchow.auc.D4020bv_5min_postfood

