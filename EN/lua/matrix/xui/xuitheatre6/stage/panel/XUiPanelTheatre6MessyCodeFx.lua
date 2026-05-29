---@class XUiPanelTheatre6MessyCodeFx : XUiNode 乱码特效面板（按服务端推送加载/销毁特效）
---@field _Control XTheatre6Control
---@field Node UnityEngine.RectTransform
local XUiPanelTheatre6MessyCodeFx = XClass(XUiNode, "XUiPanelTheatre6MessyCodeFx")

function XUiPanelTheatre6MessyCodeFx:OnStart()
    ---@type table<number, UnityEngine.RectTransform> key=特效Id value=实例化出来的Node
    self._FxNodeDict = {}
    self.Node.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre6MessyCodeFx:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_MESSY_CODE_ADD, self.OnAddMessyCode, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_MESSY_CODE_DEL, self.OnDelMessyCode, self)
    self:RefreshAll()
end

function XUiPanelTheatre6MessyCodeFx:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_MESSY_CODE_ADD, self.OnAddMessyCode, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_MESSY_CODE_DEL, self.OnDelMessyCode, self)
end

function XUiPanelTheatre6MessyCodeFx:OnDestroy()
    self:DestroyAll()
end

---按 Model 当前全量数据补齐特效（进入界面/切换房间时使用）
function XUiPanelTheatre6MessyCodeFx:RefreshAll()
    local messyCodes = self._Control:GetMessyCodes()
    local activeIdSet = {}
    if messyCodes then
        for _, effectId in pairs(messyCodes) do
            activeIdSet[effectId] = true
        end
    end

    -- 销毁已不存在的
    for effectId, _ in pairs(self._FxNodeDict) do
        if not activeIdSet[effectId] then
            self:_DestroyFx(effectId)
        end
    end

    -- 新增缺失的
    for effectId, _ in pairs(activeIdSet) do
        self:_LoadFx(effectId)
    end
end

function XUiPanelTheatre6MessyCodeFx:OnAddMessyCode(effectId)
    if not XTool.IsNumberValid(effectId) then
        return
    end
    self:_LoadFx(effectId)
end

function XUiPanelTheatre6MessyCodeFx:OnDelMessyCode(effectId)
    if not XTool.IsNumberValid(effectId) then
        return
    end
    self:_DestroyFx(effectId)
end

function XUiPanelTheatre6MessyCodeFx:_LoadFx(effectId)
    if self._FxNodeDict[effectId] then
        return
    end
    local config = self._Control:GetStageEffectConfig(effectId)
    local nodeObj = XUiHelper.Instantiate(self.Node, self.Node.parent)
    nodeObj.gameObject:SetActiveEx(true)
    nodeObj:LoadUiEffect(config.EffectLut)
    self._FxNodeDict[effectId] = nodeObj
end

function XUiPanelTheatre6MessyCodeFx:_DestroyFx(effectId)
    local nodeObj = self._FxNodeDict[effectId]
    if not XTool.UObjIsNil(nodeObj) then
        CS.UnityEngine.Object.Destroy(nodeObj.gameObject)
    end
    self._FxNodeDict[effectId] = nil
end

function XUiPanelTheatre6MessyCodeFx:DestroyAll()
    for effectId, _ in pairs(self._FxNodeDict) do
        self:_DestroyFx(effectId)
    end
    self._FxNodeDict = {}
end

return XUiPanelTheatre6MessyCodeFx
