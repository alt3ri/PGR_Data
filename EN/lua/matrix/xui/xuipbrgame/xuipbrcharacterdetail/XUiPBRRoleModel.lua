---@class XUiPBRRoleModel: XUiNode
---@field protected _Control
---@field Parent
local XUiPBRRoleModel = XClass(XUiNode, "XUiPBRRoleModel")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiPBRRoleModel:OnStart()
    local uiModelRoot = self.Parent.UiModelGo.transform
    
    local uiNearRoot = uiModelRoot:FindTransform("UiNearRoot")

    local roleModelRoot = nil
    
    if uiNearRoot then
        roleModelRoot = uiNearRoot:FindTransform("PanelRoleModel")

        if roleModelRoot == nil then
            roleModelRoot = uiNearRoot
        end
    end

    if roleModelRoot then
        ---@type XUiPanelRoleModel
        self._PanelRoleModel = XUiPanelRoleModel.New(roleModelRoot, self.Parent.Name, true, true, false, true, false)
    else
        XLog.Error('角色模型生成挂点丢失， 请检查镜头资源是否包含：UiNearRoot或PanelRoleModel节点')
    end
end

function XUiPBRRoleModel:InitShowCharacter(cuteModelName)
    if self._PanelRoleModel then
        self._PanelRoleModel:UpdateCuteModelByModelName(nil, nil, nil, nil, nil,
                cuteModelName, function()
                    CS.XShadowHelper.AddShadow(self._PanelRoleModel.GameObject, true)
                end, true)
        self._PanelRoleModel:ShowRoleModel()
    end
end

function XUiPBRRoleModel:PlayRoleAnimation(animName)
    if self._PanelRoleModel then
        if not string.IsNilOrEmpty(animName) then
            self._PanelRoleModel:PlayAnima(animName)
        end
    end
end

return XUiPBRRoleModel