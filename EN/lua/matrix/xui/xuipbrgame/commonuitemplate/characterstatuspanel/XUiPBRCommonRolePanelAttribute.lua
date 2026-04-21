
--- 通用的角色属性面板，其角色属性格子需是通用结构，自身需是非动态列表的滑动窗
---@class XUiPBRCommonRolePanelAttribute : XUiNode
---@field _Control XPBRGameControl
---@field ListAttribute UnityEngine.UI.ScrollRect
local XUiPBRCommonRolePanelAttribute = XClass(XUiNode, "XUiPBRCommonRolePanelAttribute")
local XUiPBRCommonRoleGridAttribute = require("XUi/XUiPBRGame/CommonUiTemplate/CharacterStatusPanel/XUiPBRCommonRoleGridAttribute")

function XUiPBRCommonRolePanelAttribute:OnStart(...)
    self:InitComponents()
end

function XUiPBRCommonRolePanelAttribute:OnEnable()
end

function XUiPBRCommonRolePanelAttribute:OnDisable()
end

function XUiPBRCommonRolePanelAttribute:OnDestroy()
    
end

function XUiPBRCommonRolePanelAttribute:InitComponents()

end

--- 获取角色属性信息，可由子类重写
---@return XPBRCharacterStatusParams[]
function XUiPBRCommonRolePanelAttribute:GetCharacterStatusInfo(customCharId)
    return self._Control.CharacterControl:GetCharacterStatusInfo(customCharId, true)
end

function XUiPBRCommonRolePanelAttribute:RefreshStatusShow(customCharId, resetScroll)
    if self._GridAttributeList == nil then
        self._GridAttributeList = {}
    else
        for i, v in pairs(self._GridAttributeList) do
            v:Close()
        end
    end
    
    local infos = self:GetCharacterStatusInfo(customCharId)
    
    XUiHelper.RefreshCustomizedList(self.Content, self.GridAttribute, infos and #infos or 0, function(index, go)
        local grid = self._GridAttributeList[go]

        if not grid then
            grid = XUiPBRCommonRoleGridAttribute.New(go, self)
            self._GridAttributeList[go] = grid
        end
        
        grid:Open()
        grid:Refresh(infos[index])
        grid:SetBgDisplayByIndex(index)
    end)

    if resetScroll then
        self.ListAttribute.verticalNormalizedPosition = 1
    end
end


return XUiPBRCommonRolePanelAttribute
