function out = assign_mode(device, opts)
%ASSIGN_MODE  Decide A/B, resolve role & protocol, and (optionally) randomize.
%
% out = assign_mode(device, opts)
%
% Inputs
%   device : struct as loaded by devices.m (must contain .modes, .default_mode, .randomize)
%   opts   : (optional) struct with fields:
%              - manual   : "A"|"B"  (manual override; still blinded to user)
%              - reason   : string   (why overridden; optional)
%              - randomize: logical  (override device.randomize)
%
% Output (struct)
%   out.label     : "A" or "B" (mode label)
%   out.role      : "real" | "sham" | string (hidden)
%   out.protocol  : string (e.g., "MovAvg_SS")
%   out.seed      : uint32 (only when randomized), [] otherwise
%   out.source    : "manual" | "randomize" | "default"
%   out.reason    : string (empty unless manual)
%
% Notes
% - If opts.manual is provided, that wins.
% - Else if randomize is true (device or opts), coin-flip with a logged seed.
% - Else use device.default_mode (falls back to "A" if missing).
% - This only reads JSON; it does not check that a .m file exists on disk.

    arguments
        device (1,1) struct
        opts.manual string = ""
        opts.reason string = ""
        opts.randomize logical = []
    end

    % Choose source: manual vs randomize vs default ---
    if opts.manual ~= ""
        lbl = upper(strtrim(opts.manual));
        src = "manual";
        rsn = opts.reason;
    else
        % prefer explicit override in opts if provided, else device.randomize
        doRand = device.randomize;
        if ~isempty(opts.randomize)
            doRand = logical(opts.randomize);
        end
        if doRand
            % coin flip with reproducible seed output
            seed = uint32(mod(floor(now*86400*1e6), 2^32));  % time-based seed
            s = rng;                 % stash current
            rng(seed, 'twister');
            lbl = ifelse(rand < 0.5, "A", "B");
            rng(s);                  % restore previous RNG state
            src = "randomize";
            rsn = "";
        else
            lbl = "A";
            if isfield(device, 'default_mode') && ~isempty(device.default_mode)
                lbl = string(device.default_mode);
            end
            src = "default";
            rsn = "";
            seed = [];
        end
    end

    % Validate label and pull mode struct
    if ~isfield(device, 'modes') || isempty(device.modes)
        error('assign_mode:NoModes', 'Device "%s" has no "modes" in JSON.', device.name);
    end
    if ~isfield(device.modes, char(lbl))
        error('assign_mode:UnknownMode', 'Mode "%s" not defined in device "%s".', lbl, device.name);
    end
    m = device.modes.(char(lbl));

    % Extract role & protocol with guards
    if ~isfield(m, 'role') || strlength(string(m.role))==0
        error('assign_mode:MissingRole', 'Mode %s has no "role" in JSON.', lbl);
    end
    if ~isfield(m, 'protocol') || strlength(string(m.protocol))==0
        error('assign_mode:MissingProtocol', 'Mode %s has no "protocol" in JSON.', lbl);
    end

    % Pack output
    out = struct();
    out.label    = lbl;
    out.role     = string(m.role);
    out.protocol = string(m.protocol);
    out.source   = src;
    out.reason   = rsn;

    % seed only for randomized pick
    if exist('seed','var')
        out.seed = seed;
    else
        out.seed = [];
    end
end

function r = ifelse(cond, a, b)
    if cond, r = a; else, r = b; end
end
