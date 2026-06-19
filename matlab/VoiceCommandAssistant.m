function VoiceCommandAssistant()
% ========================================================================
% VOICE RECOGNITION COMMAND ASSISTANT
% Complete offline system with 20 built-in commands
% ========================================================================
% Configuration
fs = 16000; % sampling rate
NUM_MFCC = 13; % MFCC coefficients
ID_THRESHOLD = 20; % identification threshold
ROOT_DB = 'database'; % user database folder
RECORD_DIR = 'recordings'; % audio recordings folder
HISTORY_DIR = 'history'; % conversation history folder
% Create necessary folders
if ~exist(ROOT_DB,'dir'), mkdir(ROOT_DB); end
if ~exist(RECORD_DIR,'dir'), mkdir(RECORD_DIR); end
if ~exist(HISTORY_DIR,'dir'), mkdir(HISTORY_DIR); end
% Load or initialize reminders
REMINDERS_FILE = fullfile(HISTORY_DIR, 'reminders.mat');
if exist(REMINDERS_FILE, 'file')
 load(REMINDERS_FILE, 'reminders');
else
 reminders = struct();
end
fprintf('\n==============================================\n');
fprintf(' VOICE RECOGNITION COMMAND ASSISTANT\n');
fprintf(' 20 Built-in Commands - Fully Offline\n');
fprintf('==============================================\n\n');
% Main menu loop
while true
 fprintf('\nMAIN MENU:\n');
 fprintf('1. Register New User\n');
 fprintf('2. Start Voice Command Assistant\n');
 fprintf('3. Test Voice Matching (with visualization)\n');
 fprintf('4. View Available Commands\n');
 fprintf('5. View Users & History\n');
 fprintf('6. Delete User\n');
 fprintf('7. Exit\n\n');

 choice = input('Enter choice (1-7): ', 's');

13
 switch choice
 case '1'
 registerUser();
 case '2'
 startAssistant();
 case '3'
 testVoiceMatching();
 case '4'
 showCommands();
 case '5'
 viewUsersAndHistory();
 case '6'
 deleteUser();
 case '7'
 saveReminders();
 fprintf('\nThank you for using Voice Command Assistant!\n');
 return;
 otherwise
 fprintf('Invalid choice. Please try again.\n');
 end
end
%% ========================================================================
% NESTED FUNCTIONS
% ========================================================================
 function registerUser()
 fprintf('\n==============================================\n');
 fprintf(' USER REGISTRATION\n');
 fprintf('==============================================\n\n');

 % Get user name
 name = input('Enter user name (no spaces): ', 's');
 if isempty(name)
 fprintf('Error: Name cannot be empty.\n');
 return;
 end

 % Check if user exists
 dbFile = fullfile(ROOT_DB, [name '.mat']);
 if exist(dbFile, 'file')
 overwrite = input('User exists. Overwrite? (y/n): ', 's');
 if ~strcmpi(overwrite, 'y')
 return;
 end
 end

 % Registration sentences
14
 sentences = {
 'The quick brown fox jumps over the lazy dog';
 'Machine learning is transforming the world';
 'Voice recognition technology is amazing';
 'Artificial intelligence helps solve complex problems';
 'Speech processing enables natural human computer interaction'
 };

 sentence = sentences{randi(length(sentences))};

 fprintf('\nPlease read this sentence clearly:\n');
 fprintf('>> "%s"\n\n', sentence);
 fprintf('Recording in: 3...');
 pause(1); fprintf(' 2...'); pause(1); fprintf(' 1...\n');
 fprintf('RECORDING (4 seconds)...\n');

 % Record audio
 rec = audiorecorder(fs, 16, 1);
 recordblocking(rec, 4);
 audio = getaudiodata(rec);
 audio = audio / max(1e-6, max(abs(audio)));

 fprintf('Recording complete!\n');

 % Save audio file
 audiowrite(fullfile(RECORD_DIR, [name '_registration.wav']), audio, fs);

 % Extract features
 features = extractFeatures(audio, fs);

 % Save user data
 user.name = name;
 user.features = features;
 user.sentence = sentence;
 user.registered = datetime('now');
 user.audioSample = audio;
 user.sampleRate = fs;

 save(dbFile, 'user');

 fprintf('\n✓ User "%s" registered successfully!\n', name);
 fprintf(' Pitch: %.1f Hz\n', features.pitch_mean);
 fprintf(' Energy: %.4f\n', features.energy_mean);
 end
 function startAssistant()
 fprintf('\n==============================================\n');
 fprintf(' VOICE COMMAND ASSISTANT STARTED\n');
