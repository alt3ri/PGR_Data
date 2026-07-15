local XUiEquipOverrunV4P6GridOverrunBase = require("XUi/XUiEquip/XUiEquipOverrunV4P6/XUiEquipOverrunV4P6GridOverrunBase")

---@class XUiEquipOverrunV4P6GridOverrunSuit : XUiEquipOverrunV4P6GridOverrunBase
local XUiEquipOverrunV4P6GridOverrunSuit = XClass(XUiEquipOverrunV4P6GridOverrunBase, "UiEquipOverrunV4P6GridOverrunSuit")

function XUiEquipOverrunV4P6GridOverrunSuit:OnStart(index, overrunCfgId)
    self.Index = index
    self.OverrunCfgId = overrunCfgId
    self:InitComponents()
end

function XUiEquipOverrunV4P6GridOverrunSuit:OnEnable()
    self:Refresh()
end

function XUiEquipOverrunV4P6GridOverrunSuit:InitComponents()
    self.BtnlLevel:AddEventListener(function() self:OnBtnlLevelClick() end)
    self.BtnAdd:AddEventListener(function() self:OnBtnAddClick() end)
    self.BtnChange:AddEventListener(function() self:OnBtnAddClick() end)
end

function XUiEquipOverrunV4P6GridOverrunSuit:OnBtnlLevelClick()
    self.Parent:OnClickGridOverrun(self.Index)
end

function XUiEquipOverrunV4P6GridOverrunSuit:OnBtnAddClick()
    if not self.Parent.Equip:IsOverrunCanBlindSuit() then
        return
    end

    XLuaUiManager.Open("UiEquipOverrunSelect", self.Parent.EquipId, function()
        self:Refresh()
    end)
end

function XUiEquipOverrunV4P6GridOverrunSuit:Refresh()
    local overrunCfg = self:GetOverrunConfig()
    self:RefreshName(overrunCfg)
    self:RefreshActiveBg(overrunCfg)
    self:RefreshDesc(overrunCfg)
    self:RefreshSelectState()
    self:RefreshNextTag(overrunCfg)
    self:RefreshLine(overrunCfg)
    self.BtnlLevel:ShowReddot(self.Parent.Equip:IsShowOverrunSuitRed())
end

function XUiEquipOverrunV4P6GridOverrunSuit:RefreshDesc(overrunCfg)
    local isActive = self:IsOverrunActive(overrunCfg)
    local choseSuit = self.Parent.Equip:GetOverrunChoseSuit()

    -- 按钮显示提示信息
    local tips = ""
    if not isActive then
        tips = CS.XTextManager.GetText("EquipOverrunUnActive")
    elseif choseSuit == 0 then
        tips = CS.XTextManager.GetText("EquipOverrunUnBindSuit")
    else
        tips = self._Control:GetSuitName(choseSuit)
    end
    self.BtnlLevel:SetNameByGroup(1, tips)

    -- 锁状态显示
    self.ImgBgLock.gameObject:SetActiveEx(not isActive)

    -- 加号图标显示
    self.BtnAdd.gameObject:SetActiveEx(isActive and choseSuit == 0)

    -- 已绑定套装显示
    local isBindSuit = isActive and choseSuit ~= 0
    self.BtnChange.gameObject:SetActiveEx(isBindSuit)
    if isBindSuit then
        local suitCfg = XMVCA.XEquip:GetConfigEquipSuit(choseSuit)
        self.ImgAwareness:SetSprite(suitCfg.IconPath)
    end
end

return XUiEquipOverrunV4P6GridOverrunSuit
