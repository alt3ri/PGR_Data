XDataCenter.MonsterCombatManager = {}
setmetatable(XDataCenter.MonsterCombatManager,
        {
            __index = function(table, key, value)
                XLog.Error("[MonsterCombatManager] 战双BVB, 该副本已被屏蔽，如有问题，请联系立斌，谢谢")
            end
        })

XDataCenter.NieRManager = {}
setmetatable(XDataCenter.NieRManager,
        {
            __index = function(table, key, value)
                XLog.Error("[NieRManager] 尼尔, 该副本已被屏蔽，如有问题，请联系立斌，谢谢")
            end
        })
