/**
 * Custom pawn class used by the KFStatsX mutator.  
 * Injects stat tracking code above the KFHumanPawn class 
 * to log events such as money spent, damage taken, etc...
 * @author etsai (Scary Ghost)
 */
class KFSXHumanPawn extends KFHumanPawn;

function DeactivateSpawnProtection() {
    local int mode;
    local string itemName;
    local float load;
    super.DeactivateSpawnProtection();
    
    if (Weapon.isFiring() && Syringe(Weapon) == none && 
            Welder(Weapon) == none && Huskgun(Weapon) == none) {
        itemName= Weapon.ItemName;
        if (Weapon.GetFireMode(1).bIsFiring)
            mode= 1;

        if (KFMeleeGun(Weapon) != none || (mode == 1 && MP7MMedicGun(Weapon) != none)) {
            load= 1;
        } else {
            load= Weapon.GetFireMode(mode).Load;
        }

        if (mode == 1 && (MP7MMedicGun(Weapon) != none || 
                (KFWeapon(Weapon) != none && KFWeapon(Weapon).bHasSecondaryAmmo))) {
            itemName$= " Alt";
        }

        KFSXPlayerController(Controller).weaponLRI.accum(itemName, load);
    }
}

function ServerBuyWeapon( Class<Weapon> WClass ) {
    local int oldScore;

    oldScore= PlayerReplicationInfo.Score;
    super.ServerBuyWeapon(WClass);
    KFSXPlayerController(Controller).playerLRI.accum(KFSXPlayerController(Controller).playerLRI.STAT_CASH, 
            oldScore - PlayerReplicationInfo.Score);
}

function ServerBuyAmmo( Class<Ammunition> AClass, bool bOnlyClip ) {
    local int oldScore;

    oldScore= PlayerReplicationInfo.Score;
    super.ServerBuyAmmo(AClass, bOnlyClip);
    KFSXPlayerController(Controller).playerLRI.accum(KFSXPlayerController(Controller).playerLRI.STAT_CASH, 
            oldScore - PlayerReplicationInfo.Score);
}

function ServerBuyKevlar() {
    local int oldScore;

    oldScore= PlayerReplicationInfo.Score;
    super.ServerBuyKevlar();
    KFSXPlayerController(Controller).playerLRI.accum(KFSXPlayerController(Controller).playerLRI.STAT_CASH, 
        oldScore - PlayerReplicationInfo.Score);
}
