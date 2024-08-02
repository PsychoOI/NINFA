function fh = RecordOnly
  fh.requires = @requires;
  fh.init     = @init;
  fh.process  = @process;
  fh.finish   = @finish;
end

% REQUIREMENTS FOR PROTOCOL
function r = requires()
    r.devicetype = "ANY";
    r.markers    = [];
    r.channels   = struct([]);
end

% EXECUTED ONCE ON START
function init()
end

% EXECUTED FOR EACH SLIDING WINDOW
function r = process(~, ~, ~, ~, ~, ~, ~, ~)
    r = 0.0;
end

% EXECUTED AT THE END OF THE SESSION
function finish(session)
    ploth = figure('Name', 'Session Plot');
    ploth.NumberTitle = 'off';
    % Plotting up to four channels
    nchannels = length(session.channels);
    nplots = nchannels+2;
    
    iplots = 1;
    fn = fieldnames(session.data); %TODO: Cache this
    for k = 1:numel(fn)
        for i = 1:size(session.data.(fn{k}), 2)
            subplot(nplots,1,iplots);
            plot(session.data.(fn{k})(:,i));
            title('Channel');
            %title('Channel ' + string(session.channels(i)));
            iplots = iplots + 1;
        end

    end
    
    % Plotting Feedback values
    subplot(nplots,1,nchannels+1);
    plot(session.feedback(:,1));
    title('Feedback');
    % Plotting Marker Values
    subplot(nplots,1,nchannels+2);
    plot(session.markers(:,1));
    title('Marker');
end
