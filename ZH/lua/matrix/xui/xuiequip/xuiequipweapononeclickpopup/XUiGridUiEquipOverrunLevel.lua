-- 谐振等级 Grid：展示单个谐振节点的激活/未激活态、等级、绑定意识/技能图标
-- 根节点挂 XUiButton，需 prefab 绑定为 ButtonOverrunLevel
---@class XUiGridUiEquipOverrunLevel:XUiNode
---@field Parent XUiEquipWeaponOneClickPopup
---@field ButtonOverrunLevel XUiComponent.XUiButton
---@field ImgBgLevelOn UnityEngine.RectTransform
---@field ImgBgLevelOff UnityEngine.RectTransform
---@field ImgBgLock UnityEngine.RectTransform
---@field ImgAwareness UnityEngine.UI.RawImage
---@field PanelDot UnityEngine.RectTransform
---@field ImgDotLevelOn UnityEngine.RectTransform
---@field ImgDotLevelOff UnityEngine.RectTransform
---@field UiTxtLevelImg1 UnityEngine.RectTransform
---@field UiTxtLevelImg2 UnityEngine.RectTransform
local XUiGridUiEquipOverrunLevel = XClass(XUiNode, "XUiGridUiEquipOverrunLevel")

local OVERRUN_LEVEL_1 = 1
local OVERRUN_LEVEL_2 = 2

function XUiGridUiEquipOverrunLevel:OnStart()
end

--- 刷新一个谐振等级节点
---@param data table { Level, IsPreviewActive, Title, Desc, AwarenessIcon }
function XUiGridUiEquipOverrunLevel:Update(data)
    self.Data = data
    local isActive = data.IsPreviewActive == true

    self.ButtonOverrunLevel:SetNameByGroup(0, data.Title or "")
    self.ButtonOverrunLevel:ActiveTextByGroup(0, not string.IsNilOrEmpty(data.Title))
    self.ButtonOverrunLevel:SetNameByGroup(1, data.Desc or "")
    self.ImgLock.gameObject:SetActiveEx(not isActive)
    self.ImgBgLevelOn.gameObject:SetActiveEx(isActive)
    self.ImgBgLevelOff.gameObject:SetActiveEx(not isActive)
    if self.ImgBgLock then
        self.ImgBgLock.gameObject:SetActiveEx(not isActive)
    end

    self:_RefreshLevelIcon(data.Level, isActive)

    self.ImgAwareness:SetSprite(data.AwarenessIcon)
end

function XUiGridUiEquipOverrunLevel:_RefreshLevelIcon(level, isActive)
    local isLv1 = level == OVERRUN_LEVEL_1
    local isLv2 = level == OVERRUN_LEVEL_2
    local isDotLevel = not isLv1 and not isLv2

    self.UiTxtLevelImg1.gameObject:SetActiveEx(isLv1)
    self.UiTxtLevelImg2.gameObject:SetActiveEx(isLv2)

    self.PanelDot.gameObject:SetActiveEx(isDotLevel)
    self.PanelLevelIcon.gameObject:SetActiveEx(not isDotLevel)
    if isDotLevel then
        self.ImgDotLevelOn.gameObject:SetActiveEx(isActive)
        self.ImgDotLevelOff.gameObject:SetActiveEx(not isActive)
    end
end

return XUiGridUiEquipOverrunLevel
