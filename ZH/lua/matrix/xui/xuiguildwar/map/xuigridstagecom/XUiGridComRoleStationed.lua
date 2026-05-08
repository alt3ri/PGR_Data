--- 公会战关卡节点UI，负责分担处理驻扎相关表现的组件
---@class XUiGridComRoleStationed
---@field _Control XGuildWarControl
---@field Parent XUiGridStage
local XUiGridComRoleStationed = XClass(XUiNode, 'XUiGridComRoleStationed')

function XUiGridComRoleStationed:OnStart()
    self:InitStationedNodes()
end

--- 初始化驻扎相关UI节点
--- 子类可重写此方法绑定具体节点
---@protected
function XUiGridComRoleStationed:InitStationedNodes()
    if self.ImgOtherStay then
        self.ImgOtherStay.gameObject:SetActiveEx(false)
    end

    if self.ImgSelfStay then
        self.ImgSelfStay.gameObject:SetActiveEx(false)
    end

    if self.ImgBuffMax then
        self.ImgBuffMax.gameObject:SetActiveEx(false)
    end
end

--- 刷新驻扎显示
function XUiGridComRoleStationed:RefreshStationedShow()
    self:UpdateStationedUI()
end

--- 更新驻扎UI显示
--- 子类可重写此方法实现具体的UI更新逻辑
---@param stateData table 驻扎状态数据
---@protected
function XUiGridComRoleStationed:UpdateStationedUI()
    local isSelfStationed = self._Control.RoleStationControl:CheckNodeIsAnyCharacterStationed(self.Parent.StageNodeId)
    local isOtherPlayerStationed = self._Control.RoleStationControl:CheckNodeHasOtherMemberStationed(self.Parent.StageNodeId)
    local isStationedBuffMax = self._Control.RoleStationControl:CheckNodeStationedEffectIsMax(self.Parent.StageNodeId)

    -- 自己驻扎标识：独立显示
    self:UpdateSelfStationedShow(isSelfStationed)

    -- 他人驻扎和效果满互斥，效果满优先级更高
    self:UpdateEffectMaxShow(isStationedBuffMax)
    self:UpdateAnyStationedShow(not isStationedBuffMax and isOtherPlayerStationed)
end

--- 更新是否有任何人驻扎的显示
---@param hasAnyStationed boolean 是否有任何人驻扎
---@protected
function XUiGridComRoleStationed:UpdateAnyStationedShow(hasAnyStationed)
    if self.ImgOtherStay then
         self.ImgOtherStay.gameObject:SetActiveEx(hasAnyStationed)
    end
end

--- 更新自己是否有驻扎的显示
---@param hasSelfStationed boolean 自己是否有驻扎
---@protected
function XUiGridComRoleStationed:UpdateSelfStationedShow(hasSelfStationed)
    if self.ImgSelfStay then
        self.ImgSelfStay.gameObject:SetActiveEx(hasSelfStationed)
    end
end

--- 更新驻扎效果是否满的显示
---@param isEffectMax boolean 驻扎效果是否满
---@protected
function XUiGridComRoleStationed:UpdateEffectMaxShow(isEffectMax)
    if self.ImgBuffMax then
         self.ImgBuffMax.gameObject:SetActiveEx(isEffectMax)
    end
end

return XUiGridComRoleStationed