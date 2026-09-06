local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

---@class XUiPunishaarMainModelShow : XUiNode
local XUiPunishaarMainModelShow = XClass(XUiNode, "XUiPunishaarMainModelShow")

local MODEL_COUNT = 4

function XUiPunishaarMainModelShow:OnStart()
    self._RoleModelPanels = {}

    for i = 1, MODEL_COUNT do
        local node = self["PanelRoleModel" .. i]

        if node then
            local panel = XUiPanelRoleModel.New(
                node,
                "PunishaarMainModel" .. i,
                true
            )

            panel:ShowRoleModel()
            self._RoleModelPanels[i] = panel
        else
            XLog.Error(
                "UiPunishaarMain缺少模型挂点：PanelRoleModel" .. i
            )
        end
    end
end

function XUiPunishaarMainModelShow:OnEnable()
    self:RefreshModels()
end

function XUiPunishaarMainModelShow:OnDisable()
    self:ReleaseModels()
end

function XUiPunishaarMainModelShow:OnDestroy()
    if not self._RoleModelPanels then
        return
    end

    for _, panel in pairs(self._RoleModelPanels) do
        panel:RemoveRoleModelPool()
    end

    self._RoleModelPanels = nil
end

function XUiPunishaarMainModelShow:RefreshModels()
    for i = 1, MODEL_COUNT do
        local cardId = self._Control:GetMainShowCardId(i)
        local animaName = self._Control:GetMainShowAnimaName(i)

        self:RefreshModel(i, cardId, animaName)
    end
end

function XUiPunishaarMainModelShow:RefreshModel(index, cardId, animaName)
    local panel = self._RoleModelPanels[index]
    if not panel then
        return
    end

    if not XTool.IsNumberValid(cardId) then
        panel:ReleaseCurrentModel()
        return
    end

    local modelCfg = self._Control:GetTablePunishaarCardModel(cardId, true)

    if not modelCfg or string.IsNilOrEmpty(modelCfg.ModelId) then
        panel:ReleaseCurrentModel()
        XLog.Error("Punishaar主界面模型配置不存在，cardId=" .. cardId)
        return
    end

    if string.IsNilOrEmpty(animaName) then
        animaName = modelCfg.NormalIdleAnima
    end

    panel:UpdateCuteModelByModelName(
        nil,
        nil,
        nil,
        nil,
        nil,
        modelCfg.ModelId,
        function()
            CS.XShadowHelper.AddShadow(
                panel.GameObject,
                true
            )
        end,
        true
    )

    panel:ShowRoleModel()

    if not string.IsNilOrEmpty(animaName) then
        panel:PlayAnimaCross(animaName)
    end
end

function XUiPunishaarMainModelShow:ReleaseModels()
    if not self._RoleModelPanels then
        return
    end

    for _, panel in pairs(self._RoleModelPanels) do
        panel:ReleaseCurrentModel()
    end
end

function XUiPunishaarMainModelShow:PlayStartAnimation()
    self.Start:PlayTimelineAnimation()
end

return XUiPunishaarMainModelShow