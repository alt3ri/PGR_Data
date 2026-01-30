local XUiBWPanelAssetTool = require("XUi/XUiBigWorld/XCommon/XPanelAsset/XUiBWPanelAssetTool")

---@class XUiBWPanelAsset : XUiNode
---@field PanelTool1 UnityEngine.RectTransform
---@field PanelTool2 UnityEngine.RectTransform
---@field PanelTool3 UnityEngine.RectTransform
local XUiBWPanelAsset = XClass(XUiNode, "XUiBWPanelAsset")

function XUiBWPanelAsset:OnStart(itemIds)
    self._ItemIds = itemIds
    self._BindNodes = {}

    ---@type XUiBWPanelAssetTool[]
    self._Tools = {
        XUiBWPanelAssetTool.New(self.PanelTool1, self), 
        XUiBWPanelAssetTool.New(self.PanelTool2, self),
        XUiBWPanelAssetTool.New(self.PanelTool3, self),
    }
end

function XUiBWPanelAsset:OnEnable()
    self:_Refresh()
    self:_RegisterEvent()
end

function XUiBWPanelAsset:OnDisable()
    self:_RemoveEvent()
end

function XUiBWPanelAsset:OnItemCountUpdate()
    self:_Refresh()
end

function XUiBWPanelAsset:Refresh(itemIds)
    self._ItemIds = itemIds

    self:_RemoveEvent()
    self:_RegisterEvent()
    self:_Refresh()
end

function XUiBWPanelAsset:_Refresh()
    local index = 1

    if not XTool.IsTableEmpty(self._ItemIds) then
        for _, itemId in pairs(self._ItemIds) do
            local tool = self._Tools[index]

            if tool then
                tool:Open()
                tool:Refresh(itemId)
            end

            index = index + 1
        end
    end

    for i = index, #self._Tools do
        self._Tools[i]:Close()
    end
end

function XUiBWPanelAsset:_RegisterEvent()
    if not XTool.IsTableEmpty(self._ItemIds) then
        for index, id in pairs(self._ItemIds) do
            local node = self["PanelTool" .. index]

            if node then
                table.insert(self._BindNodes, node)
                XEventManager.BindEvent(node, XEventId.EVENT_ITEM_COUNT_UPDATE_PREFIX .. id, self.OnItemCountUpdate, self)
            end
        end
    end
end

function XUiBWPanelAsset:_RemoveEvent()
    if not XTool.IsTableEmpty(self._BindNodes) then
        for _, node in pairs(self._BindNodes) do
            XEventManager.UnBindEvent(node)
        end
    end

    self._BindNodes = {}
end

return XUiBWPanelAsset
