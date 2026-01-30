local XUiGridRelinkSettlementChar = require("XUi/XUiDlcRelink/Settlement/XUiGridRelinkSettlementChar")
---@class XUiRelinkSettlement : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiRelinkSettlement = XLuaUiManager.Register(XLuaUi, "UiRelinkSettlement")

function XUiRelinkSettlement:OnAwake()
    self.GridMulitiplayerRoomChar.gameObject:SetActiveEx(false)
    ---@type XUiGridRelinkSettlementChar[]
    self.GridMultiPlayerChar = {}
    self:RegisterUiEvents()
end

---@param resultData XDlcFightResultData
function XUiRelinkSettlement:OnStart(resultData)
    self.ResultData = resultData
    ---@type XWorldData
    self.WorldData = resultData.WorldData
    self:InitScene()
end

function XUiRelinkSettlement:OnEnable()
    self:RefreshInfo()
end

function XUiRelinkSettlement:InitScene()
    local worldId = self.WorldData.WorldId
    local levelId = self.WorldData.LevelId
    local sceneUrl = self._Control:GetCurrentWorldScene(worldId, levelId)
    local modelUrl = self._Control:GetCurrentWorldSceneModel(worldId, levelId)
    local loadingType = self._Control:GetCurrentMaskLoadingType(worldId, levelId)

    XLuaUiManager.Open("UiLoading", loadingType)
    self:LoadUiSceneAsync(sceneUrl, modelUrl, function()
        if not self._Control then
            XLuaUiManager.SafeClose("UiLoading")
            return
        end
        self:InitModelRoot()
        --self:InitCharacterGrid()
        XLuaUiManager.Close("UiLoading")
    end)
end

function XUiRelinkSettlement:InitModelRoot()
    local root = self.UiModelGo.transform
    self.MainModelRoot = root:FindTransform("PanelRoleModel")
    self.MainModelRoot.gameObject:SetActiveEx(true)
end

function XUiRelinkSettlement:InitCharacterGrid()
    local root = self.MainModelRoot or self.UiModelGo.transform
    ---@type XWorldPlayerData[]
    local players = self.WorldData.Players
    for _, player in pairs(players) do
        local index = player.CurNpcPos
        local case = root:FindTransform(string.format("Role%d", index))
        local grid = self.GridMultiPlayerChar[index]
        if not grid then
            local roomCase = self[string.format("RoomCharCase%d", index)]
            local go = XUiHelper.Instantiate(self.GridMulitiplayerRoomChar, roomCase)
            grid = XUiGridRelinkSettlementChar.New(go, self, case)
            self.GridMultiPlayerChar[index] = grid
        end
        grid.Transform:Reset()
        grid:Open()
        grid:Refresh(player)
    end
end

function XUiRelinkSettlement:RefreshInfo()
    self.TxtWin.gameObject:SetActive(self.ResultData.IsPlayerWin)
    self.TxtLost.gameObject:SetActive(not self.ResultData.IsPlayerWin)
    self.TxtTime.text = XUiHelper.GetTime(self.ResultData.FinishTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
end

function XUiRelinkSettlement:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnTongBlack, self.OnBtnTongBlackClick)
end

function XUiRelinkSettlement:OnBtnTongBlackClick()
    self:Close()
end

return XUiRelinkSettlement