15
 fprintf('==============================================\n\n');

 % Load all users
 files = dir(fullfile(ROOT_DB, '*.mat'));
 if isempty(files)
 fprintf('Error: No users registered. Register first (option 1).\n');
 return;
 end

 names = {};
 userDatabase = {};
 for i = 1:length(files)
 try
 S = load(fullfile(files(i).folder, files(i).name));

 % Check if 'user' field exists
 if isfield(S, 'user')
 userData = S.user;
 else
 % Try direct structure
 userData = S;
 end

 % Validate user structure
 if ~isfield(userData, 'features') || ~isfield(userData, 'name')
 fprintf('Warning: Invalid user file %s - skipping\n', files(i).name);
 continue;
 end

 names{end+1} = userData.name; %#ok<AGROW>
 userDatabase{end+1} = userData.features; %#ok<AGROW>
 catch ME
 fprintf('Warning: Could not load %s - %s\n', files(i).name, ME.message);
 end
 end

 if isempty(names)
 fprintf('Error: No valid users found. Please re-register users.\n');
 return;
 end

 fprintf('Loaded %d registered users\n', length(names));
 fprintf('Type "exit" to quit\n');
 fprintf('Say "help" to see available commands\n\n');

 % Assistant loop
 sessionCount = 0;
 while true
16
 sessionCount = sessionCount + 1;
 fprintf('\n========== Session %d ==========\n', sessionCount);

 continueChat = input('Press Enter to speak (or type "exit"): ', 's');
 if strcmpi(continueChat, 'exit')
 break;
 end

 % STEP 1: Identify speaker
 fprintf('\nSpeak now to identify yourself (3 seconds)...\n');
 rec = audiorecorder(fs, 16, 1);
 recordblocking(rec, 3);
 audio = getaudiodata(rec);
 audio = audio / max(1e-6, max(abs(audio)));

 % Check audio energy
 if max(abs(audio)) < 0.01
 fprintf('No speech detected. Please speak louder.\n');
 continue;
 end

 % Extract features and identify
 testFeatures = extractFeatures(audio, fs);
 [identifiedUser, confidence, matchDetails] = identifySpeaker(testFeatures, userDatabase, names);

 % Display matching results
 displayMatchingResults(matchDetails, names);

 if isempty(identifiedUser)
 fprintf('\n✗ UNKNOWN USER - Speaker not recognized\n');
 fprintf('Please register first.\n');
 continue;
 end

 fprintf('\n✓ SPEAKER IDENTIFIED: %s\n', identifiedUser);
 fprintf(' Confidence: %.1f%%\n\n', confidence * 100);

 % STEP 2: Get command
 fprintf('Now speak your command (4 seconds)...\n');
 rec2 = audiorecorder(fs, 16, 1);
 recordblocking(rec2, 4);
 qAudio = getaudiodata(rec2);
 qAudio = qAudio / max(1e-6, max(abs(qAudio)));

 % Try speech-to-text or ask for manual input
 command = transcribeAudio(qAudio, fs);

 if isempty(command)
17
 fprintf('Please try again.\n');
 continue;
 end

 fprintf('\nYou said: "%s"\n', command);

 % STEP 3: Process command
 fprintf('\nProcessing command...\n');
 response = processCommand(identifiedUser, command);

 fprintf('\n╔════════════════════════════════════════════╗\n');
 fprintf('║ ASSISTANT RESPONSE ║\n');
 fprintf('╚════════════════════════════════════════════╝\n');
 fprintf('%s\n\n', response);

 % Save to history
 saveToHistory(identifiedUser, command, response);
 end

 fprintf('\nAssistant session ended.\n');
 saveReminders();
 end
 function testVoiceMatching()
 fprintf('\n==============================================\n');
 fprintf(' VOICE MATCHING TEST & VISUALIZATION\n');
 fprintf('==============================================\n\n');

 % Load users
 files = dir(fullfile(ROOT_DB, '*.mat'));
 if isempty(files)
 fprintf('Error: No users registered.\n');
 return;
 end

 names = {};
 userDatabase = {};
 for i = 1:length(files)
 try
 S = load(fullfile(files(i).folder, files(i).name));

 % Check if 'user' field exists
 if isfield(S, 'user')
 userData = S.user;
 else
 userData = S;
 end

