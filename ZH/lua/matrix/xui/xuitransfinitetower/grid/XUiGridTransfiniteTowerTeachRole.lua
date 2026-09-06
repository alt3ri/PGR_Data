---@class XUiGridTransfiniteTowerTeachRole : XUiNode
---@field private _Control XTransfiniteTowerControl
---@field Parent XUiTransfiniteTowerTeach
---@field Head UnityEngine.GameObject
---@field BtnClick XUiComponent.XUiButton
local XUiGridTransfiniteTowerTeachRole = XClass(XUiNode, "XUiGridTransfiniteTowerTeachRole")

function XUiGridTransfiniteTowerTeachRole:OnStart()
    self.BtnClick:AddEventListener(handler(self, self.OnClick))
    -- Head 为通用头像子 prefab，展开一次以访问其 StandIcon
    self._HeadUi = XTool.InitUiObjectByUi({}, self.Head)
end

---UpdateDynamicItem 约定刷新方法
---@param data any 领航员数据
---@param index number 列表下标
function XUiGridTransfiniteTowerTeachRole:Update(data, index)
    self.Index = index
    self.Data = data

    local characterId = self._Control:GetPilotCharacterId(data)
    local icon = XMVCA.XCharacter:GetCharSmallHeadIcon(characterId)
    self._HeadUi.StandIcon:SetRawImage(icon)

    self:SetSelect(self.Parent:IsRoleSelected(index))
end

function XUiGridTransfiniteTowerTeachRole:OnClick()
    self.Parent:OnRoleSelected(self.Index)
end

function XUiGridTransfiniteTowerTeachRole:SetSelect(isSelect)
    -- 选中态由 BtnClick 的按钮状态实现（Select 态显示选中框）
    self.BtnClick:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

return XUiGridTransfiniteTowerTeachRole
