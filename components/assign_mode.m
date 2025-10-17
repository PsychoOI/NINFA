function out = assign_mode(device, varargin)
%ASSIGN_MODE  Decide A/B, resolve role & protocol, and (optionally) randomize.
%
% out = assign_mode(device)
% out = assign_mode(device, 'manual', "A"| "B")
% out = assign_mode(device, optsStruct)   % optsStruct.manual = "A"|"B"
%
% Output:
%   out.label     : "A" | "B"
%   out.role      : role string (hidden to user)
%   out.protocol  : protocol string (may include path or .m)
%   out.seed      : uint32 when randomized, [] otherwise
%   out.source    : "manual" | "randomize" | "default"
%   out.reason    : string ("" here)
%
% Notes:
% - manual (if provided) wins; else device.randomize decides; else default_mode.

    % ---- Parse inputs (struct or name-value) ----
    manual = "";      % "" means no manual override
    if ~isempty(varargin)
        if isstruct(varargin{1})
            S = varargin{1};
            if isfield(S,'manual'); manual = string(S.manual); end
        else
            % name-value pairs
            for k = 1:2:numel(varargin)
                name = lower(string(varargin{k}));
                val  = varargin{k+1};
                if name == "manual", manual = string(val); end
            end
        end
    end

    % ---- Choose A/B: manual > randomize > default ----
    seed = []; src = "default";
    if manual ~= ""
        lbl = upper(strtrim(manual));
        src = "manual";
    else
        doRand = false;
        if isfield(device,'randomize') && ~isempty(device.randomize)
            doRand = logical(device.randomize);
        end
        if doRand
            seed = uint32(mod(floor(now*86400*1e6), 2^32));
            s = rng; rng(seed,'twister');
            lbl = ifelse(rand<0.5,"A","B");
            rng(s);
            src = "randomize";
        else
            lbl = "A";
            if isfield(device,'default_mode') && ~isempty(device.default_mode)
                lbl = string(device.default_mode);
            end
        end
    end

    % ---- Validate and extract mode info ----
    if ~isfield(device,'modes') || ~isfield(device.modes, char(lbl))
        error('assign_mode:UnknownMode', 'Mode "%s" not defined for device "%s".', lbl, device.name);
    end
    m = device.modes.(char(lbl));

    if ~isfield(m,'role') || strlength(string(m.role))==0
        error('assign_mode:MissingRole','Mode %s has no "role" in JSON.', lbl);
    end
    if ~isfield(m,'protocol') || strlength(string(m.protocol))==0
        error('assign_mode:MissingProtocol','Mode %s has no "protocol" in JSON.', lbl);
    end

    % ---- Pack output ----
    out = struct();
    out.label    = lbl;
    out.role     = string(m.role);
    out.protocol = string(m.protocol);
    out.source   = src;
    out.reason   = "";
    out.seed     = seed;
end

function r = ifelse(c,a,b)
    if c, r=a; else, r=b; end
end
