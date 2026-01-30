
---@class XUiBigWorldProcessCoreTipGrid : XUiNode
---@field TxtName UnityEngine.UI.Text
---@field TxtDesc UnityEngine.UI.Text
---@field PanelComplete UnityEngine.RectTransform
---@field Parent XUiBigWorldProcessCoreTip
local XUiBigWorldProcessCoreTipGrid = XClass(XUiNode, "XUiBigWorldProcessCoreTipGrid")

function XUiBigWorldProcessCoreTipGrid:OnStart()
    self:_RegisterButtonClicks()
end

function XUiBigWorldProcessCoreTipGrid:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldProcessCoreTipGrid:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcessCoreTipGrid:OnDestroy()
end

function XUiBigWorldProcessCoreTipGrid:Refresh(tip, progress, isComplete)
    self.TxtName.text = tip
    self.TxtDesc.text = progress
    if self.PanelComplete then
        self.PanelComplete.gameObject:SetActiveEx(isComplete or false)
    end
end

function XUiBigWorldProcessCoreTipGrid:_RegisterButtonClicks()
    --在此处注册按钮事件
end

function XUiBigWorldProcessCoreTipGrid:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldProcessCoreTipGrid:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldProcessCoreTipGrid:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldProcessCoreTipGrid:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldProcessCoreTipGrid:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

return XUiBigWorldProcessCoreTipGrid
