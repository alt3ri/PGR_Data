---@class XTheatre5Model : XModel
local XTheatre5Model = XClass(XModel, "XTheatre5Model", true)

--region 初始化部分类
require('XModule/XTheatre5/ModelPartial/XTheatre5ModelConfig')
require('XModule/XTheatre5/ModelPartial/XTheatre5ModelSave')
--endregion

local XTheatre5PVPAdventureData = require('XModule/XTheatre5/Entity/XTheatre5PVPAdventureData')
local XTheatre5PVPCharacterData = require('XModule/XTheatre5/Entity/XTheatre5PVPCharacterData')
local XTheatre5PVERougeData = require('XModule/XTheatre5/Entity/XTheatre5PVERougeData')
local XTheatre5PVEAdventureData = require('XModule/XTheatre5/Entity/XTheatre5PVEAdventureData')

function XTheatre5Model:OnInit()
    self:InitConfigs()
    self:InitLocalSave()
    ---@type XTheatre5PVPAdventureData
    self.PVPAdventureData = XTheatre5PVPAdventureData.New(self)
    ---@type XTheatre5PVPCharacterData
    self.PVPCharacterData = XTheatre5PVPCharacterData.New()

    ---@type XTheatre5AdventureDataBase
    self.CurAdventureData = nil
     ---@type XTheatre5PVERougeData
    self.PVERougeData = XTheatre5PVERougeData.New(self)
    ---@type XTheatre5PVEAdventureData
    self.PVEAdventureData = XTheatre5PVEAdventureData.New(self)
    
    self._RelicCollects = {}
end

function XTheatre5Model:ClearPrivate()
    self:ReleasePriConfigCache()
end

function XTheatre5Model:ResetAll()
    self:SetActivityId(nil)
    self:ReleaseNopriConfigCache()

    self.PVPAdventureData:ClearData()
    self.PVPCharacterData:ClearData()
    self.PVERougeData:ClearData()
    self.PVEAdventureData:ClearData()

    self:SetCurPlayingMode(nil)
    self:SetHasActivityData(nil)
    self:SetCharacterWinGameCountData(nil)
end

function XTheatre5Model:SetActivityId(activityId)
    self._ActivityId = activityId
end

function XTheatre5Model:GetActivityId()
    return self._ActivityId or 0
end

function XTheatre5Model:SetHasActivityData(hasData)
    self._HasActivityData = hasData
end

function XTheatre5Model:GetHasActivityData()
    return self._HasActivityData
end

--- 设置当前正在游玩的模式, 用于玩法内各界面差异化逻辑判断
function XTheatre5Model:SetCurPlayingMode(mode)
    self._CurPlayingMode = mode

    if self._CurPlayingMode == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        self.CurAdventureData = self.PVPAdventureData
    else
        self.CurAdventureData = self.PVEAdventureData
    end
    
    XMVCA.XTheatre5:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_GAME_MODE_CHANGED)
end

function XTheatre5Model:GetCurPlayingMode()
    return self._CurPlayingMode
end

function XTheatre5Model:ChangePlayingMode()
    local curPlayingMode = self._CurPlayingMode
    if curPlayingMode == XMVCA.XTheatre5.EnumConst.GameMode.PVE then
        curPlayingMode = XMVCA.XTheatre5.EnumConst.GameMode.PVP
    else
        curPlayingMode = XMVCA.XTheatre5.EnumConst.GameMode.PVE
    end
    self:SetCurPlayingMode(curPlayingMode)        
end

--- 设置每个角色的胜场次数，不分模式
function XTheatre5Model:SetCharacterWinGameCountData(data)
    self._CommonFightCnt = data
end

function XTheatre5Model:GetCharacterWinGameCountById(charaId)
    if not XTool.IsNumberValid(charaId) then
        return 0
    end
    
    if not XTool.IsTableEmpty(self._CommonFightCnt) then
        return self._CommonFightCnt[charaId] or 0
    end
    
    return 0
end

function XTheatre5Model:GetCharacterWinGameCountData()
    return self._CommonFightCnt
end

function XTheatre5Model:GetTheatre5WorldIdByActivityId(activityId)
    if self:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        return self:GetTheatre5PVPWorldIdByActivityId(activityId)
    end
    return self:GetTheatre5PVEWorldIdByActivityId()    
end

function XTheatre5Model:UpdateRelicCollects(relicCollects)
    if not relicCollects then
        XLog.Error("[XTheatre5Model] 更新饰品图鉴，但是服务端数据为空")
    end
    self._RelicCollects = relicCollects or {}
end

function XTheatre5Model:UpdateOneRelicCollect(relicId)
    self._RelicCollects = self._RelicCollects or {}
    self._RelicCollects[#self._RelicCollects + 1] = relicId
end

function XTheatre5Model:HasEnoughExpToAutoUpgrade()
    local levelConfig = self:GetCharacterLevelConfig(self.CurAdventureData)
    if not levelConfig then
        XLog.Error("[XTheatre5Model] 角色检测升级，但是对应等级的配置数据为空")
        return false
    end
    local nextLevel = self:GetCharacterLevelConfig(self.CurAdventureData, levelConfig.Level + 1)
    if not nextLevel then
        --XLog.Error("[XTheatre5Model] 已经满级")
        return false
    end
    local exp = self.CurAdventureData:GetCharacterExp()
    if exp >= levelConfig.Exp then
        return true
    end
    return false
end

--- 判断任务是否有多个奖励
function XTheatre5Model:CheckMissionHasMultyRewards(bountyId, level)
    level = level or 1

    local id = self:GetMissionBountyComboId(bountyId, level)
    local bountyCfg = self:GetTheatre5MissionBountyCfgById(id)

    if bountyCfg then
        return XTool.GetTableCount(bountyCfg.BountyItem) > 1
    end

    return false
end

return XTheatre5Model