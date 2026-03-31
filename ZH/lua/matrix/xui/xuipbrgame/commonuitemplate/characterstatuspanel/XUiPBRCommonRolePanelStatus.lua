--- 通用的角色状态面板，包括属性和专属信息，属性和专属信息必须也是通用的
---@class XUiPBRCommonRolePanelStatus : XUiNode
---@field PanelTabGroup XUiButtonGroup
local XUiPBRCommonRolePanelStatus = XClass(XUiNode, "XUiPBRCommonRolePanelStatus")

local XUiPBRCommonRolePanelAttribute = require("XUi/XUiPBRGame/CommonUiTemplate/CharacterStatusPanel/XUiPBRCommonRolePanelAttribute")
local XUiPBRCommonRolePanelExclusive = require("XUi/XUiPBRGame/CommonUiTemplate/CharacterStatusPanel/XUiPBRCommonRolePanelExclusive")

local BtnTabIndexMap = {
    Attribute = 1,
    Exclusive = 2,
}

function XUiPBRCommonRolePanelStatus:OnStart(customCharId)
    self.CustomCharId = customCharId
    
    self:InitComponents()
end

function XUiPBRCommonRolePanelStatus:OnEnable()
end

function XUiPBRCommonRolePanelStatus:OnDisable()
end

function XUiPBRCommonRolePanelStatus:OnDestroy()
    
end

function XUiPBRCommonRolePanelStatus:InitComponents()
    -- Button
    self.BtnClose:AddEventListener(function() self:OnBtnCloseClick() end)

    -- 节点默认隐藏
    self.ListAttribute.gameObject:SetActiveEx(false)
    self.ListExclusive.gameObject:SetActiveEx(false)
    -- XUiNode
    ---@type XUiPBRCommonRolePanelAttribute
    self.ListAttribute = self:GetPanelAttributeCls().New(self.ListAttribute, self)
    ---@type XUiPBRCommonRolePanelExclusive
    self.ListExclusive = self:GetPanelExclusiveCls().New(self.ListExclusive, self)

    -- 初始化页签
    self.BtnTabGroup = {
        self.GridTabAttribute,
        self.GridTabExclusive,
    }

    self.PanelTabGroup:Init(self.BtnTabGroup, handler(self, self.OnGroupTabIndex), 1)
    self.PanelTabGroup:SelectIndex(1)
end

--- 获取属性面板类（基类或其派生类），子类可重写此方法以使用不同的属性面板
function XUiPBRCommonRolePanelStatus:GetPanelAttributeCls()
    return XUiPBRCommonRolePanelAttribute
end

--- 获取专属面板类（基类或其派生类），子类可重写此方法以使用不同的专属面板
function XUiPBRCommonRolePanelStatus:GetPanelExclusiveCls()
    return XUiPBRCommonRolePanelExclusive
end


function XUiPBRCommonRolePanelStatus:OnBtnCloseClick()
    self:Close()
end

function XUiPBRCommonRolePanelStatus:OnGroupTabIndex(index)
    if index == self.CurIndex then
        return
    end
    
    self.CurIndex = index

    self.ListAttribute:Close()
    self.ListExclusive:Close()

    if index == BtnTabIndexMap.Attribute then
        self.ListAttribute:Open()
        self.ListAttribute:RefreshStatusShow(self.CustomCharId, true)
    elseif index == BtnTabIndexMap.Exclusive then
        self.ListExclusive:Open()
        self.ListExclusive:RefreshCharacterExclusiveDesc(self.CustomCharId, true)
    end
end

return XUiPBRCommonRolePanelStatus
