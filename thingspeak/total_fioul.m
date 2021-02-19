% Channel ID to read data from
readChannelID = ;
% Fuel consummed Field ID
fieldID = 1;
% Channel Read API Key
% If your channel is private, then enter the read API Key between the '' below:
readAPIKey = '';
% Get total fuel consumed
meter_reading = thingSpeakRead(readChannelID,'Fields', fieldID,'NumDays',365,'ReadKey',readAPIKey);
% Calculate the total fuel consumed
total_time_sec = round(sum(meter_reading));
total_time_hour = total_time_sec / 3600.0;
% debit en kg/l
jet_rate = 2.78;
total_consumption = total_time_hour * jet_rate;
cons = sprintf("Fioul total consommé : %.f litres",total_consumption);
plotGauge(total_consumption,4500,10);
th = title(cons);       
set(th,'FontSize',15,'Position',[0 1.9 0])


function plotGauge(measurement, rangeGrid, numGrid)
% Plot dial / gauge / meter for depicting a measurement
%
% Input Arguments
% 1) measurement - Measurement to be indicated on the meter/gauage/dial
% 2) rangeGrid   - Measurement range; default minimum is 0, enter max value
%                  only
% 3) varargin    - (optional) numGrid: Number of equidistant grids to display
%
% Output
% Dial / Gauge / Meter with measurement indicated with an arrow
%
%
% Example:
% m = 150;                          % measurement entered by user
% rangeGrid = 480;                  % default min value = 0. Max value is 480
% numGrid   = 6;                    % Ease of readability selected by user
% plotGauge(m,rangeGrid,numGrid)    % Plot the dial with reading
% th = title('Gauge Reading');       % Set title
% set(th,'FontSize',15, 'Position', [0 1.9 0]) % Set title-properties
%
%
% Developed by
% Sowmya Aggarwal
% email: sowmyaaggarwal@gmail.com
% M.Sc. Carnegie Mellon University
% M.Sc. University of Pittsburgh

%% Error handling for the input arguments
if nargin>1
    
    try
        m = measurement;
    catch
        error('Enter measurement value to be displayed on the dial')
    end
    % m = measurement;
    
    if ~isnumeric(m)
        error('Enter a valid numeric value to be displayed on the dial')
        
    end
    % maxGrid   = rangeGrid;
    try
        maxGrid   = rangeGrid; %480;
    catch
        error('Enter the maximum value allowable for the grid-display')
    end
    
    if ~isnumeric(maxGrid) || max(size(maxGrid))>1
        error('Enter single numeric value for maximum-allowable value on grid display')
    end
    
    %     exist(numGrid)
    
else
    
    error('At least two arguments are required. Type: Help plotGauge for details')
end

%% Set coordinates of dial's graphics
% maxGrid   = rangeGrid;
rangeTheta = 0:0.1:pi;
rO1 = 1.6; % r = radius, O = outer, 1 = first outer? Outer-most if you will
semicrcO1 = rO1.*[cos(rangeTheta); sin(rangeTheta)]; % Outer-most semicircle coordinates
rO = 1.5; % set dimensions of outer radius
semicrcO = rO.*[cos(rangeTheta); sin(rangeTheta)];
rI = 1.2; % set dimensions of inner radius
semicrcI = rI.*[cos(rangeTheta); sin(rangeTheta)];


%% Plot the Dial
figure1 = figure;
axes1 = axes('Parent',figure1);
hold(axes1,'on');
area(semicrcO1(1,:),semicrcO1(2,:),'Facecolor','w')
hold on
area(semicrcO(1,:), semicrcO(2,:), 'FaceColor','b')
hold on
area(semicrcI(1,:), semicrcI(2,:), 'FaceColor','w')
hold on

%% Plot Meter-Reading Grid Lines on the Dial
hold on
plotPolarGrid(maxGrid,numGrid,rO1,rO,'k')


%% Add Annotations to the Grid Lines


%% Plot amount-grid lines
hold on

plotPolarGrid(maxGrid,4,rO1,rO,'k')



%% Plot meter-reading / dial-reading / gauge-reading for user-input measurement
maxDeg    = pi;
theta     = (maxDeg/maxGrid)*m;
xStart    = 0;      
r         = (rO+rI)/2;

if m<round(maxGrid/2)
    deltaX  = xStart-rI*abs(cos(-theta));
end

if m==maxGrid/2
    deltaX = xStart;
end

if m>maxGrid/2
    
    deltaX = xStart+rI*abs(cos(theta));
end


yStart  = 0; %rI*sin(theta(1));
deltaY  = r*abs(sin(theta));


hold on

quiver(xStart,yStart,deltaX, deltaY,...
    'LineWidth',5,...
    'MaxHeadSize',0.3,...
    'color',[1 0 0])
scatter(xStart,yStart, 'filled','k' )




axis equal

axis off


hold off


end


function plotPolarGrid(maxGrid, numGrid,radOuter,radMedium,varargin)
%% Plot Grid Lines on the Dial
% disp(varargin)

if nargin>3
    color_space = varargin{1,1};
    color = char(color_space(1));
end


theta(1:numGrid+1) = fliplr((pi/180)*linspace(0,180,numGrid+1));
n = numGrid+1;


for i=1:n
    
    xStart = radMedium*cos(theta(i));
    yStart = radMedium*sin(theta(i));
    
    deltaX = radOuter*cos(theta(i));
    deltaY = radOuter*sin(theta(i));
    
    line([xStart,deltaX], [yStart,deltaY], 'Color', char(color) );
    if i<=(n+2)/2
        text(1.7*cos(theta(i)),1.7*sin(theta(i)),...
            num2str((i-1)*(maxGrid/numGrid)),'HorizontalAlignment','right',...
            'VerticalAlignment','top','FontWeight','bold')
        
    else
        text(1.7*cos(theta(i)),1.7*sin(theta(i)),...
            num2str((i-1)*(maxGrid/numGrid)),'HorizontalAlignment','left',...
            'VerticalAlignment','top','FontWeight','bold')
    end
    
end


end