18
 % Validate user structure
 if ~isfield(userData, 'features') || ~isfield(userData, 'name')
 fprintf('Warning: Invalid user file %s - skipping\n', files(i).name);
 continue;
 end

 names{end+1} = userData.name; %#ok<AGROW>
 userDatabase{end+1} = userData.features; %#ok<AGROW>
 catch ME
 fprintf('Warning: Could not load %s - %s\n', files(i).name, ME.message);
 end
 end

 if isempty(names)
 fprintf('Error: No valid users found. Please re-register users.\n');
 return;
 end

 % Record test audio
 fprintf('Speak now (3 seconds)...\n');
 rec = audiorecorder(fs, 16, 1);
 recordblocking(rec, 3);
 audio = getaudiodata(rec);
 audio = audio / max(1e-6, max(abs(audio)));

 fprintf('Recording complete!\n\n');

 % Extract and identify
 testFeatures = extractFeatures(audio, fs);
 [identifiedUser, confidence, matchDetails] = identifySpeaker(testFeatures, userDatabase, names);

 % Display results
 displayMatchingResults(matchDetails, names);

 % Visualize
 visualizeVoiceComparison(testFeatures, userDatabase, names, matchDetails);

 fprintf('\n');
 if ~isempty(identifiedUser)
 fprintf('✓ IDENTIFIED AS: %s (Confidence: %.1f%%)\n', identifiedUser, confidence * 100);
 else
 fprintf('✗ UNKNOWN USER\n');
 end
 end
 function showCommands()
 fprintf('\n==============================================\n');
 fprintf(' AVAILABLE COMMANDS (20)\n');
19
 fprintf('==============================================\n\n');

 fprintf('TIME & DATE:\n');
 fprintf(' 1. "What time is it?" / "Tell me the time"\n');
 fprintf(' 2. "What is today''s date?" / "Tell me the date"\n\n');

 fprintf('REMINDERS:\n');
 fprintf(' 3. "Set a reminder" / "Remind me to..."\n');
 fprintf(' 4. "Show my reminders" / "List reminders"\n');
 fprintf(' 5. "Delete reminder" / "Remove reminder"\n\n');

 fprintf('SMART HOME:\n');
 fprintf(' 6. "Turn on the lights" / "Lights on"\n');
 fprintf(' 7. "Turn off the lights" / "Lights off"\n');
 fprintf(' 8. "Turn on the fan" / "Fan on"\n');
 fprintf(' 9. "Turn off the fan" / "Fan off"\n');
 fprintf(' 10. "Turn on AC" / "Air conditioner on"\n');
 fprintf(' 11. "Turn off AC" / "Air conditioner off"\n\n');

 fprintf('ENTERTAINMENT:\n');
 fprintf(' 12. "Play music" / "Start music"\n');
 fprintf(' 13. "Stop music" / "Pause music"\n');
 fprintf(' 14. "Tell me a joke"\n');
 fprintf(' 15. "Read the news" / "What''s the news"\n\n');

 fprintf('INFORMATION:\n');
 fprintf(' 16. "What''s the weather?" / "Weather forecast"\n');
 fprintf(' 17. "Calculate..." / "What is 5 plus 3"\n\n');

 fprintf('SYSTEM:\n');
 fprintf(' 18. "Help" / "Show commands"\n');
 fprintf(' 19. "Clear history" / "Delete my history"\n');
 fprintf(' 20. "Exit" / "Goodbye"\n\n');
 end
 function response = processCommand(user, commandText)
 commandLower = lower(commandText);
 userSafe = matlab.lang.makeValidName(user);

 % TIME
 if contains(commandLower, {'time', 'what time'})
 response = sprintf('Current time: %s', datestr(now, 'HH:MM:SS'));

 % DATE
 elseif contains(commandLower, {'date', 'today', 'what day'})
 response = sprintf('Today is %s', datestr(now, 'dddd, mmmm dd, yyyy'));

 % SET REMINDER
