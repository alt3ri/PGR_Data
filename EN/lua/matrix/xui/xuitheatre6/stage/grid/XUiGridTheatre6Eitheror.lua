---@class XUiGridTheatre6Eitheror: XUiNode 二择奖励
---@field Parent   XUiTheatre6RoomEitheror
---@field _Control XTheatre6Control
local XUiGridTheatre6Eitheror = XClass(XUiNode, "XUiGridTheatre6Eitheror")
local XUiGridTheatre6Skill = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Skill")
local XUiGridTheatre6Relic = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Relic")

function XUiGridTheatre6Eitheror:OnStart()
    ---@type XUiGridTheatre6Relic
    self._GridRelic = XUiGridTheatre6Relic.New(self.UiTheatre6GridRelic, self)
    ---@type XUiGridTheatre6Skill
    self._GridSkill = XUiGridTheatre6Skill.New(self.UiTheatre6GridSkill, self)
    self._Attrs = {}
end

function XUiGridTheatre6Eitheror:Refresh(rewardData)
    self.TxtDesc.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
    self.TxtDesc.text = self._Control:GetEventRewardDesc(rewardData)
    self.BtnClick.gameObject:SetActiveEx(false)

    local sourceTagIds = self._Control:GetTagHighlightSourceTagIds()
    local highlightSourceTagIds = self._Control:GetEffectiveTagHighlightSourceTagIds(sourceTagIds)
    
    -- 遗物显示加成属性
    if XTool.IsNumberValid(rewardData.AttrPack) then
        self.PanelAttr.gameObject:SetActiveEx(true)
        local attrPackConfig = self._Control:GetAttrPackCfgById(rewardData.AttrPack)
        local attrConfigs, attrValues = self._Control:GetShowAttribute(
            attrPackConfig.AttrTypes, attrPackConfig.AttrNums
        )
        self._GridRelic:Open()
        self._GridRelic:Update(rewardData.AttrPack)
        self._GridRelic:ShowTagHightLight(self._Control:CalcSkillHighlightTagsBySource(attrPackConfig, highlightSourceTagIds))
        XUiHelper.RefreshCustomizedList(self.PanelAttr, self.GridAttr, #attrConfigs, function (i, go)
            local config = attrConfigs[i]
            local attrValue = attrValues[i]

            local uiObj = self._Attrs[go]
            if uiObj == nil then
                uiObj = {}
                XUiHelper.InitUiClass(uiObj, go)
            end
            uiObj.ImgIcon:SetRawImage(config.Icon)
            if attrValue >= 0 then
                uiObj.TxtNum.text = string.format("%s + %s", config.Name, self._Control:FormatNumberWithUnit(attrValue))
            else
                uiObj.TxtNum.text = string.format("%s %s", config.Name, self._Control:FormatNumberWithUnit(attrValue))
            end
        end)
    else
        self.PanelAttr.gameObject:SetActiveEx(false)
        self._GridRelic:Close()
    end

    if XTool.IsNumberValid(rewardData.SkillId) then
        local skillCfg = self._Control:GetSkillCfgById(rewardData.SkillId)
        self._GridSkill:Open()
        self._GridSkill:Update(rewardData.SkillId, true)
        self._GridSkill:ShowTagHightLight(self._Control:CalcSkillHighlightTagsBySource(skillCfg, highlightSourceTagIds))
        self._GridSkill:CanUpgrade(self._Control:ShopHasCanUpGradeSkills(rewardData.SkillId))
    else
        self._GridSkill:Close()
    end
end

return XUiGridTheatre6Eitheror
