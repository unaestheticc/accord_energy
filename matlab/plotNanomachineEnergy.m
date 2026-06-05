function plotNanomachineEnergy(filename)
% plotNanomachineEnergy  Plot nanomachine energy over time from an AcCoRD output file.
%
%   plotNanomachineEnergy(FILENAME)  reads the specified AcCoRD output file.
%   plotNanomachineEnergy()          opens a file selection dialog.
%
%   The script automatically detects the number of energy actors and
%   nanomachines per actor.
%
%   Output:
%     Figure 1 - Individual NM energy curves, one subplot per actor.

if nargin < 1 || isempty(filename)
    [file, path] = uigetfile({'*.txt', 'AcCoRD output files (*.txt)'}, ...
                              'Select AcCoRD output file');
    if isequal(file, 0), return; end
    filename = fullfile(path, file);
end

fprintf('Reading: %s\n', filename);
actors = parseEnergyActors(filename);
if ~isempty(actors) && isnan(actors(1).depletionThreshold)
    fprintf('  WARNING: EnergyDepletionThreshold not found in file.\n');
    fprintf('  Rerun the simulation with the latest binary to see the threshold line.\n');
end

if isempty(actors)
    error('No EnergyActor section found in file: %s', filename);
end

nActors  = numel(actors);
totalNMs = sum([actors.numNMs]);
nDepleted = 0;
for a = 1:nActors
    for k = 1:actors(a).numNMs
        if actors(a).nms(k).depleted
            nDepleted = nDepleted + 1;
        end
    end
end

fprintf('  %d actor(s), %d nanomachine(s) total', nActors, totalNMs);
if nDepleted > 0
    fprintf(', %d depleted', nDepleted);
end
fprintf('\n');

[~, shortname, ext] = fileparts(filename);
shortname = [shortname, ext];

% Common y-axis scale based on per-NM max (not the actor sum)
yMax_mJ = 0;
for a = 1:nActors
    for k = 1:actors(a).numNMs
        yMax_mJ = max(yMax_mJ, max(actors(a).nms(k).energy) * 1e3);  %#ok keep variable name
    end
end
yMax_mJ = yMax_mJ * 1.08;

% ========================================================================
%  Figure 1 - individual NM curves per actor (subplots)
% ========================================================================
figure('Name', 'NM Energy - detail per actor', 'NumberTitle', 'off', ...
       'Color', 'white');

nCols = ceil(sqrt(nActors));
nRows = ceil(nActors / nCols);

for a = 1:nActors
    subplot(nRows, nCols, a);
    hold on; grid on; box on;
    set(gca, 'FontSize', 12, 'Color', 'white', 'GridColor', [0.8 0.8 0.8]);

    t   = actors(a).time;
    nNM = actors(a).numNMs;
    cmap = parula(max(nNM, 2));

    nDepl = 0;
    for k = 1:nNM
        e = actors(a).nms(k).energy * 1e3;
        if actors(a).nms(k).depleted
            nDepl = nDepl + 1;
            plot(t, e, 'r-', 'LineWidth', 1.8);
        else
            plot(t, e, '-', 'Color', [cmap(k,:), 0.70], 'LineWidth', 1.8);
        end
    end

    % Depletion threshold reference line
    thr = actors(a).depletionThreshold;
    if ~isnan(thr) && thr > 0
        xlims = xlim;
        plot(xlims, [thr thr] * 1e3, '--', 'Color', [0.2 0.7 0.2], 'LineWidth', 1.5);
        text(xlims(1), thr * 1e3, sprintf(' thr=%.1e', thr), ...
             'Color', [0.2 0.7 0.2], 'FontSize', 10, 'VerticalAlignment', 'bottom');
    end

    xlabel('Time (s)', 'FontSize', 12);
    ylabel('Energy (pJ)', 'FontSize', 12);
    ylim([0, yMax_mJ]);

    if nDepl > 0
        titleStr = sprintf('Actor %d - %d NM - \\color{red}%d depleted', ...
                            actors(a).id, nNM, nDepl);
    else
        titleStr = sprintf('Actor %d - %d NM', actors(a).id, nNM);
    end
    title(titleStr, 'FontSize', 12);
end

try
    sgtitle(sprintf('Nanomachine energy - %s', shortname), ...
            'Interpreter', 'none', 'FontSize', 13, 'FontWeight', 'bold');
catch
    % sgtitle not available (MATLAB < R2018b)
end

% ========================================================================
%  Figure 2 - Actor 56 alone
% ========================================================================
actorIdx56 = [];
for a = 1:nActors
    if actors(a).id == 56
        actorIdx56 = a;
        break;
    end
end

