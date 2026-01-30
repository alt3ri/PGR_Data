local XRelinkEventRecord = XClass(nil, "XRelinkEventRecord")
--统计工具
---@param proxy XDlcCSharpFuncs
function XRelinkEventRecord:Ctor(proxy)
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
end
function XRelinkEventRecord:Init(Porxy, LevelName)
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
        LinkTimes = 133006,                 --破韧次数  原LinkTimes            
        FullChain = 13307,                  --FC      
        MultiGuardTimes = 133008,           --多人弹刀
        MakeDamageData = 133009,            --伤害  
        TakeOnDamageData = 133010,          --抗伤
        CureData = 133011,                  --治疗量
        BreakCount = 133012,                --break次数
        Deaths = 133013,                    --死亡次数
        DeathTime = 133014,                 --死亡时长               --无
        RescueTime = 133015,                --救人时长               --无
        Qtes = 133016,                      --QTE
        CounterData = 133017,               --拼刀成功
        ClashFailCount = 133018,            --拼刀失败次数          --无 
        FullChain_2 = 133019,               --触发2人fullchain     
        FullChain_3 = 133020,               --触发3人fullchain
        WrestleTimes = 133021,              --角力次数
    }
    self._data = {
        --个人项目
        MakeDamageData = {},                --造成伤害
        TakeOnDamageData = {},              --承受伤害
        CureData = {},                      --治疗
        CureDataTimes = {},                 --治疗次数
        CounterData = {},                   --拼刀次数
        Deaths = {},                        --死亡次数
        MultiGuardTimes = {},               --多人参与拼刀
        WrestleTimes = {},                  --角力次数
        Qtes = {},                          --破韧追击次数
        FullChain = {},                     --参与FC次数
        --团队项目
        BreakTimes = 0,                     --Break次数
        LinkTimes = 0,                      --破韧次数
        FullChain_2 = 0,                    --触发2人fullchain     
        FullChain_3 = 0                     --触发3人fullchain
    }
    self._playerIdDictionary = {}

    Porxy:RegisterEvent(EWorldEvent.NpcDamage)                                     --事件注册：NPC伤害
    Porxy:RegisterEvent(EWorldEvent.NpcCure)                                       --事件注册：NPC治疗
    Porxy:RegisterEvent(EWorldEvent.NpcDie)                                        --事件注册：NPC死亡
    Porxy:RegisterLuaEvent(EFightLuaEvent.RelinkCounterSuccess)   --弹刀
end

function XRelinkEventRecord:AddPlayerNpc(playerId, uuid)        --初始化所有个人数据，在logic的初始化玩家处初始化
    self._data.MakeDamageData[uuid] = 0
    self._data.TakeOnDamageData[uuid] = 0
    self._data.CureData[uuid] = 0
    self._data.CureDataTimes[uuid] = 0
    self._data.CounterData[uuid] = 0
    self._data.Deaths[uuid] = 0
    self._data.MultiGuardTimes[uuid] = 0
    self._data.WrestleTimes[uuid] = 0
    self._data.Qtes[uuid] = 0
    self._data.FullChain[uuid] = 0
    self._playerIdDictionary[uuid] = playerId
end


function XRelinkEventRecord:HandleEvent(eventType, eventArgs)                     
    if eventType == EWorldEvent.NpcDamage then     --伤害事件
        if self._data.MakeDamageData[eventArgs.LauncherId] ~= nil then     --防止伤害来源是白龙
            self._data.MakeDamageData[eventArgs.LauncherId] = self._data.MakeDamageData[eventArgs.LauncherId] + eventArgs.PhysicalDamage + eventArgs.ElementDamage + eventArgs.RealDamage
        end
        if self._data.TakeOnDamageData[eventArgs.TargetId] ~= nil then      --防止挨打的是白龙
            self._data.TakeOnDamageData[eventArgs.TargetId] = self._data.TakeOnDamageData[eventArgs.TargetId] + eventArgs.PhysicalDamage + eventArgs.ElementDamage + eventArgs.RealDamage
        end

    elseif  eventType == EWorldEvent.NpcCure then
        if self._data.CureData[eventArgs.LauncherId] ~= nil then
            self._data.CureDataTimes[eventArgs.LauncherId] = self._data.CureDataTimes[eventArgs.LauncherId] + 1
            self._data.CureData[eventArgs.LauncherId] = self._data.CureData[eventArgs.LauncherId] + eventArgs.PhysicalDamage + eventArgs.ElementDamage + eventArgs.RealDamage
        end
    end
end

function XRelinkEventRecord:HandleLuaEvent(eventType, eventArgs)                     --事件注册：弹刀成功
    if eventType == EWorldEvent.RelinkCounterSuccess then
            
    elseif  eventType == EWorldEvent.poren then

    elseif  eventType == EWorldEvent.fullchain then
        
    end
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
        local mutltiGuardTimes = self._data.MultiGuardTimes[uuid] 
        local wrestle = self._data.WrestleTimes[uuid]  
        local qte = self._data.Qtes[uuid] 
        local fullchain = self._data.FullChain[uuid] 

        --个人项目
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.MakeDamageData, damage)  
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.TakeOnDamageData, takeOnDamage)  
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.CureData, cure)  
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.CureDataTimes, curetimes)  
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.CounterData, counter)  
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.Deaths, deaths)  
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.mutltiGuardTimes, mutltiGuardTimes)  
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.WrestleTimes, wrestle)  
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.Qtes, qte)  
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.FullChain, fullchain) 
        --团队项目
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.BreakTimes, self._data.BreakTimes) 
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.LinkTimes, self._data.LinkTimes) 
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.FullChain_2, self._data.FullChain_2) 
        Proxy:SetFightResultCustomData(playerId, self._resultDataKey.FullChain_3, self._data.FullChain_3) 

    end 
    
    




end

function XRelinkEventRecord:Destory()
    self._levelName = nil
    self._data = nil
    self = nil
end


return XRelinkEventRecord