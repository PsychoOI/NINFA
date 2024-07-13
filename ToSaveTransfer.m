% To modify
filename = 'Feedback_Subj01.mat';

% Loading and saving data
global Transfer
save(filename ,'Transfer')

% Visualization
figure
plot(Transfer)
axis([0 400 0 1])
title('Feedback')
xlabel('Frames')