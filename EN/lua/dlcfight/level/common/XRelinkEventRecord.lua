local XRelinkEventRecord = XClass(nil, "XRelinkEventRecord")
--统计工具
---@param proxy XDlcCSharpFuncs
function XRelinkEventRecord:Ctor(proxy)
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
end
function XRelinkEventRecord:Init(Proxy, LevelName)
    self._levelName = LevelName
    -- self._data ={
    --     MakeDamageData = {
    --         Npc1 = value,
    --         Npc2 = value,
    --         ...
    --     },
    --     TakeOnDamageData = {
    --         Npc1 = value,
    --         Npc2 = value,
    --         ...
    --     },
    --     CureData = {
    --         Npc1 = value,
    --         Npc2 = value,
    --         ...
    --     },
    --     CounterData = {
    --         Npc1 = value,
    --         Npc2 = value,
    --         ...
    --     },
    --     BreakTimes = 0,
    --     FullChainTimes = 0,
    -- }

    self._resultDataKey = {                 --传值键值 
        CureDataTimes = 133005,             --治疗次数
        LinkTimes = 133006,                 --break次数   Linktime OD结束后的那个break
        FullChain = 133007,                  --FC      
        MultiGuardTimes = 133008,           --多人弹刀
        MakeDamageData = 133009,            --伤害  
        TakeOnDamageData = 133010,          --抗伤
        CureData = 133011,                  --治疗量
        BreakCount = 133012,                --破韧次数
        Deaths = 133013,                    --死亡次数
        DeathTime = 133014,                 --死亡时长               --无
        RescueTime = 133015,                --救人时长               --无
        Qtes = 133016,                      --QTE                    --无
        CounterData = 133017,               --拼刀成功
        ClashFailCount = 133018,            --拼刀失败次数          --无 
        FullChain_2 = 133019,               --触发2人fullchain
        FullChain_3 = 133020,               --触发3人fullchain
        WrestleTimes = 133021,              --角力次数
        TeamWorkSkillTimes = 133022,        --极限技释放次数
        DragonDpsCheckTimes= 133023,        --白龙DPS检测通过次数
        OverDriveTimes = 133024,            --进入OD次数
        DragonDpsCheckFailTimes = 133025,   --白龙DPS检测失败次数
        MonsterLostLife = 133026,            --怪物死亡剩余血量百分比
        IsPlayerWin = 133027                     --玩家是否胜利
    }

    self._data = {
        --个人项目
        MakeDamageData = {},                --造成伤害
        TakeOnDamageData = {},              --承受伤害
        CureData = {},                      --治疗
        CureDataTimes = {},                 --治疗次数
        CounterData = {},                   --单人弹刀次数
        Deaths = {},                        --死亡次数
        WrestleTimes = {},                  --角力次数
        Qtes = {},                          --破韧追击次数          --无
        FullChain = {},                     --参与FC次数
        TeamWorkSkillTimes = {},              --极限技释放次数
        --团队项目
        BreakCount = 0,                     --Break次数
        LinkTimes = 0,                      --破韧次数
        FullChain_2 = 0,                    --触发2人fullchain
        FullChain_3 = 0,                   --触发3人fullchain
        DragonDpsCheckTimes = 0,             --白龙DPS检测通过次数
        DragonDpsCheckFailTimes = 0,          --白龙DPS检测失败次数
        OverDriveTimes = 0,                 --进入OD次数
        MultiGuardTimes = 0,               --多人参与弹刀
        IsPlayerWin = 0                    --玩家是否胜利，胜利1，失败0
    }

    self._QteSkill = {
        [105209]= true,
        [105231]= true,
        [105273]= true,
        [105731]= true,
        [105773]= true,
        [1051092]= true,
        [1051093]= true,
        [105361]= true,
        [105861]= true,
    }

    self._TeamWorkSkill = {
        [105268]= true,
        [105274]= true,
        [105768]= true,
        [105787]= true,
        [1051096]= true,
        [105360]= true,
        [105860]= true,
    }

    self._playerIdDictionary = {}

    Proxy:RegisterEvent(EWorldEvent.NpcDamage)                                     --事件注册：NPC伤害
    Proxy:RegisterEvent(EWorldEvent.NpcCure)                                       --事件注册：NPC治疗
    Proxy:RegisterEvent(EWorldEvent.NpcDie)                                        --事件注册：NPC死亡
    Proxy:RegisterEvent(EWorldEvent.CastFullChainFinalSkill)                       --事件注册：Fullchain
    Proxy:RegisterEvent(EWorldEvent.NpcWrestleStart)                            --事件注册：角力成功
    Proxy:RegisterEvent(EWorldEvent.NpcMultiParrySucceed)                          --事件注册：多人弹刀成功
    Proxy:RegisterEvent(EWorldEvent.NpcWaitReboot)                                 --事件注册：进入复活
    Proxy:RegisterEvent(EWorldEvent.NpcODBreakAfter)                              --事件注册：怪物break
    Proxy:RegisterEvent(EWorldEvent.NpcBrokenAfter)                               --事件注册：怪物破韧
    Proxy:RegisterEvent(EWorldEvent.NpcAddBuff)                                    --事件注册：上buff 用于白龙DPS检测通过/单人弹刀事件广播
    Proxy:RegisterEvent(EWorldEvent.NpcTeamWorkSkillCast)                          --事件注册：极限技释放次数-
    Proxy:RegisterEvent(EWorldEvent.NpcEnterOverDrive)                             --事件注册：进入OD
    Proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)                            --事件注册：释放技能

