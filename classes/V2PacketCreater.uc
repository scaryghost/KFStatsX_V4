class V2PacketCreater extends PacketCreater;

var private PacketCreater.MatchInfo matchInformation;

function array<string> createPlayerPackets(PacketCreater.PlayerInfo info) {
    local string baseMsg;
    local int i;
    local array<string> packets, parts;
        
    baseMsg= generateHeader(playerHeader) $ separator $ info.steamID64;

    parts[0]= baseMsg;
    for(i= 0; i < info.stats.Length; i++) {
        parts[1]= string(i);
        parts[2]= info.stats[i].category;
        parts[3]= getStatValues(info.stats[i].statsMap);
        packets[i]= join(parts, separator);
    }

    parts[1]= string(packets.Length);
    parts[2]= "match";
    parts[3]= matchInformation.map;
    parts[4]= matchInformation.difficulty;
    parts[5]= matchInformation.length;
    if (info.levelSwitching && info.endGameType == 0) {
        parts[6]= "1";
    } else {
        parts[6]= string(info.endGameType);
    }
    parts[7]= string(info.wave);
    parts[8]= string(info.reachedFinalWave);
    parts[9]= string(info.survivedFinalWave);
    parts[10]= string(info.timeConnected);
    parts[11]= "_close";
    packets[packets.Length]= join(parts, separator);

    return packets;
}

function string createWaveInfoPacket(SortedMap stats, int wave, string category) {
    local array<string> packetParts;

    packetParts[0]= generateHeader(matchHeader);
    packetParts[1]= category;
    packetParts[2]= matchInformation.difficulty;
    packetParts[3]= matchInformation.length;
    packetParts[4]= string(wave);
    packetParts[5]= matchInformation.map;
    packetParts[6]= getStatValues(stats);
    packetParts[7]= "_close";

    return join(packetParts, separator);
}

function string createMatchResultPacket(int wave, int elapsedTime, int endGameType) {
    local array<string> matchParts;

    matchParts[0]= generateHeader(matchHeader);
    matchParts[1]= "result";
    matchParts[2]= matchInformation.difficulty;
    matchParts[3]= matchInformation.length;
    matchParts[4]= string(wave);
    matchParts[5]= matchInformation.map;
    matchParts[6]= string(elapsedTime);
    if (endGameType == 0) {
        matchParts[7]= "1";
    } else {
        matchParts[7]= string(endGameType);
    }
    matchParts[8]= "_close";
    return join(matchParts, separator);
}

function string createMatchInfoPacket(PacketCreater.MatchInfo info) {
    matchInformation= info;
    return "";
}

defaultproperties {
    matchHeader=(version=2,protocol="kfstatsx-match")
    playerHeader=(version=2,protocol="kfstatsx-player")
}
