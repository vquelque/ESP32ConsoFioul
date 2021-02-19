% Compute daily oil consumption
% Channel ID to read data from 
readChannelID = ; 
   
% Conso Field ID 
fieldID = 1;
% Channel Read API Key
% If your channel is private, then enter the read API Key between the '' below:
readAPIKey = '';

% Get running time values for the last 30 days  
running_time_30 = thingSpeakRead(readChannelID,'Fields', fieldID,'NumDays',30,'ReadKey',readAPIKey,'outputFormat','timetable');
% Compute the daily sum of the runing times 
running_time_hourly = retime(running_time_30,'daily','sum');
% Compute daily consumed oil. Jet rate = 2.78 l/h
func = @(x) (x/3600)*2.78;
daily_consumption = rowfun(func,running_time_hourly)

% bar chart
bar(daily_consumption.Timestamps,daily_consumption.Var1);
xlabel('Date'); 
ylabel('Consommation (litres)'); 
title('Consommation journalière de fioul');