end

function XRelinkEventRecord:AddPlayerNpc(playerId, uuid)        --初始化所有个人数据，在logic的初始化玩家处初始化
    self._data.MakeDamageData[uuid] = 0
    self._data.TakeOnDamageData[uuid] = 0
    self._data.CureData[uuid] = 0
    self._data.CureDataTimes[uuid] = 0
    self._data.CounterData[uuid] = 0
    self._data.Deaths[uuid] = 0
    self._data.MultiGuardTimes = 0
    self._data.WrestleTimes[uuid] = 0
    self._data.Qtes[uuid] = 0
    self._data.FullChain[uuid] = 0
    self._playerIdDictionary[uuid] = playerId
    self._data.TeamWorkSkillTimes[uuid] = 0
end

function XRelinkEventRecord:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.NpcDamage then     --伤害事件
        if self._data.MakeDamageData[eventArgs.LauncherId] ~= nil then     --防止伤害来源是白龙
            self._data.MakeDamageData[eventArgs.LauncherId] = self._data.MakeDamageData[eventArgs.LauncherId] + eventArgs.PhysicalDamage + eventArgs.ElementDamage + eventArgs.RealDamage
        end
        if self._data.TakeOnDamageData[eventArgs.TargetId] ~= nil then      --防止挨打的是白龙
            self._data.TakeOnDamageData[eventArgs.TargetId] = self._data.TakeOnDamageData[eventArgs.TargetId] + eventArgs.PhysicalDamage + eventArgs.ElementDamage + eventArgs.RealDamage
        end
    elseif  eventType == EWorldEvent.NpcCure then    --治疗事件
        if self._data.CureData[eventArgs.LauncherId] ~= nil then
            self._data.CureDataTimes[eventArgs.LauncherId] = self._data.CureDataTimes[eventArgs.LauncherId] + 1
            self._data.CureData[eventArgs.LauncherId] = self._data.CureData[eventArgs.LauncherId] + eventArgs.Value
            XLog.Debug(self._data.CureData[eventArgs.LauncherId])
        end
    elseif  eventType == EWorldEvent.NpcWaitReboot then    --死亡事件
        if self._data.Deaths[eventArgs.NpcId] ~= nil then
            self._data.Deaths[eventArgs.NpcId] = self._data.Deaths[eventArgs.NpcId] + 1
        end

    elseif  eventType == EWorldEvent.CastFullChainFinalSkill then  --FullChain完成

        if eventArgs.ChainLevel == 3 then
            self._data.FullChain_3 = self._data.FullChain_3 + 1
        end
        if eventArgs.ChainLevel == 2 then
            self._data.FullChain_2 = self._data.FullChain_2 + 1
        end
        for uuid, _ in pairs(eventArgs.ChainNpcList) do
            if self._data.FullChain[eventArgs.ChainNpcList[uuid]] ~= nil then
                self._data.FullChain[eventArgs.ChainNpcList[uuid]] = self._data.FullChain[eventArgs.ChainNpcList[uuid]] + 1
                XLog.Debug("UUID是"..eventArgs.ChainNpcList[uuid].."的玩家，chain次数+1")
            end
        end
    elseif  eventType == EWorldEvent.NpcWrestleStart then  --角力成功
        if self._data.WrestleTimes[eventArgs.TargetUUID] ~= nil then
            self._data.WrestleTimes[eventArgs.TargetUUID] = self._data.WrestleTimes[eventArgs.TargetUUID] + 1
        end
    elseif  eventType == EWorldEvent.NpcODBreakAfter then   --怪物break次数
        self._data.LinkTimes = self._data.LinkTimes + 1
    elseif  eventType == EWorldEvent.NpcBrokenAfter then   --怪物破韧次数
        self._data.BreakCount = self._data.BreakCount + 1
    elseif  eventType == EWorldEvent.NpcMultiParrySucceed then -- 多人弹刀成功
            self._data.MultiGuardTimes = self._data.MultiGuardTimes + 1
    elseif eventType == EWorldEvent.NpcAddBuff then  -- 白龙DPS检测
        if eventArgs.BuffTableId == 8005915 then
            --白龙专用:DPS检测成功1次
            self._data.DragonDpsCheckTimes = self._data.DragonDpsCheckTimes + 1
        elseif eventArgs.BuffTableId == 8005916 then
            --白龙专用:DPS检测失败1次
            self._data.DragonDpsCheckFailTimes = self._data.DragonDpsCheckFailTimes + 1
        end

        if eventArgs.BuffTableId == 1000509 then
            --玩家弹刀成功
            if self._data.CounterData[eventArgs.CasterUUID]  ~= nil then
                self._data.CounterData[eventArgs.CasterUUID] = self._data.CounterData[eventArgs.CasterUUID] + 1
            end
        end

    elseif eventType == EWorldEvent.NpcEnterOverDrive then  -- OD次数
        self._data.OverDriveTimes = self._data.OverDriveTimes + 1

    elseif eventType == EWorldEvent.NpcCastActionAfter then
        if  self._QteSkill[eventArgs.SkillActionId] then   -- 释放QTE
            if self._data.Qtes[eventArgs.LauncherId]  ~= nil then
                self._data.Qtes[eventArgs.LauncherId] = self._data.Qtes[eventArgs.LauncherId] + 1
            end
        end

        if  self._TeamWorkSkill[eventArgs.SkillActionId] then --极限技释放成功
            if self._data.TeamWorkSkillTimes[eventArgs.LauncherId] ~= nil then
                self._data.TeamWorkSkillTimes[eventArgs.LauncherId] = self._data.TeamWorkSkillTimes[eventArgs.LauncherId] + 1
            end
        end

    end
