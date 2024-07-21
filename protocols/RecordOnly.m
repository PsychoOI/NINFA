function fh = RecordOnly
  fh.requires = @requires;
  fh.init     = @init;
  fh.process  = @process;
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
function r = process(~, ~, ~, ~, ~, ~, ~, ~, ~)
    r = 0.0;
end
