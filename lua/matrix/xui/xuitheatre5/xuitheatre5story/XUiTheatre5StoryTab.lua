---@class XUiTheatre5StoryTab : XUiNode
---@field _Control XTheatre5Control
local XUiTheatre5StoryTab = XClass(XUiNode, "XUiTheatre5StoryTab")

function XUiTheatre5StoryTab:OnStart()
    self._IsOpen = false
end

---@param config XTable.XTableTheatre5StoryGroup
function XUiTheatre5StoryTab:Update(config)
    self._Config = config
    self.RImgHeadIcon:SetRawImage(config.Icon)

    -- 解锁
    if config.IsOpen then
        local condition = config.Condition
        if condition > 0 then
            local isUnlock = XConditionManager.CheckCondition(condition)
            if isUnlock then
                self._IsOpen = true
                self.PanelLock.gameObject:SetActiveEx(false)
            else
                self._IsOpen = false
                self.PanelLock.gameObject:SetActiveEx(true)
            end
        else
            self._IsOpen = true
            self.PanelLock.gameObject:SetActiveEx(false)
        end
    else
        self._IsOpen = false
        self.PanelLock.gameObject:SetActiveEx(true)
    end
end

function XUiTheatre5StoryTab:IsOpen()
    return self._IsOpen
end

function XUiTheatre5StoryTab:TipLockMsg()
    local condition = self._Config.Condition
    local desc = XConditionManager.GetConditionDescById(condition)
    XUiManager.TipMsg(desc)
end

return XUiTheatre5StoryTab