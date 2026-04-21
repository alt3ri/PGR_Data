---@class XPBRGameModel : XModel
local XPBRGameModel = XClass(XModel, "XPBRGameModel", true)

--region 分部类初始化
XClassPartialRequire("XModule/XPBRGame/XPBRGameModelConfig", "XPBRGameModel")
XClassPartialRequire("XModule/XPBRGame/XPBRGameModelData", "XPBRGameModel")
--endregion

function XPBRGameModel:OnInit()
    self:InitConfigs()
    
    -- 初始化子Model
    ---@type XPBRCollectionModel
    self.CollectionModel = self:AddSubModel(require('XModule/XPBRGame/SubModules/Collections/XPBRCollectionModel'))
    ---@type XPBRGeniusModel
    self.GeniusModel = self:AddSubModel(require('XModule/XPBRGame/SubModules/Genius/XPBRGeniusModel'))
end

function XPBRGameModel:ClearPrivate()
    self:ClearPrivateConfig()
end

function XPBRGameModel:ResetAll()
    self:ResetConfigs()

    self.ActivityDb = nil
    self._CurSelectCharId = nil
end

---@return XTablePBRActivity
function XPBRGameModel:GetCurActivityCfg()
    local activityId = self:GetActivityId()

    if XTool.IsNumberValidEx(activityId) then
        return self:GetTablePBRActivityCfgById(activityId)
    end
end

function XPBRGameModel:SetCurSelectCharId(customCharId)
    self._CurSelectCharId = customCharId
end

function XPBRGameModel:GetCurSelectCharId()
    return self._CurSelectCharId
end

function XPBRGameModel:SetFightExitType(type)
    self._FightExitType = type
end

function XPBRGameModel:GetFightExitType()
    return self._FightExitType
end

--- 获取当前货币数量
function XPBRGameModel:GetGeniusCoinCount()
    local itemId = self:GetConfigPBRNumber('PbrCoin')

    if XTool.IsNumberValidEx(itemId) then
        return XDataCenter.ItemManager.GetCount(itemId) or 0
    end

    return 0
end

--region 本地缓存

local NewStageMarkPrex = "NewStageMark_"

function XPBRGameModel:ReddotGetIsMarkStage(stageId)
    return self._SaveUtil:GetData(NewStageMarkPrex .. stageId) or false
end

function XPBRGameModel:ReddoSetStageMark(stageId)
    self._SaveUtil:SaveData(NewStageMarkPrex .. stageId, true)
end

function XPBRGameModel:GetIsShopSelectGiveupIgnorePopup()
    return self._SaveUtil:GetData("IgnoreShopGiveupPopup") or false
end

function XPBRGameModel:SetShopSelectGiveupIgnorePopup(isIgnore)
    self._SaveUtil:SaveData("IgnoreShopGiveupPopup", isIgnore)
end

function XPBRGameModel:GetLastPassStageCharId()
    return self._SaveUtil:GetData("LastPassStageCharId")
end

function XPBRGameModel:SetLastPassStageCharId(charId)
    return self._SaveUtil:SaveData("LastPassStageCharId", charId)
end

--endregion

return XPBRGameModel


--region 服务端类定义

---@class XPbrDataDb
---@field ActivityId number
---@field SegmentSettleData PbrSegmentSettleData
---@field MetaProgression PbrMetaProgression
---@field StageRecords table<number, PbrStageRecord>
---@field Compendiums PbrCompendiums


---@class PbrSegmentSettleData @局内暂存数据
---@field State number @枚举PbrAdventureState
---@field StageId number
---@field ShopData PbrAdventureShopData
---@field Wave number
---@field CharacterId number
---@field CharacterLevel number
---@field CharacterExp number
---@field BaseAttrs table<number, number>
---@field CurAttrs table<number, number>
---@field MaxAttrs table<number, number>
---@field Items table<number, PbrItem>
---@field WaveMonsters table<number, PbrMonster> @战中怪物记录
---@field WaveObrs table<number, PbrItem> @战中信号球记录

---@class PbrAdventureShopData
---@field ShopId number
---@field MaxChooseCount number
---@field MaxFreshCount number
---@field UseChooseCount number 
---@field UseFreshCount number
---@field SellItems number[] @索引位置对应货物道具Id

---@class PbrMetaProgression @局外养成数据
---@field UnlockNodes table<number> @已解锁节点集合

---@class PbrStageRecord @关卡额外数据
---@field StageId number
---@field HistoryMaxWave number @历史最大波次
---@field IsPass boolean @是否通关
---@field IsPassWave boolean @记录历史最大波次时是否通关此波次

---@class PbrCompendiums @图鉴收集数据
---@field CompendiumItems table<number, PbrItem> 
---@field CompendiumMonsters table<number, PbrMonster> 

---@class PbrItem @道具结构
---@field ItemId number
---@field UnlockTime number @获得时间戳,用于前端显示排序
---@field GainNum number @个数|累计获得次数
---@field TriggerNum number @信号球累计触发次数

---@class PbrMonster @怪物
---@field MonsterId number
---@field DamageTotal number @累计造成总伤害
---@field BeKillNum number @被击杀次数

---@class PbrShopSellItem
---@field ItemId number
---@field IsSell boolean

--endregion