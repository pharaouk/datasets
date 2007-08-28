function [Y, lbls, Ytest, lblstest] = lvmLoadData(dataset)

% LVMLOADDATA Load a latent variable model dataset.
% FORMAT
% DESC loads a data set for a latent variable modelling problem.
% ARG dataset : the name of the data set to be loaded. Currently
% the possible names are 'robotWireless', 'robotWirelessTest',
% 'robotTwoLoops', 'robotTraces', 'robotTracesTest', 'cmu35gplvm',
% 'cmu35Taylor', 'cmu35walkJog', 'vowels', 'stick', 'brendan',
% 'digits', 'twos', 'oil', 'oilTest', 'oilValid', 'oil100',
% 'swissRoll'.
% RETURN Y : the training data loaded in.
% RETURN lbls : a set of labels for the data (if there are no
% labels it is empty).
% RETURN Ytest : the test data loaded in. If no test set is
% available it is empty.
% RETURN lblstest : a set of labels for the test data (if there are
% no labels it is empty).
%
% SEEALSO : mapLoadData, datasetsDirectory
%
% COPYRIGHT : Neil D. Lawrence, 2004, 2005, 2006

% DATASETS

% get directory
baseDir = datasetsDirectory;
dirSep = filesep;
lbls = [];
switch dataset
 
 case 'robotWireless'
  Y = parseWirelessData([baseDir 'uw-floor.txt']);
  Y = Y(1:215, :);
 
 case 'robotWirelessTest'
  Y = parseWirelessData([baseDir 'uw-floor.txt']);
  Y = Y(216:end, :);

 case 'robotTwoLoops'
  Y = csvread([baseDir 'TwoLoops.slam'], 1, 0);
  Y = Y(1:floor(end/2), 4:end);
  Y(find(Y==-100))=-NaN;
  Y = (Y + 85)/15;
  
 case 'robotTraces'
  Y = csvread([baseDir 'Trace-3rdFloor-01.uwar.slam'], 1, 0); 
  Y = Y(1:floor(end/2), 4:end);
  Y(:, [3 4 38]) = []; % Remove columns of missing data.
  Y(find(Y==-100))=NaN;
  Y = (Y + 85)/15;

 case 'robotTracesTest'
  Y = csvread([baseDir 'Trace-3rdFloor-01.uwar.slam'], 1, 0); 
  Y = Y(ceil(end/2):end, 4:end);
  Y(:, [3 4 38]) = []; % Remove columns of missing data.
  Y(find(Y==-100))=NaN;
  Y = (Y + 85)/15;

 case 'osr'
  t = linspace(-pi, pi, 256);
  window = (cos(t) + 1)/2;
  [x, fs] = wavread([baseDir 'osr' dirSep 'OSR_uk_000_0020_8k.wav']);
  [r, theta] = stft(x, fs, 256, window);
  Y = [r(:, 1:32) theta(:, 1:32)];
  
 case 'cmu35gplvm'
  [Y, lbls, Ytest, lblstest] = lvmLoadData('cmu35WalkJog');
  skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '35' dirSep '35.asf']);
  [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '35' dirSep '35_01.amc'], skel);

  Ytest = Ytest(find(lblstest(:, 2)), :);
  lblstest = lblstest(find(lblstest(:, 2)), 2);

  %left indices
  xyzInd = [2];
  xyzDiffInd = [1 3];
  rotInd = [4 6];
  rotDiffInd = [5];
  generalInd = [7:38 41:47 49:50 53:59 61:62];

  jointAngles  = asin(sin(pi*Y(:, generalInd)/180));
  jointAnglesTest  = asin(sin(pi*Ytest(:, generalInd)/180));
  
  endInd = [];
  for i = 1:size(lbls, 2)
    endInd = [endInd max(find(lbls(:, i)))];
  end
  catJointAngles = [];
  xyzDiff = [];
  catSinCos = [];
  startInd = 1;
  for i = 1:length(endInd)
    ind1 = startInd:endInd(i)-1;
    ind2 = startInd+1:endInd(i);
    catJointAngles = [catJointAngles; ...
                      jointAngles(ind2, :)];
    xyzDiff = [xyzDiff;
               Y(ind1, xyzDiffInd) - Y(ind2, xyzDiffInd) ...
               Y(ind2, xyzInd)];
    catSinCos = [catSinCos; ...
                 sin(pi*Y(ind2, rotInd)/180) ...
                 sin(pi*Y(ind1, rotDiffInd)/180)-sin(pi*Y(ind2, rotDiffInd)/180) ...
                 cos(pi*Y(ind2, rotInd)/180) ...
                 cos(pi*Y(ind1, rotDiffInd)/180)-cos(pi*Y(ind2, rotDiffInd)/180)];
    startInd = endInd(i)+1;
  end
  Y = [catJointAngles xyzDiff catSinCos];
  lbls = [];
  
  endInd = [];
  for i = 1:size(lblstest, 2)
    endInd = [endInd max(find(lblstest(:, i)))];
  end
  catJointAnglesTest = [];
  xyzDiffTest = [];
  catSinCosTest = [];
  startInd = 1;
  for i = 1:length(endInd)
    ind1 = startInd:endInd(i)-1;
    ind2 = startInd+1:endInd(i);
    catJointAnglesTest = [catJointAnglesTest; ...
                      jointAnglesTest(ind2, :)];
    xyzDiffTest = [xyzDiffTest;
                   Ytest(ind1, xyzDiffInd) - Ytest(ind2, xyzDiffInd) ...
                   Ytest(ind2, xyzInd)];
    catSinCosTest = [catSinCosTest; ...
                 sin(pi*Ytest(ind2, rotInd)/180) ...
                 sin(pi*Ytest(ind1, rotDiffInd)/180)-sin(pi*Ytest(ind2, rotDiffInd)/180) ...
                 cos(pi*Ytest(ind2, rotInd)/180) ...
                 cos(pi*Ytest(ind1, rotDiffInd)/180)-cos(pi*Ytest(ind2, rotDiffInd)/180)];
    startInd = endInd(i)+1;
  end                                                
  Ytest = [catJointAnglesTest xyzDiffTest catSinCosTest];
  lblstest = [];

 case 'cmu35Taylor'
  % The CMU 35 data set as Graham Taylor et al. have it in their
  % NIPS 2006 paper.
  [rawY, lbls, rawYtest, lblstest] = lvmLoadData('cmu35WalkJog');
  rawYtest = rawYtest(45:end, :);
  lblstest = lblstest(45:end, 2);
  skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '35' dirSep '35.asf']);
  [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '35' dirSep '35_01.amc'], skel);
  posInd = [1 2 3];
  rotInd = [4 5 6];
  generalInd = [7:38 41:47 49:50 53:59 61:62];
  
  rawY = [rawY(:, posInd) sind(rawY(:, rotInd)) cosd(rawY(:, rotInd)) asind(sind(rawY(:, generalInd)))];
  rawYtest = [rawYtest(:, posInd) sind(rawYtest(:, rotInd)) cosd(rawYtest(:, rotInd)) asind(sind(rawYtest(:, generalInd)))];
  
  endInd = [];
  for i = 1:size(lbls, 2)
    endInd = [endInd max(find(lbls(:, i)))];
  end
  Y = [];
  startInd = 1;
  for i = 1:length(endInd)
    ind1 = startInd:endInd(i)-1;
    ind2 = startInd+1:endInd(i);
    Y = [Y; rawY(ind1, :) rawY(ind2, :)];
    startInd = endInd(i)+1;
  end  
  lbls = [];
  
  endInd = [];
  for i = 1:size(lblstest, 2)
    endInd = [endInd max(find(lblstest(:, i)))];
  end
  Ytest = [];
  startInd = 1;
  for i = 1:length(endInd)
    ind1 = startInd:endInd(i)-1;
    ind2 = startInd+1:endInd(i);
    Ytest = [Ytest; rawYtest(ind1, :) rawYtest(ind2, :)];
    startInd = endInd(i)+1;
  end                                                
  lblstest = [];

  
 case 'cmu35WalkJog'
  try 
    load([baseDir 'cmu35WalkJog.mat']);
  catch
    [void, errid] = lasterr;
    if strcmp(errid, 'MATLAB:load:couldNotReadFile');
      skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '35' dirSep '35.asf']);
      examples = ...
          {'01', '02', '03', '04', '05', '06', '07', '08', '09', '10', ...
           '11', '12', '13', '14', '15', '16', '17', '19', '20', ...
           '21', '22', '23', '24', '25', '26', '28', '30', '31', '32', '33', '34'};
      testExamples = {'18', '29'};
      % Label differently for each sequence
      exlbls = eye(31);
      testexlbls = eye(2);
      totLength = 0;
      totTestLength = 0;
      for i = 1:length(examples)
        [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '35' dirSep '35_' ...
                            examples{i} '.amc'], skel);
        tY{i} = tmpchan(1:4:end, :);
        tlbls{i} = repmat(exlbls(i, :), size(tY{i}, 1), 1);
        totLength = totLength + size(tY{i}, 1);
      end
      Y = zeros(totLength, size(tY{1}, 2));
      lbls = zeros(totLength, size(tlbls{1}, 2));
      endInd = 0;
      for i = 1:length(tY)
        startInd = endInd + 1;
        endInd = endInd + size(tY{i}, 1);
        Y(startInd:endInd, :) = tY{i};
        lbls(startInd:endInd, :) = tlbls{i};
      end
      for i = 1:length(testExamples)
        [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '35' dirSep '35_' ...
                            testExamples{i} '.amc'], skel);
        tYtest{i} = tmpchan(1:4:end, :);
        tlblstest{i} = repmat(testexlbls(i, :), size(tYtest{i}, 1), 1);
        totTestLength = totTestLength + size(tYtest{i}, 1);
      end
      Ytest = zeros(totTestLength, size(tYtest{1}, 2));
      lblstest = zeros(totTestLength, size(tlblstest{1}, 2));
      endInd = 0;
      for i = 1:length(tYtest)
        startInd = endInd + 1;
        endInd = endInd + size(tYtest{i}, 1);
        Ytest(startInd:endInd, :) = tYtest{i};
        lblstest(startInd:endInd, :) = tlblstest{i};
      end
      save([baseDir 'cmu35WalkJog.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
    else
      error(lasterr);
    end
  end

 case 'vowels'
  load([baseDir 'jon_vowel_data']);
  Y = [a_raw; ae_raw; ao_raw; ...
       e_raw; i_raw; ibar_raw; ...
       o_raw; schwa_raw; u_raw];
  Y(:, [13 26]) = [];
  lbls = [];
  for i = 1:9
    lbl = zeros(1, 9);
    lbl(i) = 1;
    lbls = [lbls; repmat(lbl, size(a_raw, 1), 1)];
  end
 

 case 'stick'
  Y = mocapLoadTextData([baseDir 'run1']);
  Y = Y(1:4:end, :);
 
 case 'brendan'
  load([baseDir 'frey_rawface.mat']);
  Y = double(ff)';
  
 case 'digits'
  
  % Fix seeds
  randn('seed', 1e5);
  rand('seed', 1e5);

  load([baseDir 'usps_train.mat']);
  % Extract 600 of digits 0 to 4
  [ALL_T, sortIndices] = sort(ALL_T);
  ALL_DATA = ALL_DATA(sortIndices(:), :);
  Y = [];
  lbls = [];
  numEachDigit = 600;
  for digit = 0:4;
    firstDigit = min(find(ALL_T==digit));
    Y = [Y; ALL_DATA(firstDigit:firstDigit+numEachDigit-1, :)];
    lbl = zeros(1, 5);
    lbl(digit+1) = 1;
    lbls = [lbls; repmat(lbl, numEachDigit, 1)];
  end

 case 'twos'  
  % load data
  load([baseDir 'twos']);
  Y = 2*a-1;

 case 'oil'
  load([baseDir '3Class.mat']);
  Y = DataTrn;
  lbls = DataTrnLbls;

 case 'oilTest'
  load([baseDir '3Class.mat']);
  Y = DataTst;
  lbls = DataTstLbls;

 case 'oilValid'
  load([baseDir '3Class.mat']);
  Y = DataVdn;
  lbls = DataVdnLbls;

 case 'oil100'
  randn('seed', 1e5);
  rand('seed', 1e5);
  load([baseDir '3Class.mat']);
  Y = DataTrn;
  lbls = DataTrnLbls;
  indices = randperm(size(Y, 1));
  indices = indices(1:100);
  Y = Y(indices, :);
  lbls = lbls(indices, :);

 case 'swissRoll'
  load([baseDir 'swiss_roll_data']);
  Y = X_data(:, 1:1000)';

  %/~
 case 'fourWalks'
  try 
    load([baseDir 'fourWalks.mat']);
  catch
    [void, errid] = lasterr;
    if strcmp(errid, 'MATLAB:load:couldNotReadFile');
      
      subj = {'35', '10', '12', '16'};
      examples = {'02', '04', '01', '15'};
      exlbls = eye(4);
      startVals = [55, 222, 22, 62];
      endVals = [338, 499, 328, 342];
      diffInd = [1 3 5];
      totLength = 0;
      totTestLength = 0;
      for i = 1:length(examples)
        skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep subj{i} dirSep subj{i} ...
                            '.asf']);
        [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep subj{i} dirSep subj{i} '_' ...
                            examples{i} '.amc'], skel);
        tY{i} = tmpchan(startVals(i):4:endVals(i), :);
        % Make given indices differences.
        tY{i}(:, diffInd) = tmpchan(startVals(i)+1:4:endVals(i)+1, diffInd)...
            - tY{i}(:, diffInd);
        tlbls{i} = repmat(exlbls(i, :), size(tY{i}, 1), 1);
        totLength = totLength + size(tY{i}, 1);
      end
      Y = zeros(totLength, size(tY{1}, 2));
      lbls = zeros(totLength, size(tlbls{1}, 2));
      endInd = 0;
      for i = 1:length(tY)
        startInd = endInd + 1;
        endInd = endInd + size(tY{i}, 1);
        Y(startInd:endInd, :) = tY{i};
        lbls(startInd:endInd, :) = tlbls{i};
      end
      Ytest = [];
      lblstest = [];
      subj = {'35', '12', '16', '12', '07', '07', '08', '08'};
      examples = {'03', '02', '21', '03', '01', '02', '01', '02'};
      testexlbls = eye(8);
      startVals = ones(1, 8);
      endVals = 200*ones(1, 8);
      totLength = 0;
      totTestLength = 0;
      for i = 1:length(examples)
        skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep subj{i} dirSep subj{i} ...
                            '.asf']);
        [tmpchan, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep subj{i} dirSep subj{i} '_' ...
                            examples{i} '.amc'], skel);
        tYtest{i} = tmpchan(startVals(i):4:endVals(i), :);
        tYtest{i}(:, diffInd) = tmpchan(startVals(i)+1:4:endVals(i)+1, diffInd)...
            - tYtest{i}(:, diffInd);
        tlblstest{i} = repmat(testexlbls(i, :), size(tYtest{i}, 1), 1);
        totLength = totLength + size(tYtest{i}, 1);
      end
      Ytest = zeros(totTestLength, size(tYtest{1}, 2));
      lblstest = zeros(totTestLength, size(tlblstest{1}, 2));
      endInd = 0;
      for i = 1:length(tYtest)
        startInd = endInd + 1;
        endInd = endInd + size(tYtest{i}, 1);
        Ytest(startInd:endInd, :) = tYtest{i};
        lblstest(startInd:endInd, :) = tlblstest{i};
      end
      save([baseDir 'fourWalks.mat'], 'Y', 'lbls', 'Ytest', 'lblstest');
    else
      error(lasterr);
    end
  end

 case 'walkSitJog'
  Y = mocapLoadTextData([baseDir 'walkSitJog']);
  Y = Y(1:4:end, :)*200;
 

 case 'robotAtrium'
  Y = parseWirelessData([baseDir 'uw-atrium.txt']);
  Y = Y(1:281, :);
 
 case 'robotAtriumTest'
  Y = parseWirelessData([baseDir 'uw-atrium.txt']);
  Y = Y(282:end, :);

      
 case 'accWalkSitJog'
  try
    load([baseDir 'walkSitJog.mat']); 
  catch    
    [void, errid] = lasterr;
    if strcmp(errid, 'MATLAB:load:couldNotReadFile')
      skel = acclaimReadSkel([baseDir 'mocap' dirSep 'cmu' dirSep '86' dirSep '86.asf']);
      [channels, skel] = acclaimLoadChannels([baseDir 'mocap' dirSep 'cmu' dirSep '86' dirSep '86_10.amc'], skel);
      % Remove root z & x pos channels.
      channels(:, [1 3]) = zeros(size(channels, 1), 2);
      Y = channels(1:4:end, :);
      save([baseDir 'walkSitJog.mat'], 'Y')
    else
      error(lasterr);
    end
  end
 case 'horse'
  load([baseDir 'horse.dat']);
  horse([133, 309], :) = [];
  ordinalAtr = [1 2 7 8 9 10 11 12 13 14 15 17 18 21];
  horse(:, ordinalAtr) = horse(:, ordinalAtr) - 1;

  % Set labels as outcome --- 1 lived, 2 died, 3 was euthanized
  lbls = zeros(size(horse, 1), 3);
  for i = 1:size(horse, 1)
    lbls(i, horse(i, 23)) = 1;
  end
  
  horse(:, 23:28) = [];
  horse(:, 3) = [];
  Y = horse;
  % Normalise Gaussian variables.
  for i = [3 4 5 15 18 19 21];
    va = var(Y(find(~isnan(Y(:, i))), i));
    Y(:, i) = Y(:, i)/va;
  end
  
  case 'pitch'
   load('-ascii', [baseDir 'bballpitch.mat']);
   Y = bballpitch(:,8:end);

 case 'ratemaps'
  % Fix seeds
  Y = loadRateMap([baseDir 'ratemaps'])';
  Y = Y(1:10000, :);
 
 case 'cepstral'
  Y = load([baseDir 'cepvecs']);
  Y = Y(1:5000, :);

 case 'vowels90'
  load([baseDir 'jon_vowel_data']);
  Y = [a_raw(1:30:end, :); ae_raw(1:30:end, :); ao_raw(1:30:end, :); ...
       e_raw(1:30:end, :); i_raw(1:30:end, :); ibar_raw(1:30:end, :); ...
       o_raw(1:30:end, :); schwa_raw(1:30:end, :); u_raw(1:30:end, :)];
  lbls = [];
  for i = 1:9
    lbl = zeros(1, 9);
    lbl(i) = 1;
    lbls = [lbls; repmat(lbl, 10, 1)];
  end
 case 'vowels3'
  load([baseDir 'jon_vowel_data']);
  Y = [a_raw(1:3:end, :); ae_raw(1:3:end, :); ao_raw(1:3:end, :); ...
       e_raw(1:3:end, :); i_raw(1:3:end, :); ibar_raw(1:3:end, :); ...
       o_raw(1:3:end, :); schwa_raw(1:3:end, :); u_raw(1:3:end, : ...
                                                    )];
  lbls = [];
  for i = 1:9
    lbl = zeros(1, 9);
    lbl(i) = 1;
    lbls = [lbls; repmat(lbl, 100, 1)];
  end
 case 'breakdance'
  Y = mocapLoadTextData([baseDir 'EricCamper04'], 0);
  Y = Y(1:4:end, :);
 
 case 'dance'
  Y = mocapLoadTextData([baseDir 'dancemotion'], 0);
  Y = Y(1:4:end, :);

 case 'danceReduced'
  Y = mocapLoadTextData([baseDir 'dancemotion'], 0);
  Y = Y(1:16:end, :);
  %~/
 
 
 otherwise
  error('Unknown data set requested.')
 
end
