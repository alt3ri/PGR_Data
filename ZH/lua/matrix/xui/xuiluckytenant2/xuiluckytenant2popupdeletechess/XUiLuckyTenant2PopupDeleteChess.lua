--[[
-- XUiLuckyTenant2PopupDeleteChess.lua
-- 删除棋子确认弹窗：展示待删棋子，确认后消耗删除道具并删除
--]]

local XUiLuckyTenant2GameGridChess = require("XUi/XUiLuckyTenant2/XUiLuckyTenant2Game/XUiLuckyTenant2GameGridChess")

---@class XUiLuckyTenant2PopupDeleteChess : XLuaUi
---@field _Control XLuckyTenant2Control
---@field _PieceData table 待删除的棋子数据（SelectedBagPiece）
---@field _GridChess XUiLuckyTenant2GameGridChess
local XUiLuckyTenant2PopupDeleteChess = XLuaUiManager.Register(XLuaUi, "UiLuckyTenant2PopupDeleteChess")

function XUiLuckyTenant2PopupDeleteChess:OnAwake()
    self:InitComponents()
end

function XUiLuckyTenant2PopupDeleteChess:InitComponents()
    self.BtnTanchuangCloseBig:AddEventListener(function() self:OnBtnTanchuangCloseBigClick() end)
    self.BtnCancel:AddEventListener(function() self:OnBtnCancelClick() end)
    self.BtnDelete:AddEventListener(function() self:OnBtnDeleteClick() end)

    -- 复用游戏界面的 GridChess 节点展示待删棋子（需在 prefab 中绑定 GridChess 节点）
    if self.GridChess then
        self._GridChess = XUiLuckyTenant2GameGridChess.New(self.GridChess, self)
    end

    self.ImgIcon = self.ImgIcon or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelBond/PanelDoc/ImgIcon/ImgIcon", "RawImage")
end

---@param pieceData table 待删除的棋子数据（与 SelectedBagPiece 结构一致）
---@param control XLuckyTenant2Control 选棋/背包界面传入的 Control
function XUiLuckyTenant2PopupDeleteChess:OnStart(pieceData, control)
    self._PieceData = pieceData
    self._Control = control
    self:Update()
end

function XUiLuckyTenant2PopupDeleteChess:OnEnable()
end

function XUiLuckyTenant2PopupDeleteChess:OnDisable()
end

function XUiLuckyTenant2PopupDeleteChess:OnDestroy()
end

function XUiLuckyTenant2PopupDeleteChess:Update()
    if not self._PieceData then
        return
    end
    -- if self.TxtTitle then
    --     self.TxtTitle.text = XUiHelper.GetText("LuckyTenant2DeleteChessTitle") or "删除棋子"
    -- end
    -- if self.TxtDoc then
    --     self.TxtDoc.text = XUiHelper.GetText("LuckyTenant2DeleteChessDesc") or "确定消耗删除道具删除该棋子？"
    -- end

    -- 羁绊描述：有则显示文本并显示父节点，无则隐藏父节点（与 ChessDetail TxtBonds 逻辑一致）
    if self.TxtDoc then
        local data = self._PieceData
        local bondsText = data and data.BondsText or nil
        if (bondsText == "" or not bondsText) and self._Control.GetPieceBondsTextByData then
            bondsText = self._Control:GetPieceBondsTextByData(data)
        end
        if string.IsNilOrEmpty(bondsText) then
            if self.PanelBond then
                self.PanelBond.gameObject:SetActiveEx(false)
            end
        else
            self.TxtDoc.text = bondsText or ""
            if self.PanelBond then
                self.PanelBond.gameObject:SetActiveEx(true)
            end
        end
    end

    if self.BtnTanchuangCloseBig then
        self.BtnTanchuangCloseBig:SetButtonState(CS.UiButtonState.Normal)
    end
    if self.BtnCancel then
        self.BtnCancel:SetButtonState(CS.UiButtonState.Normal)
    end
    if self.BtnDelete then
        self.BtnDelete:SetButtonState(CS.UiButtonState.Normal)
    end
    -- 用 GridChess 展示待删棋子
    if self._GridChess and self._PieceData then
        self._GridChess:Update(self._PieceData)
    end

    if self.ImgIcon then
        local pieceId = self._PieceData and self._PieceData.Id or 0
        local bondIcon = self._Control:GetBondIcon(pieceId) or ""
        if bondIcon and not string.IsNilOrEmpty(bondIcon) then
            self.ImgIcon:SetImage(bondIcon or "")
            self.ImgIcon.gameObject:SetActiveEx(true)
        else
            self.ImgIcon.gameObject:SetActiveEx(false)
        end
    end
end

function XUiLuckyTenant2PopupDeleteChess:OnBtnTanchuangCloseBigClick()
    self:Close()
end

function XUiLuckyTenant2PopupDeleteChess:OnBtnCancelClick()
    self:Close()
end

function XUiLuckyTenant2PopupDeleteChess:OnBtnDeleteClick()
    if not self._Control or not self._PieceData or not self._PieceData.Uid then
        self:Close()
        return
    end
    if self._Control:ConfirmDeletePieceWithProp(self._PieceData.Uid) then
        self:Close()
        XEventManager.DispatchEvent(XEventId.EVENT_LUCKY_TENANT2_DELETE_CHESS_POPUP_CLOSE)
    else
        self:Close()
    end
end

return XUiLuckyTenant2PopupDeleteChess
