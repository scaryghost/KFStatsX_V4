class FragFire_KFSX extends FragFire;

function projectile SpawnProjectile(Vector Start, Rotator Dir) {
    local class<Projectile> g;

    /** Copied from FragFire.SpawnProjectile */
    if ( KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo) != none && 
        KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo).ClientVeteranSkill != none ) {
        g= KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo)
            .ClientVeteranSkill.Static.GetNadeType(KFPlayerReplicationInfo(Instigator.PlayerReplicationInfo));
    }
    else {
        g= class'Nade';
    }
    KFSXPlayerController(Instigator.Controller).weaponLRI.accum(GetItemName(string(g)), 1);

    return super.SpawnProjectile(Start,Dir);
}