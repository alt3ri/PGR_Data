--- 战斗奖励-技能卡片
---@class XUiPanelTheatre6RewardSkill : XUiNode
---@field private _Control XTheatre6Control
---@field Parent XUiTheatre6FightReward
local XUiPanelTheatre6RewardSkill = XClass(XUiNode, "XUiPanelTheatre6RewardSkill")

---技能类型文本
local SkillTypeText = {
    "Theatre6ActiveSkill", "Theatre6BattleSkill", "Theatre6CSSkill", "Theatre6InsertSkill"
}
local SkillTypeBgConfigName = {
    [XEnumConst.Theatre6.SlotType.Special] = "SkillType4Bg",
    [XEnumConst.Theatre6.SlotType.Insert] = "SkillType2a3Bg",
    [XEnumConst.Theatre6.SlotType.Active] = "SkillType1Bg",
}
function XUiPanelTheatre6RewardSkill:OnStart()
    self._TagGrids = {}
    self._StarGrids = {}
    self._ClickTagCb = nil
    self.TxtDesc.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
    self.ImgIconSp:SetSprite(self._Control:GetClientConfigValue("IconSp"))
end

---@param data table {SkillId, Level}
function XUiPanelTheatre6RewardSkill:Update(data)
    self._SkillId = data.SkillId
    self._SkillLevel = data.Level or 1
    self._Config = self._Control:GetSkillCfgById(self._SkillId)
    self.SlotTypes = self._Control:GetSkillInstallSlots(self._SkillId)

    self:RefreshIcon()
    self:RefreshName()
    self:RefreshQuality()
    self:RefreshType()
    self:RefreshCost()
    self:RefreshStar()
    self:RefreshDesc()
    self:RefreshTags()
end

function XUiPanelTheatre6RewardSkill:RefreshIcon()
    self.UiRImgIcon:SetRawImage(self._Config.Icon)
end

function XUiPanelTheatre6RewardSkill:RefreshName()
    self.UiTxtName.text = self._Config.Name
end

function XUiPanelTheatre6RewardSkill:RefreshQuality()
    local spriteName = ""
    if self.SlotTypes then
        local slotType = self.SlotTypes[1] --默认第一个槽位
        if slotType then
            spriteName = self._Control:GetClientConfigValue(SkillTypeBgConfigName[slotType],self._Config.Quality)
        end
    else
        spriteName = self._Control:GetQualityIcon(self._Config.Quality)
    end
    self.ImgQuality:SetSprite(spriteName)
end

function XUiPanelTheatre6RewardSkill:RefreshType()
    self.TxtType.text = XUiHelper.GetText(SkillTypeText[self._Config.Type])
end

function XUiPanelTheatre6RewardSkill:RefreshCost()
    self.UiTxtNum.text = tostring(self._Config.CostTL or 0)
end

function XUiPanelTheatre6RewardSkill:RefreshStar()
    self.GridStar.gameObject:SetActiveEx(false)
    self._StarGrids = XUiHelper.RefreshUiObjectList(self._StarGrids, self.GridStar.parent, self.GridStar, self._SkillLevel, function(i, grid)
        grid.GridStar.gameObject:SetActiveEx(true)
    end)
end

function XUiPanelTheatre6RewardSkill:RefreshDesc()
    self.TxtDesc.text = self._Control:GetSkillDesc(self._SkillId, false)
end

function XUiPanelTheatre6RewardSkill:RefreshTags()
    local showTags = self._Control:GetShowBuildTagWithSort(self._Config.BuildTags)
    local keyWordIds = self._Config.KeyWordIds

    self.GridTag.gameObject:SetActiveEx(false)
    self._TagGrids = XUiHelper.RefreshUiObjectList(self._TagGrids, self.GridTag.parent, self.GridTag, #showTags, function(i, grid)
        local tag = showTags[i]
        grid.ImgIcon:SetSprite(tag.Icon)
        grid.TxtName.text = tag.Name

        grid.GridTag:AddEventListener(function()
            if XLuaUiManager.IsUiShow("UiTheatre6BubbleTagDetail") then
                XLuaUiManager.Close("UiTheatre6BubbleTagDetail")
                return
            end
            self._Control:OpenTagTip(self._Config.BuildTags, self.Transform, keyWordIds)
        end)
    end)

    -- 超算倍率
    local csMag = self._Config.CSMag or 0
    self.TxtScName.text = CS.XTextManager.GetText("Theatre6SkillCSMag")
    self.UiTxtScNum.text = string.format("%s%%", math.floor(csMag / 100))

    self.GridTagSc:SetNameByGroup(0, XUiHelper.GetText("Theatre6OverClockEfficiency"))
    self.GridTagSc:SetNameByGroup(1, string.format("%s%%", math.floor(self._Config.CSMag / 100)))
    self.GridTagSc:AddEventListener(function()
            if XLuaUiManager.IsUiShow("UiTheatre6BubbleTagDetail") then
                XLuaUiManager.Close("UiTheatre6BubbleTagDetail")
                return
            end
           
            self._Control:OpenTagTip(self._Config.BuildTags, self.Transform, keyWordIds)
    end)
end

return XUiPanelTheatre6RewardSkill
