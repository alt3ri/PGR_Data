-----伙伴配置-----------------------------------------
local PartnerConfigs = {
    [0] ={ --结构参考表
        IsAiDefaultUnEnabled = false, --默认关闭AI
        NormalAttackList ={},--普攻列表
        VigilantRange =50,--警戒范围，会被多少范围内的敌人触发战斗
    },
    [1601] ={ --
        
    },
    [1602] ={ --70斧形Relink教学队友AI啊
        IsAiDefaultUnEnabled = true, --默认关闭AI
        NormalAttackList = {105215,105216,105217,105218}, --普攻列表
        VigilantRange =100,--警戒范围，会被多少范围内的敌人触发战斗
    },
    [1603] ={ --丽芙Relink教学队友AI
        IsAiDefaultUnEnabled = true, --默认关闭AI
        NormalAttackList = {105301,105302,105303,105304,105305,105306}, --普攻列表
        VigilantRange =100,--警戒范围，会被多少范围内的敌人触发战斗
    },
}
return PartnerConfigs