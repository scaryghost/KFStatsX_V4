/**
 * Maintains the remote tracking server information and 
 * handles the packet broadcasting
 * @author etsai (Scary Ghost)
 */
class RemoteServerLink extends UDPLink;

/** UDP port number the packets are broadcasted from */
var int udpPort;
/** Address of the remote tracking server */
var IpAddr serverAddr;

/** Stores map name, difficulty, and length */
var string mapName, difficulty, length;

/** Character to separate packet information */
var string packetSeparator;
/** Protocol name for the match informatiion scheme */
var string matchProtocol;
/** Version of the match informatiion scheme */
var string matchProtocolVersion;
/** Protocol name for the player informatiion scheme */
var string playerProtocol;
/** Version of the player informatiion scheme */
var string playerProtocolVersion;

var array<string> difficulties, lengths;
var string matchHeader, playerHeader;
var string killsKey, assistsKey;

function PostBeginPlay() {
    local KFGameType gametype;
    local array<string> parts;
    local int i;

    udpPort= BindPort();
    if (udpPort > 0) Resolve(class'KFSXMutator'.default.serverAddress);

    gametype= KFGameType(Level.Game);
    Split(gametype.GIPropsExtras[0], ";", parts);
    for(i= 0; i < parts.Length; i+= 2)
        difficulties[int(parts[i])]= parts[i+1];
    Split(gametype.GIPropsExtras[1], ";", parts);
    for(i= 0; i < parts.Length; i+= 2)
        lengths[int(parts[i])]= parts[i+1];

    matchHeader= matchProtocol $ "," $ matchProtocolVersion $ "," $ class'KFSXMutator'.default.serverPwd;
}

event Resolved(IpAddr addr) {
    serverAddr= addr;
    serverAddr.port= class'KFSXMutator'.default.serverPort;
}

/**
 * Initialize matchData with map name, difficulty, and length
 */
function MatchStarting() {
    mapName= locs(Left(string(Level), InStr(string(Level), ".")));
    difficulty= difficulties[int(Level.Game.GameDifficulty)];
    length= lengths[KFGameType(Level.Game).KFGameLength];
}

/**
 * Send the match information to the remote server
 */
function broadcastMatchResults() {
    local array<string> matchParts;

    matchParts[0]= matchHeader;
    matchParts[1]= "result";
    matchParts[2]= difficulty;
    matchParts[3]= length;
    matchParts[4]= string(KFGameType(Level.Game).WaveNum + 1);
    matchParts[5]= mapName;
    matchParts[6]= string(Level.GRI.ElapsedTime);
    matchParts[7]= string(KFGameReplicationInfo(Level.GRI).EndGameType);
    matchParts[8]= "_close";
    SendText(serverAddr, join(matchParts, packetSeparator));
}    

/**
 * Send wave specific stats to the remote server
 */
function broadcastWaveInfo(SortedMap stats, int wave, string group) {
    local array<string> packetParts;

    packetParts[0]= matchHeader;
    packetParts[1]= group;
    packetParts[2]= difficulty;
    packetParts[3]= length;
    packetParts[4]= string(wave);
    packetParts[5]= mapName;
    packetParts[6]= getStatValues(stats);
    packetParts[7]= "_close";
    SendText(serverAddr, join(packetParts, packetSeparator));
}

/**
 * Convert the entries in the SortedMap into 
 * comma separated ${key}=${value} pairs
 */
function string getStatValues(SortedMap stats) {
    local string statVals;
    local int i;
    local bool addComma;

    for(i= 0; i < stats.maxStatIndex; i++) {
        if (stats.values[i] != 0) {
            if (addComma) statVals$= ",";
            statVals$= stats.keys[i] $ "=" $ int(round(stats.values[i]));
            addComma= true;
        }
    }
    return statVals;
}

/**
 * Broadcast the stat objects from the custom replication info tied to the given pri
 * @param   pri  The PlayerReplicationInfo object to save
 */
function broadcastPlayerStats(PlayerReplicationInfo pri) {
    local string baseMsg;
    local array<string> statMsgs, resultParts;
    local int index, realWaveNum, timeConnected;
    local KFSXReplicationInfo kfsxri;
    local bool reachedFinale;

    timeConnected= Level.GRI.ElapsedTime - pri.StartTime;
    if (timeConnected != 0) {
        kfsxri= class'KFSXReplicationInfo'.static.findKFSXri(pri);
        if (KFPlayerReplicationInfo(pri) != none) {
            kfsxri.summary.put(assistsKey, KFPlayerReplicationInfo(pri).KillAssists);
        }
        kfsxri.summary.put(killsKey, pri.Kills);
        baseMsg= playerProtocol $ "," $ playerProtocolVersion $ "," $ 
            class'KFSXMutator'.default.serverPwd $ packetSeparator $ kfsxri.playerIDHash $ packetSeparator;

        statMsgs[statMsgs.Length]= "0" $ packetSeparator $ "summary" $ packetSeparator $ getStatValues(kfsxri.summary);
        statMsgs[statMsgs.Length]= "1" $ packetSeparator $ "weapons" $ packetSeparator $ getStatValues(kfsxri.weapons);
        statMsgs[statMsgs.Length]= "2" $ packetSeparator $ "kills" $ packetSeparator $ getStatValues(kfsxri.kills);
        statMsgs[statMsgs.Length]= "3" $ packetSeparator $ "perks" $ packetSeparator $ getStatValues(kfsxri.perks);
        statMsgs[statMsgs.Length]= "4" $ packetSeparator $ "actions" $ packetSeparator $ getStatValues(kfsxri.actions);
        statMsgs[statMsgs.Length]= "5" $ packetSeparator $ "deaths" $ packetSeparator $ getStatValues(kfsxri.deaths);

        realWaveNum= KFGameType(Level.Game).WaveNum + 1;
        reachedFinale= realWaveNum > KFGameType(Level.Game).FinalWave;
        resultParts[0]= "6";
        resultParts[1]= "match";
        resultParts[2]= mapName;
        resultParts[3]= difficulty;
        resultParts[4]= length;
        resultParts[5]= string(KFGameReplicationInfo(Level.GRI).EndGameType);
        resultParts[6]= string(realWaveNum);
        resultParts[7]= string(byte(reachedFinale));
        resultParts[8]= string(byte(!pri.bOnlySpectator && kfsxri.survivedFinale && reachedFinale));
        resultParts[9]= string(timeConnected);
        resultPArts[10]= "_close";

        statMsgs[statMsgs.Length]= join(resultParts, packetSeparator);
        for(index= 0; index < statMsgs.Length; index++) {
            SendText(serverAddr, baseMsg $ statMsgs[index]);
        }
    }
}

function string join(array<string> parts, string separator) {
    local int i;
    local string whole;

    for(i= 0; i < parts.Length; i++) {
        if (i != 0) {
            whole$= separator;
        }
        whole$= parts[i];
    }
    return whole;
}

defaultproperties {
    packetSeparator= "|"
    matchProtocol= "kfstatsx-match";
    matchProtocolVersion= "2";
    playerProtocol= "kfstatsx-player";
    playerProtocolVersion= "2";

    killsKey= "Kills"
    assistsKey= "Kill Assists"
}
