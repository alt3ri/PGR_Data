---角色界面
---@class XUiTheatre5PVECheckCharacter: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5PVECheckCharacter = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PVECheckCharacter')
local XUiPanelTheatre5Skill = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiPanelTheatre5Skill')
local XUiGridTheatre5Container = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Container')
local XUiPanelTheatre5Gem = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiPanelTheatre5Gem')
local XUiGridTheatre5ShowGemSlot = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5ShowGemSlot')
local XUiModelTheatre5PVPCharacter3D = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiModelTheatre5PVPCharacter3D')
local XUiPanelTheatre5Bag = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiPanelTheatre5Bag')
local XUiTheatre5Level = require("XUi/XUiTheatre5/XUiTheatre5Level/XUiTheatre5Level")
local XUiTheatre5RelicPanel = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiTheatre5RelicPanel')
local XUiTheatre5MissionPanelInCheck = require('XUi/XUiTheatre5/XUiTheatre5PVECheckCharacter/XUiTheatre5MissionPanelInCheck')

function XUiTheatre5PVECheckCharacter:OnAwake()
    self:AddUIListener()
    if self.PanelCharacterLv then
        self.LevelPanel = XUiTheatre5Level.New(self.PanelCharacterLv, self)
        self.LevelPanel.BtnUpgrade.gameObject:SetActiveEx(false)
    end
    if self.ListRelicBag then
        ---@type XUiTheatre5RelicPanel
        self.PanelRelic = XUiTheatre5RelicPanel.New(self.ListRelicBag, self)
    end
end

function XUiTheatre5PVECheckCharacter:OnStart()
    ---@type XUiPanelTheatre5Skill
    self.PanelSkill = XUiPanelTheatre5Skill.New(self.ListSkillBag, self, XUiGridTheatre5Container, XMVCA.XTheatre5.EnumConst.ItemContainerType.NormalDetails)
    ---@type XUiPanelTheatre5Gem
    self.PanelGem = XUiPanelTheatre5Gem.New(self.PanelGem, self, XUiGridTheatre5ShowGemSlot, XMVCA.XTheatre5.EnumConst.ItemContainerType.NormalDetails)
    ---@type XUiModelTheatre5PVPCharacter3D
    self.Model3D = XUiModelTheatre5PVPCharacter3D.New(self.UiModelGo, self)
    ---@type XUiPanelTheatre5Bag
    self.PanelBag = XUiPanelTheatre5Bag.New(self.ListBag, self, XMVCA.XTheatre5.EnumConst.ItemContainerType.NormalDetails)
    ---@type XUiTheatre5MissionPanelInCheck
    self.PanelMission = XUiTheatre5MissionPanelInCheck.New(self.PanelTask, self)
    
    self.PanelSkill:Open()
    self.PanelGem:Open()
    self:InitCharacter3D()
end

function XUiTheatre5PVECheckCharacter:OnEnable()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_OPEN_ITEM_DETAIL, self.OnItemDetailOpenEvent, self)
    self.PanelSkill:RefreshSkillShow()
    self.PanelGem:RefreshGemShow()
    self.PanelBag:RefreshBagShow()
    self.PanelBag:NotAllowDrag()
end

function XUiTheatre5PVECheckCharacter:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_OPEN_ITEM_DETAIL, self.OnItemDetailOpenEvent, self)
end

function XUiTheatre5PVECheckCharacter:AddUIListener()
    self:RegisterClickEvent(self.BtnBack, self.Close, true)
    self:BindHelpBtn(self.BtnHelp, 'Theatre5') --先占坑
    self:RegisterClickEvent(self.BtnName, self.OnBtnNameClickEvent, true)
end

function XUiTheatre5PVECheckCharacter:InitCharacter3D()
    ---@type XTableTheatre5Character
    local characterCfg = self._Control:GetCurCharacterCfg()

    if characterCfg then
        local animatorController = self._Control.CharacterControl:GetAnimatorControllerByCharacterIdCurMode(characterCfg.Id)
        local detailIdleAnima = self._Control.CharacterControl:GetDetailIdleAnimaByCharacterIdCurMode(characterCfg.Id)
        local fashionId, weaponId = self._Control.CharacterControl:GetMainlineFashionIdByCharacterIdCurMode(characterCfg.Id)

        self.Model3D:UpdateRoleModelByHand(characterCfg.CharacterId, fashionId, weaponId, animatorController)
        -- 播放战备界面的待机动画
        if not string.IsNilOrEmpty(detailIdleAnima) then
            self.Model3D.UiPanelRoleModel:PlayAnima(detailIdleAnima)
        end
        self.BtnName:SetNameByGroup(0, characterCfg.Name)
    end
end

function XUiTheatre5PVECheckCharacter:OnItemDetailOpenEvent(itemData, containerType, uiPos)
    if not XLuaUiManager.IsUiShow('UiTheatre5BubbleItemDetail') then
        XLuaUiManager.Open('UiTheatre5BubbleItemDetail', itemData, XMVCA.XTheatre5.EnumConst.ItemContainerType.NormalDetails, uiPos)
    else
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_ITEM_DETAIL, itemData,
                XMVCA.XTheatre5.EnumConst.ItemContainerType.NormalDetails, uiPos)
    end
end

function XUiTheatre5PVECheckCharacter:OnBtnNameClickEvent()
    XLuaUiManager.Open('UiTheatre5BubbleCharacterDetail')
end

return XUiTheatre5PVECheckCharacter