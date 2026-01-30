---@class XUiTheatre5PVEGame: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5PVEGame = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PVEGame')
local XUiPanelTheatre5PVEGame = require('XUi/XUiTheatre5/XUiTheatre5PVEGame/XUiPanelTheatre5PVEGame')

function XUiTheatre5PVEGame:OnStart(chapterData, chapterBattlePromoteCb)
    self._ChapterData = chapterData
    self._ChapterBattlePromoteCb = chapterBattlePromoteCb
    
    local path = self._Control:GetUiPrefabPathByType(XMVCA.XTheatre5.EnumConst.UITypeInStyles.UiBattleEventSelection)
    local go = self.PanelRoot:LoadPrefab(path)

    self._CurPrefabPath = path
    ---@type XUiPanelTheatre5PVEGame
    self._PanelPVEGame = XUiPanelTheatre5PVEGame.New(go, self, chapterData, chapterBattlePromoteCb)
    self._PanelPVEGame:Open()

    self._StartRun = true
end

function XUiTheatre5PVEGame:OnEnable()
    if self._StartRun then
        self._StartRun = false
    else
        local path = self._Control:GetUiPrefabPathByType(XMVCA.XTheatre5.EnumConst.UITypeInStyles.UiBattleEventSelection)

        if path ~= self._CurPrefabPath then
            self:ReInitPanel(path)
        end
    end
end

function XUiTheatre5PVEGame:ReInitPanel(path)
    if self._PanelPVEGame then
        self:RemoveChildNode(self._PanelPVEGame)
        self._PanelPVEGame:Release()
        self._PanelPVEGame = nil
    end

    self._CurPrefabPath = path

    local go = self.PanelRoot:LoadPrefab(path)

    self._PanelPVEGame = XUiPanelTheatre5PVEGame.New(go, self, self._ChapterData, self._ChapterBattlePromoteCb)
    self._PanelPVEGame:Open()
end

return XUiTheatre5PVEGame