if ~isempty(actorIdx56)
    a = actorIdx56;
    figure('Name', 'Actor 56 - NM Energy', 'NumberTitle', 'off', ...
           'Color', 'white');
    hold on; grid on; box on;
    set(gca, 'FontSize', 40, 'Color', 'white', 'GridColor', [0.8 0.8 0.8]);

    t    = actors(a).time;
    nNM  = actors(a).numNMs;
    cmap = parula(max(nNM, 2));

    nDepl = 0;
    for k = 1:nNM
        e = actors(a).nms(k).energy * 1e3;
        if actors(a).nms(k).depleted
            nDepl = nDepl + 1;
            plot(t, e, 'r-', 'LineWidth', 1.8);
        else
            plot(t, e, '-', 'Color', [cmap(k,:), 0.70], 'LineWidth', 1.8);
        end
    end

    thr = actors(a).depletionThreshold;
    if ~isnan(thr) && thr > 0
        xlims = xlim;
        plot(xlims, [thr thr] * 1e3, '--', 'Color', [0.2 0.7 0.2], 'LineWidth', 1.5);
        text(xlims(1), thr * 1e3, sprintf(' thr=%.1e', thr), ...
             'Color', [0.2 0.7 0.2], 'FontSize', 36, 'VerticalAlignment', 'bottom');
    end

    xlabel('Time (s)', 'FontSize', 30);
    ylabel('Energy (pJ)', 'FontSize', 30);
    ylim([0, yMax_mJ]);

    if nDepl > 0
        title(sprintf('Actor 56 - %d NM - \\color{red}%d depleted', nNM, nDepl), ...
              'FontSize', 40);
    else
        title(sprintf('Actor 56 - %d NM', nNM), 'FontSize', 40);
    end
end


end % function plotNanomachineEnergy


% ========================================================================
%  Local parsing function
% ========================================================================
function actors = parseEnergyActors(filename)
% Read an AcCoRD base output file and extract all EnergyActor sections.

fid = fopen(filename, 'r');
if fid < 0
    error('Cannot open file: %s', filename);
end
raw = textscan(fid, '%s', 'Delimiter', '\n', 'WhiteSpace', '');
fclose(fid);
lines = raw{1};

actors = struct('id',{}, 'time',{}, 'energy',{}, 'energyMax',{}, ...
                'depletionThreshold',{}, 'numNMs',{}, 'nms',{});

curActor = 0;
curNM    = 0;
expectTime        = false;
expectActorEnergy = false;
expectNMEnergy    = false;

for i = 1:numel(lines)
    L = lines{i};
    if isempty(L), continue; end

    % ---- New energy actor ----------------------------------------------
    if ~isempty(regexp(L, '^\tEnergyActor \d+:', 'once'))
        curActor = curActor + 1;
        curNM    = 0;
        actors(curActor).id                 = parseFirstInt(L);
        actors(curActor).time               = [];
        actors(curActor).energy             = [];
        actors(curActor).energyMax          = NaN;
        actors(curActor).depletionThreshold = NaN;
        actors(curActor).numNMs             = 0;
        actors(curActor).nms                = struct('id',{}, 'energy',{}, 'depleted',{});
        expectTime = false; expectActorEnergy = false; expectNMEnergy = false;

    elseif curActor == 0
        continue   % skip lines before first energy actor

    % ---- Actor-level metadata (2 tabs) ---------------------------------
    elseif ~isempty(regexp(L, '^\t\tEnergyMax:', 'once'))
        actors(curActor).energyMax = parseValue(L);

    elseif ~isempty(regexp(L, '^\t\tEnergyDepletionThreshold:', 'once'))
        actors(curActor).depletionThreshold = parseValue(L);

    elseif ~isempty(regexp(L, '^\t\tNumNanomachines:', 'once'))
        actors(curActor).numNMs = parseFirstInt(L);

    elseif ~isempty(regexp(L, '^\t\tTime:$', 'once'))
        expectTime = true;
        expectActorEnergy = false; expectNMEnergy = false;

    elseif ~isempty(regexp(L, '^\t\tEnergy:$', 'once'))
        expectActorEnergy = true;
        expectTime = false; expectNMEnergy = false;

    % ---- New nanomachine (2 tabs) --------------------------------------
    elseif ~isempty(regexp(L, '^\t\tNanomachine \d+:', 'once'))
        curNM = curNM + 1;
        actors(curActor).nms(curNM).id       = parseFirstInt(L);
        actors(curActor).nms(curNM).energy   = [];
        actors(curActor).nms(curNM).depleted = false;
        expectNMEnergy = false; expectActorEnergy = false;

    % ---- NM-level metadata (3 tabs) ------------------------------------
    elseif ~isempty(regexp(L, '^\t\t\tEnergyDepleted:', 'once')) && curNM > 0
        actors(curActor).nms(curNM).depleted = ~isempty(strfind(L, 'YES'));

    elseif ~isempty(regexp(L, '^\t\t\tEnergy:$', 'once')) && curNM > 0
        expectNMEnergy = true;
        expectTime = false; expectActorEnergy = false;

    % ---- Data lines (vectors) ------------------------------------------
    elseif expectTime
        actors(curActor).time = sscanf(strtrim(L), '%f')';
        expectTime = false;

    elseif expectActorEnergy
        actors(curActor).energy = sscanf(strtrim(L), '%f')';
        expectActorEnergy = false;

    elseif expectNMEnergy && curNM > 0
        actors(curActor).nms(curNM).energy = sscanf(strtrim(L), '%f')';
        expectNMEnergy = false;
    end
end
end % function parseEnergyActors


function val = parseFirstInt(str)
% Return the first integer found in str.
    tok = regexp(str, '\d+', 'match', 'once');
    val = str2double(tok);
end

function val = parseValue(str)
% Return the numeric value after ':' in a "Key: value" line.
    idx = find(str == ':', 1, 'first');
    if isempty(idx)
        val = NaN;
    else
        val = str2double(strtrim(str(idx+1:end)));
    end
end