20
 elseif contains(commandLower, {'set reminder', 'remind me', 'add reminder', 'remember to'})
 fprintf('\n');
 detail = input('What should I remind you about? ', 's');
 when = input('When? (e.g., tomorrow 5pm, or press Enter for no time): ', 's');

 if ~isfield(reminders, userSafe)
 reminders.(userSafe) = {};
 end

 newReminder.item = detail;
 newReminder.when = when;
 newReminder.created = datestr(now);
 reminders.(userSafe){end+1} = newReminder;

 response = sprintf('✓ Reminder set: "%s"', detail);
 if ~isempty(when)
 response = [response sprintf(' for %s', when)];
 end

 % LIST REMINDERS
 elseif contains(commandLower, {'list reminders', 'show reminders', 'my reminders', 'view reminders'})
 if isfield(reminders, userSafe) && ~isempty(reminders.(userSafe))
 rList = reminders.(userSafe);
 response = sprintf('You have %d reminder(s):\n', length(rList));
 for i = 1:length(rList)
 if isempty(rList{i}.when)
 response = [response sprintf('\n %d. %s', i, rList{i}.item)];
 else
 response = [response sprintf('\n %d. %s (at: %s)', i, rList{i}.item, rList{i}.when)];
 end
 end
 else
 response = 'You have no reminders.';
 end

 % DELETE REMINDER
 elseif contains(commandLower, {'delete reminder', 'remove reminder', 'cancel reminder'})
 if isfield(reminders, userSafe) && ~isempty(reminders.(userSafe))
 rList = reminders.(userSafe);
 fprintf('\nYour reminders:\n');
 for i = 1:length(rList)
 fprintf(' %d. %s\n', i, rList{i}.item);
 end
 idx = input('Which number to delete? ');

 if ~isempty(idx) && idx >= 1 && idx <= length(rList)
 deleted = rList{idx}.item;
 rList(idx) = [];
21
 reminders.(userSafe) = rList;
 response = sprintf('✓ Deleted reminder: "%s"', deleted);
 else
 response = 'Invalid reminder number.';
 end
 else
 response = 'You have no reminders to delete.';
 end

 % LIGHTS ON
 elseif contains(commandLower, {'lights on', 'turn on lights', 'switch on lights'})
 response = '✓ Turning lights ON';

 % LIGHTS OFF
 elseif contains(commandLower, {'lights off', 'turn off lights', 'switch off lights'})
 response = '✓ Turning lights OFF';

 % FAN ON
 elseif contains(commandLower, {'fan on', 'turn on fan', 'start fan'})
 response = '✓ Turning fan ON';

 % FAN OFF
 elseif contains(commandLower, {'fan off', 'turn off fan', 'stop fan'})
 response = '✓ Turning fan OFF';

 % AC ON
 elseif contains(commandLower, {'ac on', 'air conditioner on', 'turn on ac', 'aircon on'})
 response = '✓ Turning air conditioner ON';

 % AC OFF
 elseif contains(commandLower, {'ac off', 'air conditioner off', 'turn off ac', 'aircon off'})
 response = '✓ Turning air conditioner OFF';

 % PLAY MUSIC
 elseif contains(commandLower, {'play music', 'start music', 'play song'})
 response = '♪ Playing music...';

 % STOP MUSIC
 elseif contains(commandLower, {'stop music', 'pause music', 'stop song'})
 response = '✓ Music stopped';

 % JOKE
 elseif contains(commandLower, {'joke', 'tell me a joke', 'make me laugh'})
 jokes = {
 'Why did the scarecrow win an award? Because he was outstanding in his field!';
 'Why don''t scientists trust atoms? Because they make up everything!';
 'What do you call a bear with no teeth? A gummy bear!';
22
 'Why did the bicycle fall over? It was two-tired!';
 'What do you call a fake noodle? An impasta!';
 'Why don''t eggs tell jokes? They''d crack each other up!';
 'What''s orange and sounds like a parrot? A carrot!';
 'Why did the math book look sad? Because it had too many problems!'
 };
 response = jokes{randi(length(jokes))};

 % NEWS
 elseif contains(commandLower, {'news', 'headlines', 'latest news'})
 response = 'Today''s headlines (offline mode):\n • Technology stocks showing strong performance\n •
