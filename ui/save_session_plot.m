function save_session_plot(session)
% Save the protocol's "Session Plot" with the standardized name.
% Robust to string paths, collisions, and figure lookup.

% 1) Find the figure created by the protocol
fig = findobj(0, 'Type','figure', 'Name','Session Plot');
if isempty(fig) || ~ishandle(fig)
    % Fallback: use current figure if it exists
    if ishghandle(gcf, 'figure')
        fig = gcf;
    else
        warning('save_session_plot: no figure to save.');
        return;
    end
else
    fig = fig(1);  % most recent
end

% 2) Study folder & safe name
studyName = session.study;
if studyName == "", studyName = "unnamed"; end
safeStudy = regexprep(string(studyName), '[^A-Za-z0-9._-]', '_');

baseDir = fullfile("sessions", safeStudy);
if ~isfolder(baseDir)
    mkdir(baseDir);
end

% 3) Timestamp (second precision). If you want fewer collisions, use 'yyyy-MM-dd_HH-mm-ss_SSS'
ts = string(datetime(session.starttime, 'ConvertFrom','datenum', ...
                     'Format','yyyy-MM-dd_HH-mm-ss'));

% 4) Base filename (blind: no protocol/device)
baseName = sprintf("%s_S%03d_R%02d_%s", safeStudy, session.subject, session.run, ts);
pngPath  = fullfile(baseDir, baseName + ".png");

% 5) Collision-safe suffix (_v02, _v03, …)
if isfile(pngPath)
    k = 2;
    while true
        candidate = fullfile(baseDir, baseName + sprintf("_v%02d.png", k));
        if ~isfile(candidate)
            pngPath = candidate;
            break;
        end
        k = k + 1;
    end
end

% 6) Save the figure
try
    exportgraphics(fig, pngPath, 'Resolution', 150);
catch
    try
        saveas(fig, pngPath);
    catch ME
        warning("Could not save session plot: ", '%s',ME.message);
    end
end
end
