--- pve剧情节点确认回溯界面
---@class XUiTheatre5PopupBacktrack: XLuaUi
---@field _Control XTheatre5Control
local XUiTheatre5PopupBacktrack = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PopupBacktrack')

function XUiTheatre5PopupBacktrack:OnAwake()
    self.BtnSure:AddEventListener(handler(self, self.OnSubmit))
end

function XUiTheatre5PopupBacktrack:OnStart(cfg)
    ---@type XTableTheatre5PveStoryLineContent
    self.Cfg = cfg

    if not self.Cfg then
        XLog.Error('没有有效的节点配置')
        self:Close()
        return
    end
    
    self:InitShow()
end

function XUiTheatre5PopupBacktrack:InitShow()
    self.TxtDescription.text = self.Cfg.CharacterStoryDesc
end

function XUiTheatre5PopupBacktrack:OnSubmit()
    -- 这里是特殊处理的，下一个节点必须是“选择分支界面”这种打开界面的节点。如果是其他类型的节点，这里会有问题。
    -- 目前客户端不知道下一个节点是什么，下一个节点的Id依靠故事线推进后服务端下发
    XMVCA.XTheatre5.PVEAgency:RequestPveStoryLinePromote(self.Cfg.StoryLineId, self.Cfg.Id, function()
        self:PlayAnimationWithMask('AnimDisable', function()
            self._Control.FlowControl:EnterStroryLineContent(self.Cfg.StoryLineId)
            -- 等下一个界面完全打开后，直接移除当前界面，之所以要这么处理，是为了实现界面无缝切换，不要露出底下的角色选择界面
            self:Tween(0.5, nil, function()
                XLuaUiManager.Remove('UiTheatre5PopupBacktrack')
            end)
        end)
    end)
end

return XUiTheatre5PopupBacktrack