---@class XUiTheatre5Main: XLuaUi
---@field private _Control XTheatre5Control
---@field PanelRoot UnityEngine.RectTransform
local XUiTheatre5Main = XLuaUiManager.Register(XLuaUi, 'UiTheatre5Main')
local XUiPanelTheatre5Main = require('XUi/XUiTheatre5/XUiTheatre5Main/XUiPanelTheatre5Main')

function XUiTheatre5Main:OnStart()
    local path = self._Control:GetUiPrefabPathByType(XMVCA.XTheatre5.EnumConst.UITypeInStyles.UiMain)
    local go = self.PanelRoot:LoadPrefab(path)
    
    self._CurPrefabPath = path
    ---@type XUiPanelTheatre5Main
    self.PanelMain = XUiPanelTheatre5Main.New(go, self)
    self.PanelMain:Open()

    self._StartRun = true
end

function XUiTheatre5Main:OnEnable()
    if self._StartRun then
        self._StartRun = false
    else
        local path = self._Control:GetUiPrefabPathByType(XMVCA.XTheatre5.EnumConst.UITypeInStyles.UiMain)

        if path ~= self._CurPrefabPath then
            self:ReInitPanel(path)
        end
    end    
end

function XUiTheatre5Main:ReInitPanel(path)
    if self.PanelMain then
        self:RemoveChildNode(self.PanelMain)
        self.PanelMain:Release()
        self.PanelMain = nil
    end

    self._CurPrefabPath = path

    local go = self.PanelRoot:LoadPrefab(path)

    self.PanelMain = XUiPanelTheatre5Main.New(go, self)
    self.PanelMain:Open()
end

return XUiTheatre5Main