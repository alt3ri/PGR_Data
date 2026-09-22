---@class XPanelCharacterLevelV2P6 : XUiNode
---@field _Control XCharacterControl
local XPanelCharacterLevelV2P6 = XClass(XUiNode, "XPanelCharacterLevelV2P6")

function XPanelCharacterLevelV2P6:OnStart()
    local XUiPanelSelectLevelItems = require("XUi/XUiCharacter/XUiPanelSelectLevelItems") --XUiPanelSelectLevelItems,
    self.SelectLevelItems = XUiPanelSelectLevelItems.New(self.PanelSelectLevelItems, self, self.Parent)

    self:InitButton()
end

function XPanelCharacterLevelV2P6:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnLevelUpButton, self.OnBtnLevelUpButtonClick)
    XUiHelper.RegisterClickEvent(self, self.BtnGetMore, self.OnBtnGetMoreClick)
    self.BtnOneClick:AddEventListener(handler(self, self.OnBtnOneClickClick))
end

function XPanelCharacterLevelV2P6:OnBtnOneClickClick()
    XMVCA.XCharacter:OpenUiRoleCultureDetailMain(self.CharacterId)
end

function XPanelCharacterLevelV2P6:RefreshUiShow()
    self.CharacterId = self.Parent.ParentUi.CurCharacter.Id

    -- self.LeveInfoQiehuan:PlayTimelineAnimation()
    self.PanelLeveInfo.gameObject:SetActive(true)
    local isOneClickOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.CharacterOneClick)
        and self._Control:CheckRoleCultureHasAnyUpgradableByCurState(self.CharacterId)
    self.BtnOneClick.gameObject:SetActiveEx(isOneClickOpen)
    self:RefreshTrainingItemBubble()
    self:HideSelectLevelItems()
    self:UpdatePanel()
    self:CheckMaxLevel()
end

--- 一键养成道具持有提示：有道具才展示气泡
function XPanelCharacterLevelV2P6:RefreshTrainingItemBubble()
    local count = self._Control:GetRoleCultureSpecialItemCount()
    self.GroupBubble.gameObject:SetActiveEx(count > 0)
    if count <= 0 then
        return
    end
    self.IconTrainingItem:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self._Control:GetRoleCultureSpecialItemId()))
    self.TxtItemNum.text = "x" .. count
end

function XPanelCharacterLevelV2P6:HideSelectLevelItems()
    if self.GameObject.activeSelf then
        self.SelectLevelItemsDisable:PlayTimelineAnimation()
    end
    self.SelectLevelItems:HidePanel()
end

function XPanelCharacterLevelV2P6:CheckMaxLevel()
    local isMaxLevel = XMVCA.XCharacter:IsMaxLevel(self.CharacterId)
    self.BtnLevelUpButton.gameObject:SetActive(not isMaxLevel)
    self.ImgMaxLevel.gameObject:SetActive(isMaxLevel)
end

function XPanelCharacterLevelV2P6:UpdatePanel()
    local characterId = self.CharacterId
    local character = XMVCA.XCharacter:GetCharacter(characterId)
    local nextLeveExp = XMVCA.XCharacter:GetNextLevelExp(characterId, character.Level)
    local isMaxLevel = XMVCA.XCharacter:IsMaxLevel(characterId)
    self.TxtCurLevel.text = character.Level
    self.TxtMaxLevel.text = "/" .. XMVCA.XCharacter:GetCharMaxLevel(characterId)
    local exp = isMaxLevel and nextLeveExp or character.Exp
    self.TxtExp.text = exp .. "/" .. nextLeveExp
    self.ImgFill.fillAmount = exp / nextLeveExp
    self.TxtAttack.text = FixToInt(character.Attribs[XNpcAttribType.AttackNormal])
    self.TxtLife.text = FixToInt(character.Attribs[XNpcAttribType.Life])
    self.TxtDefense.text = FixToInt(character.Attribs[XNpcAttribType.DefenseNormal])
    self.TxtCrit.text = FixToInt(character.Attribs[XNpcAttribType.Crit])
end

function XPanelCharacterLevelV2P6:OnBtnLevelUpButtonClick()
    self.SelectLevelItems:ShowPanel(self.CharacterId)
    self.SelectLevelItemsEnable:PlayTimelineAnimation()
    self.PanelLeveInfo.gameObject:SetActive(false)

    self.Parent.ParentUi:SetBackTrigger(function ()
        self.Parent.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.Train)
        self:RefreshUiShow()
    end)

    self.Parent.ParentUi:SetCamera(XEnumConst.CHARACTER.CameraV2P6.LvUseItem)
    self.Parent.ParentUi:ReturnModelToInitRotation()
end

function XPanelCharacterLevelV2P6:OnBtnGetMoreClick()
    local skipIdString = CS.XGame.ClientConfig:GetString("PanelCharacterLevelSkipIds")
    local skipIds = string.ToIntArray(skipIdString, '|')
    XLuaUiManager.Open("UiEquipStrengthenSkip", skipIds)
end

return XPanelCharacterLevelV2P6
