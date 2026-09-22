local XRedPointTransfiniteTowerUnlock = {}

---任一座塔解锁后未进入过
function XRedPointTransfiniteTowerUnlock.Check()
    local towerCfgIds = XMVCA.XTransfiniteTower:GetMainTowerCfgIds()
    for _, towerCfgId in ipairs(towerCfgIds or table.empty) do
        if XMVCA.XTransfiniteTower:IsTowerUnlockRedDotShow(towerCfgId) then
            return true
        end
    end
    return false
end

return XRedPointTransfiniteTowerUnlock
