function plotNanomachineEnergy(filename)
% plotNanomachineEnergy  Visualise l'energie des nanomachines au cours du temps.
%
%   plotNanomachineEnergy(FILENAME)  lit le fichier de sortie AcCoRD indique.
%   plotNanomachineEnergy()          ouvre une boite de dialogue de selection.
%
%   Le script detecte automatiquement le nombre d'acteurs energie et de
%   nanomachines par acteur.
%
%   Figures produites :
%     Figure 1 - Courbes individuelles (une sous-figure par acteur).
%     Figure 2 - Energie moyenne +/-1 ecart-type par acteur.

if nargin < 1 || isempty(filename)
    [file, path] = uigetfile({'*.txt', 'Fichiers de sortie AcCoRD (*.txt)'}, ...
                              'Selectionner le fichier de sortie AcCoRD');
    if isequal(file, 0), return; end
    filename = fullfile(path, file);
end

fprintf('Lecture : %s\n', filename);
actors = parseEnergyActors(filename);

if isempty(actors)
    error('Aucune section EnergyActor trouvee dans le fichier : %s', filename);
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

fprintf('  %d acteur(s), %d nanomachine(s) au total', nActors, totalNMs);
if nDepleted > 0
    fprintf(', %d epuisee(s)', nDepleted);
end
fprintf('\n');

[~, shortname, ext] = fileparts(filename);
shortname = [shortname, ext];

% Echelle y commune basee sur le max reel par NM (pas la somme acteur)
yMax_mJ = 0;
for a = 1:nActors
    for k = 1:actors(a).numNMs
        yMax_mJ = max(yMax_mJ, max(actors(a).nms(k).energy) * 1e3);
    end
end
yMax_mJ = yMax_mJ * 1.08;

% ========================================================================
%  Figure 1 - courbes individuelles par acteur (sous-figures)
% ========================================================================
figure('Name', 'Energie NM - detail par acteur', 'NumberTitle', 'off');

nCols = ceil(sqrt(nActors));
nRows = ceil(nActors / nCols);

for a = 1:nActors
    subplot(nRows, nCols, a);
    hold on; grid on; box on;

    t   = actors(a).time;
    nNM = actors(a).numNMs;
    cmap = parula(max(nNM, 2));

    nDepl = 0;
    for k = 1:nNM
        e = actors(a).nms(k).energy * 1e3;
        if actors(a).nms(k).depleted
            nDepl = nDepl + 1;
            plot(t, e, 'r-', 'LineWidth', 0.8);
        else
            plot(t, e, '-', 'Color', [cmap(k,:), 0.55], 'LineWidth', 0.8);
        end
    end

    xlabel('Temps (s)');
    ylabel('Energie (mJ)');
    ylim([0, yMax_mJ]);

    if nDepl > 0
        titleStr = sprintf('Acteur %d - %d NM - \\color{red}%d epuisee(s)', ...
                            actors(a).id, nNM, nDepl);
    else
        titleStr = sprintf('Acteur %d - %d NM', actors(a).id, nNM);
    end
    title(titleStr);
end

try
    sgtitle(sprintf('Energie des nanomachines - %s', shortname), ...
            'Interpreter', 'none');
catch
    % sgtitle non disponible (MATLAB < R2018b) - pas de titre global
end


end % function plotNanomachineEnergy


% ========================================================================
%  Fonction locale de parsing
% ========================================================================
function actors = parseEnergyActors(filename)
% Lit un fichier de sortie AcCoRD et extrait les sections EnergyActor.

fid = fopen(filename, 'r');
if fid < 0
    error('Impossible d''ouvrir le fichier : %s', filename);
end
raw = textscan(fid, '%s', 'Delimiter', '\n', 'WhiteSpace', '');
fclose(fid);
lines = raw{1};

actors = struct('id',{}, 'time',{}, 'energy',{}, 'energyMax',{}, ...
                'numNMs',{}, 'nms',{});

curActor = 0;
curNM    = 0;
expectTime        = false;
expectActorEnergy = false;
expectNMEnergy    = false;

for i = 1:numel(lines)
    L = lines{i};
    if isempty(L), continue; end

    % ---- Nouveau acteur energie ----------------------------------------
    if ~isempty(regexp(L, '^\tEnergyActor \d+:', 'once'))
        curActor = curActor + 1;
        curNM    = 0;
        actors(curActor).id        = parseFirstInt(L);
        actors(curActor).time      = [];
        actors(curActor).energy    = [];
        actors(curActor).energyMax = NaN;
        actors(curActor).numNMs    = 0;
        actors(curActor).nms       = struct('id',{}, 'energy',{}, 'depleted',{});
        expectTime = false; expectActorEnergy = false; expectNMEnergy = false;

    elseif curActor == 0
        continue   % avant le premier acteur energie

    % ---- Metadonnees acteur (2 tabulations) ----------------------------
    elseif ~isempty(regexp(L, '^\t\tEnergyMax:', 'once'))
        actors(curActor).energyMax = parseValue(L);

    elseif ~isempty(regexp(L, '^\t\tNumNanomachines:', 'once'))
        actors(curActor).numNMs = parseFirstInt(L);

    elseif ~isempty(regexp(L, '^\t\tTime:$', 'once'))
        expectTime = true;
        expectActorEnergy = false; expectNMEnergy = false;

    elseif ~isempty(regexp(L, '^\t\tEnergy:$', 'once'))
        expectActorEnergy = true;
        expectTime = false; expectNMEnergy = false;

    % ---- Nouvelle nanomachine (2 tabulations) --------------------------
    elseif ~isempty(regexp(L, '^\t\tNanomachine \d+:', 'once'))
        curNM = curNM + 1;
        actors(curActor).nms(curNM).id       = parseFirstInt(L);
        actors(curActor).nms(curNM).energy   = [];
        actors(curActor).nms(curNM).depleted = false;
        expectNMEnergy = false; expectActorEnergy = false;

    % ---- Metadonnees NM (3 tabulations) --------------------------------
    elseif ~isempty(regexp(L, '^\t\t\tEnergyDepleted:', 'once')) && curNM > 0
        actors(curActor).nms(curNM).depleted = ~isempty(strfind(L, 'YES'));

    elseif ~isempty(regexp(L, '^\t\t\tEnergy:$', 'once')) && curNM > 0
        expectNMEnergy = true;
        expectTime = false; expectActorEnergy = false;

    % ---- Lignes de donnees (vecteurs) ----------------------------------
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
% Retourne le premier entier trouve dans str.
    tok = regexp(str, '\d+', 'match', 'once');
    val = str2double(tok);
end

function val = parseValue(str)
% Retourne la valeur numerique apres le ':' dans une ligne "Cle: valeur".
    idx = find(str == ':', 1, 'first');
    if isempty(idx)
        val = NaN;
    else
        val = str2double(strtrim(str(idx+1:end)));
    end
end
