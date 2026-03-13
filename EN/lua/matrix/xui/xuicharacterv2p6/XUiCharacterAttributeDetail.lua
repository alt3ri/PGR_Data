---@class XUiCharacterAttributeDetail : XLuaUi
---@field BtnGroup XUiButtonGroup
local XUiCharacterAttributeDetail = XLuaUiManager.Register(XLuaUi, "UiCharacterAttributeDetail")

function XUiCharacterAttributeDetail:OnAwake()
    self:RegisterUiEvents()
    self:InitTab()
end

function XUiCharacterAttributeDetail:OnStart(characterId, tabIndex, initGeneralSkillIndex)
    self:RefreshByCharacterId(characterId, tabIndex, initGeneralSkillIndex)
end

function XUiCharacterAttributeDetail:OnEnable()
    if self.IsNeedRefresh then
        self.IsNeedRefresh = false
        local currentIndex = self.CurSelectTabIndex
        self.CurSelectTabIndex = nil
        self.BtnGroup:SelectIndex(currentIndex)
    end
end

function XUiCharacterAttributeDetail:OnDisable()
    self.IsNeedRefresh = true
end

function XUiCharacterAttributeDetail:OnGetLuaEvents()
    return {
        XEventId.EVENT_CHARACTER_SKILL_UNLOCK,
        XEventId.EVENT_CHARACTER_SKILL_UP,
        XEventId.EVENT_CHARACTER_ENHANCESKILL_UNLOCK,
        XEventId.EVENT_CHARACTER_ENHANCESKILL_UP,
    }
end

function XUiCharacterAttributeDetail:OnNotify(event, ...)
    if self.CurSelectTabIndex == XEnumConst.UiCharacterAttributeDetail.BtnTab.GeneralSkill then
        self:RefreshGeneralSkill()
    end
end

function XUiCharacterAttributeDetail:InitTab()
    local tabBtnList = { self.BtnTab1, self.BtnTab2, self.BtnTab3, self.BtnTab4 }
    self.BtnGroup:Init(tabBtnList, function(index)
        self:OnTabBtnClick(index)
    end)
end

function XUiCharacterAttributeDetail:OnTabBtnClick(index)
    if self.CurSelectTabIndex == index then
        return
    end
    self.CurSelectTabIndex = index
    self:RefreshCareerDetail()
    self:RefreshElementDetail()
    self:RefreshDamageDetail()
    self:RefreshGeneralSkill()
end

function XUiCharacterAttributeDetail:RefreshByCharacterId(characterId, tabIndex, initGeneralSkillIndex)
    if XTool.IsNumberValid(characterId) then
        if XRobotManager.CheckIsRobotId(characterId) then
            self.RobotId = characterId
        end
        characterId = XRobotManager.GetCharacterId(characterId)

        self.CharacterId = characterId
        self.InitGeneralSkillIndex = initGeneralSkillIndex

        self.GeneralSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(characterId)
        self.BtnTab4.gameObject:SetActiveEx(not XTool.IsTableEmpty(self.GeneralSkillIds))
    else
        self.CharacterId = characterId or 0
        self.BtnTab1.gameObject:SetActiveEx(false)
        self.BtnTab4.gameObject:SetActiveEx(false)
    end
    self.CurSelectTabIndex = nil
    self.BtnGroup:SelectIndex(tabIndex or 1)
end

function XUiCharacterAttributeDetail:RefreshCareerDetail()
    if not self.PanelCareerDetail then
        ---@type XUiPanelCharacterCareerDetail
        self.PanelCareerDetail = require("XUi/XUiCharacterV2P6/PanelAttribute/XUiPanelCharacterCareerDetail").New(self.Panel1, self)
    end

    if self.CurSelectTabIndex == XEnumConst.UiCharacterAttributeDetail.BtnTab.Career then
        self.PanelCareerDetail:Open()
        self.PanelCareerDetail:Refresh(self.CharacterId)
    else
        self.PanelCareerDetail:Close()
    end
end

function XUiCharacterAttributeDetail:RefreshElementDetail()
    if not self.PanelElementDetail then
        ---@type XUiPanelCharacterElementAndGeneralSkillDetail
        self.PanelElementDetail = require("XUi/XUiCharacterV2P6/PanelAttribute/XUiPanelCharacterElementAndGeneralSkillDetail").New(self.Panel2, self)
    end

    if self.CurSelectTabIndex == XEnumConst.UiCharacterAttributeDetail.BtnTab.Element then
        self.PanelElementDetail:Open()
        self.PanelElementDetail:Refresh(self.CharacterId)
    else
        self.PanelElementDetail:Close()
    end
end

function XUiCharacterAttributeDetail:RefreshDamageDetail()
    if not self.PanelDamageDetail then
        ---@type XUiPanelCharacterDamageDetail
        self.PanelDamageDetail = require("XUi/XUiCharacterV2P6/PanelAttribute/XUiPanelCharacterDamageDetail").New(self.Panel3, self)
    end

    if self.CurSelectTabIndex == XEnumConst.UiCharacterAttributeDetail.BtnTab.Damage then
        self.PanelDamageDetail:Open()
    else
        self.PanelDamageDetail:Close()
    end
end

function XUiCharacterAttributeDetail:RefreshGeneralSkill()
    if not self.PanelGeneralSkill then
        ---@type XUiPanelGeneralSkill
        self.PanelGeneralSkill = require("XUi/XUiCharacterV2P6/Grid/XUiPanelGeneralSkill").New(self.Panel4, self)
    end

    if self.CurSelectTabIndex == XEnumConst.UiCharacterAttributeDetail.BtnTab.GeneralSkill then
        self.PanelGeneralSkill:Open()
        self.PanelGeneralSkill:Refresh(self.CharacterId, self.InitGeneralSkillIndex, self.RobotId)
    else
        self.PanelGeneralSkill:Close()
    end
end

function XUiCharacterAttributeDetail:RegisterUiEvents()
    self.BtnClose:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnBackClick))
end

function XUiCharacterAttributeDetail:OnBtnBackClick()
    self:Close()
end

return XUiCharacterAttributeDetail