Weather forecast: Partly cloudy with temperatures around 28°C\n • Local community event scheduled for this
weekend';

 % WEATHER
 elseif contains(commandLower, {'weather', 'temperature', 'forecast', 'raining'})
 response = sprintf('Weather for today:\n Temperature: 28°C\n Conditions: Partly cloudy\n Humidity:
65%%\n Wind: 10 km/h');

 % CALCULATOR
 elseif contains(commandLower, {'calculate', 'what is', 'plus', 'minus', 'times', 'divided'})
 response = 'Calculator: ';
 % Simple math parsing
 if contains(commandLower, 'plus') || contains(commandLower, '+')
 nums = regexp(commandLower, '\d+', 'match');
 if length(nums) >= 2
 result = str2double(nums{1}) + str2double(nums{2});
 response = [response sprintf('%s + %s = %.2f', nums{1}, nums{2}, result)];
 else
 response = 'Please say a calculation like "what is 5 plus 3"';
 end
 elseif contains(commandLower, 'minus') || contains(commandLower, '-')
 nums = regexp(commandLower, '\d+', 'match');
 if length(nums) >= 2
 result = str2double(nums{1}) - str2double(nums{2});
 response = [response sprintf('%s - %s = %.2f', nums{1}, nums{2}, result)];
 else
 response = 'Please say a calculation like "what is 10 minus 3"';
 end
 elseif contains(commandLower, {'times', 'multiply', 'multiplied'})
 nums = regexp(commandLower, '\d+', 'match');
 if length(nums) >= 2
 result = str2double(nums{1}) * str2double(nums{2});
 response = [response sprintf('%s × %s = %.2f', nums{1}, nums{2}, result)];
 else
 response = 'Please say a calculation like "what is 5 times 3"';
 end
 elseif contains(commandLower, {'divided', 'divide'})
23
 nums = regexp(commandLower, '\d+', 'match');
 if length(nums) >= 2
 if str2double(nums{2}) ~= 0
 result = str2double(nums{1}) / str2double(nums{2});
 response = [response sprintf('%s ÷ %s = %.2f', nums{1}, nums{2}, result)];
 else
 response = 'Cannot divide by zero!';
 end
 else
 response = 'Please say a calculation like "what is 10 divided by 2"';
 end
 else
 response = 'Say a calculation like "what is 5 plus 3"';
 end

 % HELP
 elseif contains(commandLower, {'help', 'commands', 'what can you do'})
 response = 'I can help with 20 commands:\n • Time & Date\n • Reminders (set, list, delete)\n • Smart
Home (lights, fan, AC)\n • Music control\n • Jokes & News\n • Weather & Calculator\n\nSay "show commands"
in the main menu for full list.';

 % CLEAR HISTORY
 elseif contains(commandLower, {'clear history', 'delete history', 'remove history'})
 histFile = fullfile(HISTORY_DIR, [userSafe '.txt']);
 if exist(histFile, 'file')
 delete(histFile);
 response = '✓ Your conversation history has been cleared.';
 else
 response = 'You have no history to clear.';
 end

 % EXIT
 elseif contains(commandLower, {'exit', 'quit', 'goodbye', 'bye'})
 response = 'Goodbye! Returning to main menu...';

 % UNKNOWN
 else
 response = sprintf('I didn''t understand "%s".\nTry saying "help" to see available commands.',
commandText);
 end
 end
 function viewUsersAndHistory()
 fprintf('\n==============================================\n');
 fprintf(' REGISTERED USERS & HISTORY\n');
 fprintf('==============================================\n\n');

 % List users
24
 files = dir(fullfile(ROOT_DB, '*.mat'));
 if isempty(files)
 fprintf('No users registered.\n');
 else
 fprintf('Registered Users:\n');
 for i = 1:length(files)
 try
 S = load(fullfile(files(i).folder, files(i).name));

 % Check if 'user' field exists
 if isfield(S, 'user')
 userData = S.user;
 else
 userData = S;
 end

 if isfield(userData, 'name')
 fprintf('%d. %s\n', i, userData.name);
 if isfield(userData, 'registered')
 fprintf(' Registered: %s\n', datestr(userData.registered));
 end
 if isfield(userData, 'features')
 fprintf(' Pitch: %.1f Hz\n', userData.features.pitch_mean);
 fprintf(' Energy: %.4f\n\n', userData.features.energy_mean);
 end
 end
 catch ME
 fprintf('%d. [Error loading user file: %s]\n', i, ME.message);
 end
 end
 end

 % List history files
 hFiles = dir(fullfile(HISTORY_DIR, '*.txt'));
 if ~isempty(hFiles)
 fprintf('\n--- Conversation History ---\n\n');
 for i = 1:length(hFiles)
 fprintf('User: %s\n', strrep(hFiles(i).name, '.txt', ''));
 fprintf('─────────────────────────────────────\n');
 txt = fileread(fullfile(hFiles(i).folder, hFiles(i).name));
 fprintf('%s\n', txt);
 end
 end

 % Show reminders
 if exist(REMINDERS_FILE, 'file')
 load(REMINDERS_FILE, 'reminders');
 if ~isempty(fieldnames(reminders))
25
 fprintf('\n--- Active Reminders ---\n');
 userFields = fieldnames(reminders);
 for i = 1:length(userFields)
 fprintf('\n%s:\n', userFields{i});
 rList = reminders.(userFields{i});
 for j = 1:length(rList)
 fprintf(' %d. %s', j, rList{j}.item);
 if ~isempty(rList{j}.when)
 fprintf(' (at: %s)', rList{j}.when);
 end
 fprintf('\n');
 end
 end
 end
 end
 end
 function deleteUser()
 files = dir(fullfile(ROOT_DB, '*.mat'));
 if isempty(files)
 fprintf('No users registered.\n');
 return;
 end

 fprintf('\nRegistered Users:\n');
 for i = 1:length(files)
 try
 S = load(fullfile(files(i).folder, files(i).name));

 % Check if 'user' field exists
 if isfield(S, 'user')
 userName = S.user.name;
 elseif isfield(S, 'name')
 userName = S.name;
 else
 userName = strrep(files(i).name, '.mat', '');
 end

 fprintf('%d. %s\n', i, userName);
 catch
 fprintf('%d. %s (corrupted)\n', i, strrep(files(i).name, '.mat', ''));
 end
 end

 idx = input('\nEnter user number to delete (0 to cancel): ');
 if idx > 0 && idx <= length(files)
 try
 S = load(fullfile(files(idx).folder, files(idx).name));
26
 if isfield(S, 'user')
 userName = S.user.name;
 elseif isfield(S, 'name')
 userName = S.name;
 else
 userName = strrep(files(idx).name, '.mat', '');
 end
 catch
 userName = strrep(files(idx).name, '.mat', '');
 end

 delete(fullfile(files(idx).folder, files(idx).name));
 fprintf('User "%s" deleted.\n', userName);
 end
 end
 function features = extractFeatures(audio, fs)
 % Pre-emphasis
 audio = filter([1, -0.97], 1, audio);

 % Remove silence
 audio = audio(abs(audio) > 0.01);
 if isempty(audio)
 audio = zeros(1000, 1);
 end

 % Extract MFCCs
 try
 coeffs = mfcc(audio, fs, 'NumCoeffs', NUM_MFCC);
 catch
 coeffs = zeros(100, NUM_MFCC);
 end

 % Extract pitch
 try
 [pitchVals, ~] = pitch(audio, fs, 'Range', [50, 400]);
 pitchVals = pitchVals(~isnan(pitchVals));
 if isempty(pitchVals)
 pitchVals = 150;
 end
 catch
 pitchVals = 150;
 end

 % Extract energy
 frameSize = min(round(0.025 * fs), length(audio));
 hopSize = round(0.010 * fs);
 numFrames = max(1, floor((length(audio) - frameSize) / hopSize) + 1);
27
 energy = zeros(numFrames, 1);

 for i = 1:numFrames
 startIdx = (i-1) * hopSize + 1;
 endIdx = min(startIdx + frameSize - 1, length(audio));
 if endIdx > startIdx
 frame = audio(startIdx:endIdx);
 energy(i) = sum(frame.^2);
 end
 end

 % Store features
 features.mfcc_mean = mean(coeffs, 1);
 features.mfcc_std = std(coeffs, 0, 1);
 features.pitch_mean = mean(pitchVals);
 features.pitch_std = std(pitchVals);
 features.energy_mean = mean(energy);
 features.energy_std = std(energy);

 features.vector = [features.mfcc_mean, features.mfcc_std, ...
 features.pitch_mean, features.pitch_std, ...
 features.energy_mean, features.energy_std];
 end
 function [identifiedUser, confidence, matchDetails] = identifySpeaker(testFeatures, userDatabase, names)
 numUsers = length(names);
 distances = zeros(numUsers, 1);
 matchDetails = struct('userName', {}, 'distance', {}, 'pitchDiff', {}, 'energyDiff', {}, 'mfccDist', {});

 for i = 1:numUsers
 distances(i) = norm(testFeatures.vector - userDatabase{i}.vector);

 pitchDiff = abs(testFeatures.pitch_mean - userDatabase{i}.pitch_mean);
 energyDiff = abs(testFeatures.energy_mean - userDatabase{i}.energy_mean);
 mfccDist = norm(testFeatures.mfcc_mean - userDatabase{i}.mfcc_mean);

 matchDetails(i).userName = names{i};
 matchDetails(i).distance = distances(i);
 matchDetails(i).pitchDiff = pitchDiff;
 matchDetails(i).energyDiff = energyDiff;
 matchDetails(i).mfccDist = mfccDist;
 matchDetails(i).testPitch = testFeatures.pitch_mean;
 matchDetails(i).refPitch = userDatabase{i}.pitch_mean;
 matchDetails(i).testEnergy = testFeatures.energy_mean;
 matchDetails(i).refEnergy = userDatabase{i}.energy_mean;
 end

 [minDist, idx] = min(distances);
28

 threshold = ID_THRESHOLD + (numUsers - 1) * 3;

 if minDist < threshold
 identifiedUser = names{idx};
 confidence = max(0, 1 - (minDist / threshold));
 else
 identifiedUser = '';
 confidence = 0;
 end
 end
 function displayMatchingResults(matchDetails, names)
 numUsers = length(matchDetails);

 fprintf('\n--- Voice Comparison Results ---\n');

fprintf('─────────────────────────────────────────────────────────\n');

 [~, sortIdx] = sort([matchDetails.distance]);

 for i = 1:numUsers
 idx = sortIdx(i);
 detail = matchDetails(idx);
 matchScore = max(0, 100 - (detail.distance * 4));

 fprintf('\n');
 if i == 1
 fprintf('★ BEST MATCH: %s (Score: %.1f%%)\n', detail.userName, matchScore);
 else
 fprintf(' User: %s (Score: %.1f%%)\n', detail.userName, matchScore);
 end

 fprintf(' Distance: %.2f\n', detail.distance);
 fprintf(' Pitch: Test=%.1fHz, User=%.1fHz, Diff=%.1fHz\n', ...
 detail.testPitch, detail.refPitch, detail.pitchDiff);
 fprintf(' Energy: Test=%.4f, User=%.4f, Diff=%.4f\n', ...
 detail.testEnergy, detail.refEnergy, detail.energyDiff);
 fprintf(' MFCC Distance: %.2f\n', detail.mfccDist);
 end


fprintf('─────────────────────────────────────────────────────────\n');
 end
 function visualizeVoiceComparison(testFeatures, userDatabase, names, matchDetails)
 numUsers = length(names);

29
 figure('Name', 'Voice Comparison Analysis', 'Position', [100, 100, 1200, 800]);

 % Pitch comparison
 subplot(2, 3, 1);
 testPitch = testFeatures.pitch_mean;
 refPitches = zeros(numUsers, 1);
 for i = 1:numUsers
 refPitches(i) = userDatabase{i}.pitch_mean;
 end
 bar(1:numUsers, refPitches, 'FaceColor', [0.3, 0.6, 0.9]);
 hold on;
 plot(1:numUsers, ones(numUsers,1)*testPitch, 'r-', 'LineWidth', 3);
 hold off;
 set(gca, 'XTick', 1:numUsers, 'XTickLabel', names);
 ylabel('Pitch (Hz)');
 title('Pitch Comparison');
 legend('Registered Users', 'Test Voice');
 grid on;

 % Energy comparison
 subplot(2, 3, 2);
 testEnergy = testFeatures.energy_mean;
 refEnergies = zeros(numUsers, 1);
 for i = 1:numUsers
 refEnergies(i) = userDatabase{i}.energy_mean;
 end
 bar(1:numUsers, refEnergies, 'FaceColor', [0.9, 0.6, 0.3]);
 hold on;
 plot(1:numUsers, ones(numUsers,1)*testEnergy, 'r-', 'LineWidth', 3);
 hold off;
 set(gca, 'XTick', 1:numUsers, 'XTickLabel', names);
 ylabel('Energy');
 title('Energy Comparison');
 legend('Registered Users', 'Test Voice');
 grid on;

 % Overall distance
 subplot(2, 3, 3);
 distances = [matchDetails.distance];
 [~, bestIdx] = min(distances);
 colors = repmat([0.7, 0.7, 0.7], numUsers, 1);
 colors(bestIdx, :) = [0.2, 0.8, 0.2];
 for i = 1:numUsers
 bar(i, distances(i), 'FaceColor', colors(i,:));
 hold on;
 end
 hold off;
 set(gca, 'XTick', 1:numUsers, 'XTickLabel', names);
30
 ylabel('Distance');
 title('Overall Distance (Lower = Better)');
 grid on;

 % MFCC distance
 subplot(2, 3, 4);
 mfccDists = [matchDetails.mfccDist];
 bar(1:numUsers, mfccDists, 'FaceColor', [0.6, 0.3, 0.9]);
 set(gca, 'XTick', 1:numUsers, 'XTickLabel', names);
 ylabel('MFCC Distance');
 title('Voice Signature Distance');
 grid on;

 % Match score
 subplot(2, 3, 5);
 matchScores = max(0, 100 - (distances * 4));
 for i = 1:numUsers
 if i == bestIdx
 bar(i, matchScores(i), 'FaceColor', [0.2, 0.8, 0.2]);
 else
 bar(i, matchScores(i), 'FaceColor', [0.7, 0.7, 0.7]);
 end
 hold on;
 end
 hold off;
 set(gca, 'XTick', 1:numUsers, 'XTickLabel', names);
 ylabel('Match Score (%)');
 title('Match Score (Higher = Better)');
 ylim([0, 100]);
 grid on;

 % Feature comparison
 subplot(2, 3, 6);
 pitchRatio = testFeatures.pitch_mean / userDatabase{bestIdx}.pitch_mean;
 energyRatio = testFeatures.energy_mean / userDatabase{bestIdx}.energy_mean;
 mfccRatio = norm(testFeatures.mfcc_mean) / norm(userDatabase{bestIdx}.mfcc_mean);

 categories = {'Pitch', 'Energy', 'MFCC'};
 x = 1:3;
 bar(x-0.2, [1, 1, 1], 0.4, 'FaceColor', [0.3, 0.6, 0.9]);
 hold on;
 bar(x+0.2, [pitchRatio, energyRatio, mfccRatio], 0.4, 'FaceColor', [0.9, 0.3, 0.3]);
 hold off;
 set(gca, 'XTick', 1:3, 'XTickLabel', categories);
 ylabel('Normalized Ratio');
 title(['Feature Match with ' names{bestIdx}]);
 legend('Reference', 'Test Voice');
 ylim([0, 2]);
31
 grid on;

 sgtitle('Voice Recognition Analysis Dashboard', 'FontSize', 14, 'FontWeight', 'bold');
 end
 function command = transcribeAudio(audio, fs)
 % Try speech-to-text
 try
 command = char(speech2text(audio, fs));
 command = strtrim(command);
 if isempty(command)
 error('Empty transcription');
 end
 catch
 fprintf('Speech-to-text unavailable. Please type your command:\n');
 command = input('>> ', 's');
 end
 end
 function saveToHistory(user, command, response)
 userSafe = matlab.lang.makeValidName(user);
 histFile = fullfile(HISTORY_DIR, [userSafe '.txt']);
 timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

 fid = fopen(histFile, 'a');
 fprintf(fid, '[%s]\n', timestamp);
 fprintf(fid, 'Command: %s\n', command);
 fprintf(fid, 'Response: %s\n\n', response);
 fclose(fid);
 end
 function saveReminders()
 try
 save(REMINDERS_FILE, 'reminders');
 catch
 warning('Could not save reminders.')
 end
 end
end
