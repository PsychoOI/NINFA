% START THIS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% add folders
addpath(genpath('liblsl-Matlab'));
addpath(genpath('components'));
addpath(genpath('protocols'));
addpath(genpath('ui'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% cleanup
close all force; % close old windows
clear            % clear workspace

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% globals
global mylsl;
global mysession;
global mydevices;
global myprotocols;
global myselectchannels;
global mysettings;
global myfeedback;

% init globals
mylsl            = lsl();
mysession        = session();
mydevices        = devices();
myprotocols      = protocols();
myselectchannels = selectchannels();
mysettings       = app();
myfeedback       = feedback();

% add listeners to lsl
lhsample = addlistener(mylsl, "NewSample", @onNewSample);

% add listeners to session
lhstart  = addlistener(mysession, "Started", @onSessionStarted);
lhstop   = addlistener(mysession, "Stopped", @onSessionStopped);
lhwindow = addlistener(mysession, "Window",  @onSessionWindow);
lhepoch  = addlistener(mysession, "Epoch",   @onSessionEpoch);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% main thread loop
while isvalid(mysettings) && isvalid(myfeedback.hFig)

    % update components
    mylsl.update();
    mysettings.update();
    mysession.update();
    myfeedback.centerBar();
    
    % update ui and run callbacks
    drawnow limitrate;
    
end

% shutdown
if isvalid(mysettings)
    delete(mysettings);
end
if isvalid(myfeedback) 
    delete(myfeedback);
end

% close old windows
close all force;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function onNewSample(src, ~)
    global mysession;
    mysession.pushSample(src.sample, src.timestamp);
    mysession.update();
end

function onSessionStarted(src, ~)
    global mylsl;
    global myfeedback;
    global myprotocol;
    mylsl.marker = 0;
    mylsl.trigger(100);
    myfeedback.showBar();
    myprotocol = feval(src.protocol);
    myprotocol.init();
end

function onSessionStopped(src, ~)
    global mylsl;
    global myfeedback;
    mylsl.marker = 0;
    mylsl.trigger(101);
    myfeedback.setBackground(src.bgcolor);
    myfeedback.hideBar();
end

function onSessionEpoch(src, ~)
    global mylsl;
    global myfeedback;
    mylsl.marker = src.marker;
    myfeedback.setBackground(src.bgcolor);
    if src.fbvisible
        myfeedback.showBar();
    else
        myfeedback.hideBar();
    end
end

function onSessionWindow(src, ~)
    global myfeedback;
    global myprotocol;

    prevfeedback = 0.5;
    if src.idx > 1
        prevfeedback = src.feedback(src.idx-1);
    end
    
    tick = tic();
    r = myprotocol.process (...
        src.marker,    src.SizeCHSS, src.srate, ...
        src.idx,       src.data(src.idx,:), ...
        src.windownum, src.window, ...
        src.windowidx >= length(src.window), ...
        prevfeedback);
    span = toc(tick);
    
    myfeedback.setFeedback(r);
    src.pushFeedback(r, span);
end
