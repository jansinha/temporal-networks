% Fiona Pigott
% Jan 29 2014
% MATLAB v.2012b

% Find the probability distribution for the number of connections that 
% each node has in each time step.

% INPUT: 'data', 'unweighted', 'numnodes', 'nummat' all from Graphs.mat
% OUTPUT:
%   k: Matrix with dimensions (# nodes) X (# time steps)
%      k(i,m) = the number of nearest neighbors that i has at time m
%   averagek: the average value of k (across all nodes) per time step
%      length (# time steps)
%   variancek: the average value of k^2 (across all nodes) per time step
%      length (# time steps)
%   R: k^2/k. vector with length (# time steps) should estimate the 
%      average number of neighbors that each neighbor has
%   N: Matrix with dimensions (max # of connections of any peroson) X
%      (# time steps). N(k,m) is the number of people with k-1 connectiions
%      at a given time step m.
%   POnlyParticipants: Dimention (max # of nearest neighbors for a node 
%      in the data set) X (# time steps). P(k,m) is the probability of a
%      participating node having k nearest neighbors.
%   PAllNodes: Dimention (max # of nearest neighbors for a node 
%      in the data set) X (# time steps). P(k,m) is the probability of
%      any node having k nearest neighbors in the time step m.
%   PsOnlyParticipants: Dimention (max strength of any node 
%      in the data set) X (# time steps). P(s,m) is the probability of a
%      participating node having strength s.
%   PsAllNodes: Dimention (max strength of any node 
%      X (# time steps). P(s,m) is the probability of
%      any node having strength s at the time step m.
%   knn: Matrix with dimensions (# nodes) X (# time steps)
%      knn(i,m) = the average number of nearest neighbors that the 
%      nearest neighbors of node i have
%   knnSorted: calculate knn(k). knnSorted(k,1) = the average number of 
%       nearest neighbors that nodes with degree k have
%       knnSorted(k,2) = the number of nodes with k that went into
%       that average
%   knnSorted(k,2) = the number of nodes that went into the average
%      knnweighted: weighted average nearest neighbors degreee. same dim/
%      properties as knn. Formula from TareasV1.pdf #12
%   sFunction: the weight of the node i as a function of its degree.
%       knnSorted(k,1) = the average number of nearest neighbors that 
%       nodes with degree k have knnSorted(k,2) = the number of nodes
%       with k that went into that average


% tic
%----------------------------------------------------------------------
% k = number of connections that each person has
%     sum along rows in each unweighted time step adjacency matrix
%     Result is a (# nodes) X (#time steps) matrix where 
%     k(i,m) = the number of nearest neighbors that i has at time m

k = squeeze(sum(unweighted,2));
s = squeeze(sum(data,2));
% Find the average number of nearest-neighbor connections per time step
% Vectors with length (#time steps)
averagek = zeros(nummat,1);
variancek = zeros(nummat,1);
for m = 1:nummat
    km = k(:,m);
    km = km(km~=0);
    averagek(m) = mean(km,1);
    variancek(m) = mean(km.^2,1);
end
% R = <k^2>/<k>
R = variancek ./ averagek;

clear km

%-----------------------------------------------------------------------
% N
% N contains 1 column for each month, where N(k,m) is the number
% of people with k-1 nearest neighbors at a given month m

maxEdges = max(k); % Find how many rows N needs
N = zeros(max(maxEdges)+1,nummat); % Initialize N

for m = 1:nummat %For each time step
    % Use accumarray with indices k(:,m)+1 and values 1
    % Adds 1 to N(k,m) for every entry where k(:,m)+1 = k
    N(1:maxEdges(m)+1,m)=accumarray(k(:,m)+1,1);
end

%-----------------------------------------------------------------------
% Probability distributions

% PAllNodes takes into account all nodes (even the ones who have no 
% connections at time m). This is NOT recommended for use, because
% a significant number of nodes are absent from the network at any
% given time.
PAllNodes = zeros(max(maxEdges)+1,nummat);
PsAllNodes = zeros(max(max(s)),nummat);
for m = 1:nummat
    PAllNodes(:,m) = N(:,m)/numnodes;
    PsAllNodes(1:max(s(:,m))+1,m) = accumarray(s(:,m)+1,1)/numnodes;
end

% POnlyParticipants take into account on nodes with at least one 
% connection at time m. This is used to estimate the probabilty of
% a node who is present in the network having X number of 
% nearest neighbors  or X strength.
POnlyParticipants = zeros(max(maxEdges),nummat);
PsOnlyParticipants = zeros(max(max(s)),nummat);
Ns = zeros(max(max(s)),1);
for m = 1:nummat
    POnlyParticipants(:,m) = N(2:end,m)/sum(N(2:end,m));
    Ns = accumarray(s(:,m)+1,1);
    PsOnlyParticipants(1:max(s(:,m)),m) = Ns(2:end)/sum(N(2:end,m));
end

% % Find the integral form of Ps
Ps = mean(PsOnlyParticipants,2);
for n = 1:length(PsOnlyParticipants)
    PsSum(n) = sum(Ps(1:n));
end
% %-----------------------------------------------------------------------
% Find ki*kj so that later we can graph 
% Wij (weight of the interaction between ki & kj) versus log(ki*kj) 

%tic
kikj = zeros(numnodes,numnodes,nummat);
for m = 1:nummat
    for ii = 1:numnodes
        for jj = 1:numnodes
            kikj(ii,jj,m) = k(ii,m)*k(jj,m);
        end
    end
end
%toc

%-----------------------------------------------------------------------
% Knn
% Calculate the actual nearest neighbors degree
knn = zeros(numnodes,nummat);
for m = 1:nummat % For time steps m
    for ii = 1:numnodes % For all nodes i
        if k(ii,m) ~= 0 % If k has no neighbors, knn == 0
            jj = find(unweighted(ii,:,m)==1); % Find the nodes that i
                                              % has interactions with (j)
            knn(ii,m) = mean(k(jj,m)); % Find the average number of 
                                     % nearest-neighbors that each j has
        end
    end
end

% knnSorted(k,1) = the average knn that
% nodes with degree k have
% knnSorted(k,2) = the number of nodes that went into the average
knnSorted = zeros(max(max(k)),2);
for n = 1:(nummat*numnodes)
    if k(n) ~= 0
        knnSorted(k(n),1) = knnSorted(k(n),1) + knn(n);
        knnSorted(k(n),2) = knnSorted(k(n),2) + 1;
    end
end
knnSorted(:,1) = knnSorted(:,1)./knnSorted(:,2);


% knnweighted
% Calculate the weighted average nearest neighbors degree
knnweighted = zeros(numnodes,nummat);
s = squeeze(sum(data,2));
for m = 1:nummat % For time steps m
    for ii = 1:numnodes % For all nodes i
        if k(ii,m) ~= 0 % If k has no neighbors, knn == 0
            jj = find(unweighted(ii,:,m)==1); % Find the nodes that i
                                              % has interactions with (j)
            % Find the weighted average number of 
            % nearest-neighbor connections that each j has
            knnweighted(ii,m) = ...
                dot(data(ii,jj,m),k(jj,m))/s(ii,m); 
                           
        end
    end
end

averageknn = zeros(nummat,1);
for m = 1:nummat
    knnm = knn(:,m);
    knnm = knnm(knnm~=0);
    averageknn(m) = mean(knnm,1);
end

% ------------------------------------------------------------------
% sFunction(k) = the average value of s that nodes with degree k have
sFunction = zeros(max(max(k)),2);
weights = squeeze(sum(data,2));
for n = 1:(nummat*numnodes)
    if k(n) ~= 0
        sFunction(k(n),1) = sFunction(k(n),1) + weights(n);
        sFunction(k(n),2) = sFunction(k(n),2) + 1;
    end
end
sFunction(:,1) = sFunction(:,1)./sFunction(:,2);
%-------------------------------------------------------------------

if randomizeTime == 1
    save('edgeDistributionRandTime.mat','R','averagek',...
        'variancek','N','PAllNodes','POnlyParticipants',...
        'knn','k','kikj','knnweighted','averageknn','sFunction')
else
    save('edgeDistribution.mat','R','averagek',...
        'variancek','N','PAllNodes','POnlyParticipants',...
        'knn','k','kikj','knnweighted','averageknn','sFunction')
end


%toc