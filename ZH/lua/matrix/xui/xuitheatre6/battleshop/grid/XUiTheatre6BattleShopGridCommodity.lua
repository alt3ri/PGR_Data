---@class XUiTheatre6BattleShopGridCommodity : XUiNode
---@field _Control XTheatre6Control
---@field GridSkill UiObject
---@field GridRelic UiObject
---@field ListDesc UnityEngine.RectTransform
---@field TagSkill UiObject
---@field TagLock UnityEngine.RectTransform
---@field BtnGrid XUiComponent.XUiButton
---@field SellOut UnityEngine.RectTransform

local XUiTheatre6BattleShopGridCommodity = XClass(XUiNode, "XUiTheatre6BattleShopGridCommodity")
local XUiGridTheatre6Skill = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Skill")
local XUiGridTheatre6Relic = require("XUi/XUiTheatre6/Character/Grid/XUiGridTheatre6Relic")
local ItemType = {
    None = 0,
    Skill = 1,
    AttrPack = 2,
}
local CoinStatus = {
    Free = 1,
    Enough = 2,
    NoEnough = 3,
}
function XUiTheatre6BattleShopGridCommodity:OnStart()
    self:InitComponents()
end

function XUiTheatre6BattleShopGridCommodity:InitComponents()
    self.GridSkillUi = XUiGridTheatre6Skill.New(self.GridSkill, self)
    self.GridRelicUi = XUiGridTheatre6Relic.New(self.GridRelic, self)

    self.BtnGrid:AddEventListener(handler(self, self.OnBtnGridClick))
    self.UiTxtDesc.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
    self._AvoidTransforms = { self.Transform, self.Parent.PanelRoleDetail.Transform }
end

function XUiTheatre6BattleShopGridCommodity:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE6_LOCK_GOOD,
        XEventId.EVENT_THEATRE6_BUY_GOOD,
        XEventId.EVENT_THEATRE6_GOLD_CHANGE,
        XEventId.EVENT_THEATRE6_UPDATE_SKILL,
    }
end

function XUiTheatre6BattleShopGridCommodity:OnNotify(evt, ...)
    local args = { ... }
    if evt == XEventId.EVENT_THEATRE6_LOCK_GOOD then
        self:OnLockClick(args[1], args[2])
    elseif evt == XEventId.EVENT_THEATRE6_BUY_GOOD then
        if args[1] == self.GridData.Position then
            self.IsSell = true
            self:RefreshSellStatus()
            self.IsLock = false
            self:RefreshLockStatus()
        else
            self:RefreshCanUpgrade()
        end
    elseif evt == XEventId.EVENT_THEATRE6_GOLD_CHANGE then
        if not self:IsSellOut() then
            self:RefreshBuyBtnStatus()
        end
    elseif evt == XEventId.EVENT_THEATRE6_UPDATE_SKILL then
        self:RefreshCanUpgrade()
    end
end

function XUiTheatre6BattleShopGridCommodity:RefreshCanUpgrade()
    if self:IsSellOut() then return end
    if not self.GridData or self.GridData.Type ~= ItemType.Skill then return end
    self.GridSkillUi:CanUpgrade(self._Control:ShopHasCanUpGradeSkills(self.GridData.GoodId))
end

function XUiTheatre6BattleShopGridCommodity:CloseAllGridUis()
    self.GridSkillUi:Close()
    self.GridRelicUi:Close()
    self.ListDesc.gameObject:SetActiveEx(false)
    self.PanelSkillTag.gameObject:SetActiveEx(false)
    self.PanelRelicTag.gameObject:SetActiveEx(false)
end

function XUiTheatre6BattleShopGridCommodity:Refresh(data)
    self.GridData = data
    self.IsLock = self.GridData.IsLock
    self.IsSell = self.GridData.IsSell
    self:CloseAllGridUis()
    local gridUi = nil
    if self.GridData.Type == ItemType.Skill then
        self.GridSkillUi:Open()
        self.GridSkillUi:Update(self.GridData.GoodId, nil, self.GridData)
        self.GridSkillUi:CanUpgrade(self._Control:ShopHasCanUpGradeSkills(self.GridData.GoodId))
        self.PanelSkillTag.gameObject:SetActiveEx(true)
        gridUi = self.GridSkillUi
    elseif self.GridData.Type == ItemType.AttrPack then
        self.GridRelicUi:Open()
        self.GridRelicUi:Update(self.GridData.GoodId)
        gridUi = self.GridRelicUi
        self.PanelRelicTag.gameObject:SetActiveEx(true)
    end
    self.ListDesc.gameObject:SetActiveEx(true)
    self.UiTxtDesc.text = gridUi:GetDesc()
    self.BuyPrice = gridUi:GetBuyPrice()
    self.BtnGrid:SetRawImage(self._Control:GetCoinIcon())
    self:RefreshBuyBtnStatus()

    self:RefreshLockStatus()
    self:RefreshBuildTag()
    self:RefreshSellStatus()
