--[[
XMouthAnimeConfigs = XMouthAnimeConfigs or {}

local MouthDataCfg = {}
local MouthDataDic = {}

XMouthAnimeConfigs.FrameUnit = 100

function XMouthAnimeConfigs.Init()
end

function XMouthAnimeConfigs.GetMouthDataCfg()
    if not MouthDataCfg then
        XMouthAnimeConfigs.InitMouthData()
    end
    return MouthDataCfg
end

function XMouthAnimeConfigs.InitMouthData()
    local TABLE_MOUTHDATA = "Client/MouthData/MouthData.tab"
    MouthDataCfg = XTableManager.ReadByIntKey(TABLE_MOUTHDATA, XTable.XTableMouthData, "Id")
    
    local count = {}
    for _,cfg in pairs(MouthDataCfg) do
        if not MouthDataDic[cfg.CvId] then
            MouthDataDic[cfg.CvId] = {}
            count[cfg.CvId] = 1
        end

        local millisecond = XMouthAnimeConfigs.FrameUnit * count[cfg.CvId]
        if cfg.Msec > millisecond then
            count[cfg.CvId] = count[cfg.CvId] + 1
        end
        
        MouthDataDic[cfg.CvId][millisecond] = MouthDataDic[cfg.CvId][millisecond] or {}
        table.insert(MouthDataDic[cfg.CvId][millisecond],cfg)
    end
end

function XMouthAnimeConfigs.GetMouthDataDic()
    if not MouthDataDic then
        XMouthAnimeConfigs.InitMouthData()
    end
    return MouthDataDic
end
]]