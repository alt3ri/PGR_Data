local XUiLineArithmetic2GameStarGrid = require("XUi/XUiLineArithmetic2/XUiLineArithmetic2GameStarGrid")

---@class XUiLineArithmetic2PopupSettlement : XLuaUi
---@field _Control XLineArithmetic2Control
local XUiLineArithmetic2PopupSettlement = XLuaUiManager.Register(XLuaUi, "UiLineArithmetic2PopupSettlement")

function XUiLineArithmetic2PopupSettlement:Ctor()
    ---@type XUiLineArithmetic2GameStarGrid[]
    self._StarGrids = {}
end

function XUiLineArithmetic2PopupSettlement:OnAwake()
    self.GridTarget.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnClickClose)
    XUiHelper.RegisterClickEvent(self, self.BtnNext, self.OnClickNext)
    XUiHelper.RegisterClickEvent(self, self.BtnAgain, self.OnClickAgain)
end

function XUiLineArithmetic2PopupSettlement:OnStart()
    self:UpdateStarTarget()
    self:UpdateDesc()
end

function XUiLineArithmetic2PopupSettlement:UpdateStarTarget()
    self._Control:UpdateStarTarget()

    local uiData = self._Control:GetUiData()
    local stars = uiData.StarDescData

    for i = 1, #stars do
        local starDesc = stars[i]
        local uiGrid = self._StarGrids[i]
        if not uiGrid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridTarget, self.GridTarget.parent)
            uiGrid = XUiLineArithmetic2GameStarGrid.New(ui, self)
            self._StarGrids[i] = uiGrid
        end
        uiGrid:Open()
        uiGrid:Update(starDesc)
    end
    for i = #stars + 1, #self._StarGrids do
        local uiGrid = self._StarGrids[i]
        uiGrid:Close()
    end
end

function XUiLineArithmetic2PopupSettlement:OnClickAgain()
    self._Control:StartGame()
    XEventManager.DispatchEvent(XEventId.EVENT_LINE_ARITHMETIC_UPDATE_GAME)
    self:Close()
end

function XUiLineArithmetic2PopupSettlement:OnClickNext()
    self._Control:ChallengeNextStage()
end

function XUiLineArithmetic2PopupSettlement:OnClickClose()
    self:Close()
    XLuaUiManager.Close("UiLineArithmetic2Game")
end

function XUiLineArithmetic2PopupSettlement:UpdateDesc()
    self._Control:UpdateSettleDesc()
    local uiData = self._Control:GetUiData()
    if self.RImgCharacter then
        self.RImgCharacter:SetRawImage(uiData.Settle.RoleIcon)
    end
    if self.TxtSpeak then
        self.TxtSpeak.text = uiData.Settle.Tip
    end
end

return XUiLineArithmetic2PopupSettlement