end

function XUiTheatre6BattleShopGridCommodity:RefreshLockStatus()
    self.TagLock.gameObject:SetActiveEx(self.IsLock)
end

function XUiTheatre6BattleShopGridCommodity:RefreshBuyBtnStatus()
    local price = self.BuyPrice
    local showPrice = tostring(price)
    if not self._Control:IsCoinEnough(tonumber(price) or 0) then
        showPrice = string.format("<color=#%s>%s</color>",
            self._Control:GetClientConfigValue("ShopRefreshColor", CoinStatus.NoEnough), price)
    end
    self.BtnGrid:SetNameByGroup(0, showPrice)
end

function XUiTheatre6BattleShopGridCommodity:OnBtnGridClick()
    if self:IsSellOut() then return end
    local gridStatus = {
        ReadOnly = false,
        IsSell = self:IsSellOut(),
        IsLock = self.IsLock,
        IsInShop = true,
        Pos = self.GridData.Position
    }
    if self.GridData.Type == ItemType.Skill then
        self._Control:OpenSkillTip(self.GridData.GoodId, self.Transform, gridStatus,self._AvoidTransforms)
    elseif self.GridData.Type == ItemType.AttrPack then
        self._Control:OpenRelicTip(self.GridData.GoodId, self.Transform, gridStatus,self._AvoidTransforms)
    end
end

function XUiTheatre6BattleShopGridCommodity:OnLockClick(isLock, pos)
    if pos ~= self.GridData.Position then return end
    self.IsLock = isLock
    self:RefreshLockStatus()
end

function XUiTheatre6BattleShopGridCommodity:IsSellOut()
    return self.IsSell
end

function XUiTheatre6BattleShopGridCommodity:RefreshBuildTag()
    if self.GridData.Type == ItemType.Skill then
        local skillConfig = self._Control:GetSkillCfgById(self.GridData.GoodId)
        local buildTagCfgs = self._Control:GetShowBuildTagWithSort(skillConfig.BuildTags)
        XUiHelper.RefreshCustomizedList(self.TagSkill.transform.parent, self.TagSkill,
            #buildTagCfgs,
            function(i, grid)
                local cfg = buildTagCfgs[i]
                local ui = {}
                XTool.InitUiObjectByUi(ui, grid)
                ui.ImgIcon:SetRawImage(cfg.Icon)
                ui.UiTxtName.text = cfg.Name
            end, false)
    else
        local relicConfig = self._Control:GetAttrPackCfgById(self.GridData.GoodId)
        -- local attrCfgs = self._Control:GetShowAttributeWithSort(relicConfig.AttrTypes)
        local attrConfigs, attrValues = self._Control:GetShowAttribute(relicConfig.AttrTypes, relicConfig.AttrNums)
        XUiHelper.RefreshCustomizedList(self.TagRelic.transform.parent, self.TagRelic,
            #attrConfigs,
            function(i, grid)
                local cfg = attrConfigs[i]
                local ui = {}
                local attrValue = attrValues[i]
                XTool.InitUiObjectByUi(ui, grid)
                if ui.ImgIcon.SetSprite then
                    ui.ImgIcon:SetSprite(cfg.Icon)
                else
                    ui.ImgIcon:SetRawImage(cfg.Icon)
                end
                local subStr = attrValue > 0 and "+" or ""
                ui.UiTxtName.text = string.format("%s%s", subStr, self._Control:FormatNumberWithUnit(attrValue))
            end, false)
    end
end

function XUiTheatre6BattleShopGridCommodity:RefreshSellStatus()
    self.SellOut.gameObject:SetActiveEx(self:IsSellOut())

    self.BtnGrid:SetDisable(self:IsSellOut())


    if self:IsSellOut() then
        self:CloseAllGridUis()
        return
    end
end

return XUiTheatre6BattleShopGridCommodity
