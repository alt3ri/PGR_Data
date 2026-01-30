---@class XUiTheatre5PVPRank: XLuaUi
---@field private _Control XTheatre5Control
---@field TagsButtonGroup XUiButtonGroup
local XUiTheatre5PVPRank = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PVPRank')
local XUiPanelTheatre5PVPRankList = require('XUi/XUiTheatre5/XUiTheatre5PVPRank/XUiPanelTheatre5PVPRankList')

function XUiTheatre5PVPRank:OnAwake()
    self.BtnBack.CallBack = handler(self, self.Close)

    if self.BtnMainUi then
        self.BtnMainUi.CallBack = XLuaUiManager.RunMain
    end
end

function XUiTheatre5PVPRank:OnStart(data)
    ---@type XUiPanelTheatre5PVPRankList
    self.PanelRankList = XUiPanelTheatre5PVPRankList.New(self.PanelRank, self)

    self.PanelRankList:RefreshShow(data)
    
    self.TxtTime.text = self._Control:GetClientConfigRankRefreshTips()
    
    self:InitTabs()
end

function XUiTheatre5PVPRank:InitTabs()
    ---@type XTableTheatre5Character[]
    local cfgs = self._Control:GetTheatre5CharacterCfgs()
    
    self.TabList = {
        [1] = 0
    }

    if not XTool.IsTableEmpty(cfgs) then
        for i, v in pairs(cfgs) do
            table.insert(self.TabList, v.Id)
        end
    end
    
    local btnGroup = {}
    
    XUiHelper.RefreshCustomizedList(self.TagsButtonGroup.transform, self.GridRankLevel, #self.TabList, function(index, go)
        local btn = go:GetComponent(typeof(CS.XUiComponent.XUiButton))

        if btn then
            if XTool.IsNumberValid(self.TabList[index]) then
                local cfg = cfgs[self.TabList[index]]

                if cfg then
                    btn:SetNameByGroup(0, cfg.Name)
                end
            else
                btn:SetNameByGroup(0, self._Control:GetClientConfigRankAllTabLabel())
            end

            table.insert(btnGroup, btn)
        end
    end)
    
    self.TagsButtonGroup:Init(btnGroup, handler(self, self.OnTabSelectEvent), 1)
    self.TagsButtonGroup:SelectIndex(1, false)
    self._CurSelectIndex = 1
end

function XUiTheatre5PVPRank:OnTabSelectEvent(index, force)
    if self._CurSelectIndex == index and not force then
        return
    end
    
    self._CurSelectIndex = index
    
    XMVCA.XTheatre5.PVPCom:RequestTheatre5QueryRank(self.TabList[index], function(success, data)
        if success then
            self.PanelRankList:RefreshShow(data, self.TabList[index])
        end
    end)
end

return XUiTheatre5PVPRank