end

function XRelinkEventRecord:HandleLuaEvent(eventType, eventArgs) --lua自定义事件响应逻辑

end


function XRelinkEventRecord:SetResultData(Proxy)
    for uuid, _ in pairs(self._data.MakeDamageData) do
        local playerId = self._playerIdDictionary[uuid]
        local damage =    self._data.MakeDamageData[uuid]
        local takeOnDamage =    self._data.TakeOnDamageData[uuid]
        local cure =    self._data.CureData[uuid]
        local curetimes =  self._data.CureDataTimes[uuid] 
        local counter = self._data.CounterData[uuid] 
        local deaths = self._data.Deaths[uuid]
        local wrestle = self._data.WrestleTimes[uuid]  
        local qte = self._data.Qtes[uuid] 
        local fullchain = self._data.FullChain[uuid]
        local teamWorkSkillTimes = self._data.TeamWorkSkillTimes[uuid]

        --个人项目
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.MakeDamageData, damage)  --133009 伤害
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.TakeOnDamageData, takeOnDamage)  --133010 抗伤
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.CureData, cure)  --治疗 133011
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.CureDataTimes, curetimes)  --治疗次数 133005
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.CounterData, counter)  --133017 单人弹刀
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.Deaths, deaths)  --133013 死亡次数
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.WrestleTimes, wrestle)    --133021 角力
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.Qtes, qte)                             --QTE追击
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.FullChain, fullchain) --133007 Fc参与
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.TeamWorkSkillTimes, teamWorkSkillTimes) --133022 极限技释放次数
        --团队项目
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.BreakCount, self._data.BreakCount) --133012 破韧
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.LinkTimes, self._data.LinkTimes) --133006 Break
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.FullChain_2, self._data.FullChain_2) --无了
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.FullChain_3, self._data.FullChain_3) --133020 3人Fc
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.DragonDpsCheckTimes, self._data.DragonDpsCheckTimes) --133023 白龙DPS检测通过
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.OverDriveTimes, self._data.OverDriveTimes) --133024 OD次数
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.MultiGuardTimes, self._data.MultiGuardTimes)  --133008 多人弹刀
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.DragonDpsCheckFailTimes, self._data.DragonDpsCheckFailTimes) --133025 白龙DPS检测失败
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.FullChain_2, self._data.FullChain_2) --133019 双人FC参与
        
        if Proxy:CheckLevelMemoryInt(133026) == true then
            Proxy:SetFightResultCustomData(playerId, self._resultDataKey.MonsterLostLife, Proxy:GetLevelMemoryInt(133026)) --战斗失败，怪物已损失血量百分比
            XLog.Debug("玩家"..playerId.."   怪物损失血量:"..Proxy:GetLevelMemoryInt(133026))
        end

        if Proxy:CheckLevelMemoryInt(133027) == true then
            Proxy:SetFightResultCustomData(playerId, self._resultDataKey.IsPlayerWin, Proxy:GetLevelMemoryInt(133027)) --战斗结果传值
            XLog.Debug("玩家"..playerId.."   胜利情况:"..Proxy:GetLevelMemoryInt(133027))
        end

        XLog.Debug("玩家"..playerId.."   造成伤害:"..damage)
        XLog.Debug("玩家"..playerId.."   抗伤:"..takeOnDamage)
        XLog.Debug("玩家"..playerId.."   治疗:"..cure)
        XLog.Debug("玩家"..playerId.."   治疗次数:"..curetimes)
        XLog.Debug("玩家"..playerId.."   单人弹刀次数:"..counter)
        XLog.Debug("玩家"..playerId.."   死亡次数:"..deaths)
        XLog.Debug("玩家"..playerId.."   角力次数:"..wrestle)
        XLog.Debug("玩家"..playerId.."   参与chain次数"..fullchain)
        XLog.Debug("玩家"..playerId.."   3人FullChain次数:"..self._data.FullChain_3)
        XLog.Debug("玩家"..playerId.."   2人FullChain次数:"..self._data.FullChain_2)
        XLog.Debug("玩家"..playerId.."   极限技次数:"..teamWorkSkillTimes)
        XLog.Debug("玩家"..playerId.."   QTE次数:"..qte)
        XLog.Debug("玩家"..playerId.."   OD次数:"..self._data.OverDriveTimes)
        XLog.Debug("玩家"..playerId.."   破韧次数:"..self._data.BreakCount)
        XLog.Debug("玩家"..playerId.."   Break次数:"..self._data.LinkTimes)
        XLog.Debug("玩家"..playerId.."   多人弹刀:"..self._data.MultiGuardTimes)
        
        
    end 
end

function XRelinkEventRecord:Destory()
    self._levelName = nil
    self._data = nil
    self = nil
end


return XRelinkEventRecord