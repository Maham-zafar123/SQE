% Parameters for X-Machiavel and Simulation
Tw = 0.01;                  % Backoff time (Tw)
P1_Preamble_Length = 0.1;   % Preamble duration (seconds)
DataPacketLength = 0.05;    % Data packet transmission time (seconds)

% Simulation parameters
numNodes = 6;               % Number of mobile nodes
numIterations = 50;         % Number of simulation iterations
gridSize = 100;             % Size of simulation area (100x100)
energyPerMove = 0.005;      % Energy consumed per movement step
energyInitial = 100;        % Initial energy for each node

% Initialize node properties
nodePositions = rand(numNodes, 2) * gridSize;
nodeEnergy = ones(numNodes, 1) * energyInitial;
successfulTransmissions = 0;
failedTransmissions = 0;
totalCollisions = 0;
totalEnergyConsumed = 0;

% Metrics tracking
handoverDelays = [];
handoverSuccesses = 0;
handoverAttempts = 0;
packetDeliveryCount = 0;
totalPacketsSent = 0;
endToEndDelays = [];
oneHopDelays = [];

% Initialize paths for visualization
nodePaths = cell(numNodes, 1);

% Visualization setup
figure;
hold on;

% Sleep state and energy usage
energyIdle = 0.01;
energyTransmissionLow = 0.3;
energyTransmissionHigh = 0.7;
distanceThreshold = 10;

for iteration = 1:numIterations
    % Random movement and boundary enforcement
    nodePositions = nodePositions + randn(numNodes, 2) * 2;
    nodePositions = max(min(nodePositions, gridSize), 0);

    % Store paths for visualization
    for nodeID = 1:numNodes
        nodePaths{nodeID} = [nodePaths{nodeID}; nodePositions(nodeID, :)];
    end

    % Plot paths and node energy levels
    clf;
    hold on;
    for nodeID = 1:numNodes
        plot(nodePaths{nodeID}(:, 1), nodePaths{nodeID}(:, 2), 'LineWidth', 1.5);
    end
    energyLevels = nodeEnergy / energyInitial;
    scatter(nodePositions(:, 1), nodePositions(:, 2), 50, energyLevels, 'filled');
    colormap('jet');
    colorbar;
    title(['Iteration ' num2str(iteration)]);
    xlim([0 gridSize]);
    ylim([0 gridSize]);
    grid on;
    pause(0.1);

    % Deduct movement energy
    nodeEnergy = nodeEnergy - energyPerMove;
    totalEnergyConsumed = totalEnergyConsumed + sum(energyPerMove);

    for nodeID = 1:numNodes
        if nodeEnergy(nodeID) <= 0, continue; end

        if rand() < 0.2 % 20% chance of sending data
            pause(Tw);
            totalEnergyConsumed = totalEnergyConsumed + energyIdle;

            if rand() < 0.7 % 70% chance of successful channel access
                % Distance calculation
                receiverID = randi([1 numNodes]);
                distance = norm(nodePositions(nodeID, :) - nodePositions(receiverID, :));
                totalPacketsSent = totalPacketsSent + 1;

                % Adaptive power control
                if distance < distanceThreshold
                    energyPerTransmission = energyTransmissionLow;
                else
                    energyPerTransmission = energyTransmissionHigh;
                end
                nodeEnergy(nodeID) = nodeEnergy(nodeID) - energyPerTransmission;
                totalEnergyConsumed = totalEnergyConsumed + energyPerTransmission;

                % One-hop delay calculation
                oneHopDelay = Tw + P1_Preamble_Length + DataPacketLength;
                oneHopDelays = [oneHopDelays, oneHopDelay];

                % End-to-end delay tracking
                endToEndDelay = sum(oneHopDelays);
                endToEndDelays = [endToEndDelays, endToEndDelay];

                % Collision check
                collidingNodes = find(vecnorm(nodePositions - nodePositions(nodeID, :), 2, 2) < distanceThreshold);
                if numel(collidingNodes) > 1
                    failedTransmissions = failedTransmissions + 1;
                    totalCollisions = totalCollisions + numel(collidingNodes) - 1;
                    disp(['Node ' num2str(nodeID) ' transmission collided with ' num2str(numel(collidingNodes) - 1) ' nodes.']);
                else
                    successfulTransmissions = successfulTransmissions + 1;
                    disp(['Node ' num2str(nodeID) ' successfully transmitted data.']);
                    packetDeliveryCount = packetDeliveryCount + 1;
                end

                % Handover simulation
                handoverAttempts = handoverAttempts + 1;
                if rand() < 0.8
                    handoverSuccesses = handoverSuccesses + 1;
                    handoverDelays = [handoverDelays, rand() * 3];
                end
            else
                failedTransmissions = failedTransmissions + 1;
                disp(['Node ' num2str(nodeID) ' transmission failed.']);
            end
        end
    end
end

% Calculate metrics
avgHandoverDelay = mean(handoverDelays);
avgHandoverSuccessRate = (handoverSuccesses / handoverAttempts) * 100;
avgEnergyConsumption = totalEnergyConsumed / numNodes;
avgPacketDeliveryRatio = (packetDeliveryCount / totalPacketsSent) * 100;
avgEndToEndDelay = mean(endToEndDelays);
avgOneHopDelay = mean(oneHopDelays);

% Display summary
disp('Simulation Summary:');
disp(['Average Handover Delay: ', num2str(avgHandoverDelay)]);
disp(['Average Handover Success Rate: ', num2str(avgHandoverSuccessRate), '%']);
disp(['Average Energy Consumption per Node: ', num2str(avgEnergyConsumption)]);
disp(['Average Packet Delivery Ratio: ', num2str(avgPacketDeliveryRatio), '%']);
disp(['Average End-to-End Delay: ', num2str(avgEndToEndDelay)]);
disp(['Average One-Hop Delay: ', num2str(avgOneHopDelay)]);
disp(['Successful Transmissions: ', num2str(successfulTransmissions)]);
disp(['Failed Transmissions: ', num2str(failedTransmissions)]);
disp(['Total Collisions: ', num2str(totalCollisions)]);
disp('Remaining Energy (Per Node):');
disp(nodeEnergy);

% Plot bar chart for performance metrics
figure;
metrics = [avgHandoverDelay, avgHandoverSuccessRate, avgEnergyConsumption, avgPacketDeliveryRatio, avgEndToEndDelay, avgOneHopDelay];
bar(metrics);
set(gca, 'XTickLabel', {'Handover Delay', 'Success Rate', 'Energy Consumption', 'Delivery Ratio', 'End-to-End Delay', '1-Hop Delay'});
ylabel('Metrics');
title('Performance Metrics of X-Machiavel Simulation');
grid on;
