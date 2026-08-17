---@class XUiPBRCommonItemDetailTag : XUiNode
---@field TxtTitle UnityEngine.UI.Text 标签文字
---@field TagNone UnityEngine.UI.Text 无标签时占位文字（商店固定槽使用，DetailPopup 无此节点）
local XUiPBRCommonItemDetailTag = XClass(XUiNode, "XUiPBRCommonItemDetailTag")

function XUiPBRCommonItemDetailTag:InitComponents()
end

function XUiPBRCommonItemDetailTag:OnStart(...)
    self:InitComponents()
end

function XUiPBRCommonItemDetailTag:OnEnable()
end

function XUiPBRCommonItemDetailTag:OnDisable()
end

function XUiPBRCommonItemDetailTag:OnDestroy()
end

--- tagStr 为 nil 时显示 TagNone（空槽），否则显示 TxtTitle
---@param tagStr string|nil
function XUiPBRCommonItemDetailTag:SetTagShow(tagStr)
    local hasTag = tagStr ~= nil and tagStr ~= ""
    if self.TxtTitle then
        self.TxtTitle.gameObject:SetActiveEx(hasTag)
        if hasTag then self.TxtTitle.text = tagStr end
    end
    if self.TagNone then
        self.TagNone.gameObject:SetActiveEx(not hasTag)
    end
end

return XUiPBRCommonItemDetailTag
