--[[
-- XUiLuckyTenant2ChessBag.lua
-- 背包界面（和 XUiLuckyTenant2Chess 共用一个 UI）
--]]

local XUiLuckyTenant2ChessBagGroup = require("XUi/XUiLuckyTenant2/XUiLuckyTenant2Chess/XUiLuckyTenant2ChessBagGroup")
local XUiLuckyTenant2GameUiLuckyTenant2ChessDetail = require("XUi/XUiLuckyTenant2/XUiLuckyTenant2Game/XUiLuckyTenant2GameUiLuckyTenant2ChessDetail")
local XUiLuckyTenant2GameUiLuckyTenant2Bonds = require("XUi/XUiLuckyTenant2/XUiLuckyTenant2Game/XUiLuckyTenant2GameUiLuckyTenant2Bonds")
local XUiLuckyTenant2PropDisplay = require("XUi/XUiLuckyTenant2/XUiLuckyTenant2PropDisplay")
local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")

---注意事项： 这个界面和XUiLuckyTenant2Chess是共用一个ui的
---@class XUiLuckyTenant2ChessBag : XLuaUi
---@field _Control XLuckyTenant2Control
---@field _Grids XUiLuckyTenant2ChessBagGroup[]
---@field _PropGrids table 道具数量列表（刷新/删除道具，由 XUiLuckyTenant2PropDisplay 填充）
---@field _Detail XUiLuckyTenant2GameUiLuckyTenant2ChessDetail
---@field _Bonds XUiLuckyTenant2GameUiLuckyTenant2Bonds
local XUiLuckyTenant2ChessBag = XLuaUiManager.Register(XLuaUi, "UiLuckyTenant2ChessBag")

function XUiLuckyTenant2ChessBag:Ctor()
end

function XUiLuckyTenant2ChessBag:OnAwake()
    self._Grids = {}
    -- 道具数量列表（刷新/删除道具，与 XUiLuckyTenant2Chess 一致，Prop1 为模板用于克隆）
    self._PropGrids = {}
    if self.Prop1 then
        self.Prop1.gameObject:SetActiveEx(false)
    end
    -- 显示背包面板，隐藏选棋面板
    if self.SelectPiecePanel then
        self.SelectPiecePanel.gameObject:SetActiveEx(false)
    end
    if self.BagPanel then
        self.BagPanel.gameObject:SetActiveEx(true)
    end
    -- 初始化TopControlWhite
    self.TopControlWhite = self.TopControlWhite or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/BagPanel/TopControlWhite", "RectTransform")
    if self.TopControlWhite then
        self.TopControlWhite.gameObject:SetActiveEx(true)
    end
    if self.BtnGroup then
        self.BtnGroup.gameObject:SetActiveEx(false)
    end
    if self.PanelDelete then
        self.PanelDelete.gameObject:SetActiveEx(true)
    end
    
    self:BindExitBtns()
    
    -- 显示返回按钮
    if self.BtnBack then
        self.BtnBack.gameObject:SetActiveEx(true)
    end
    if self.BtnTanchuangCloseBig then
        self.BtnTanchuangCloseBig.gameObject:SetActiveEx(true)
    end
    if self.BtnTanchuangClose then
        self.BtnTanchuangClose.gameObject:SetActiveEx(true)
    end
    
    -- 初始化详情组件
    ---@type XUiLuckyTenant2GameUiLuckyTenant2ChessDetail
    if self.GirdLuckyLandlordChessDetail then
        self._Detail = XUiLuckyTenant2GameUiLuckyTenant2ChessDetail.New(self.GirdLuckyLandlordChessDetail, self)
        -- 设置背包 UI 引用，标识此 Detail 来自背包界面
        if self._Detail.SetBagUI then
            self._Detail:SetBagUI(self)
        end
    end
    
    -- 注册删除按钮事件
    if self.BtnDeleteNoFree then
        XUiHelper.RegisterClickEvent(self, self.BtnDeleteNoFree, self._OnClickDelete, nil, true)
        
        -- 设置删除按钮文本
        self.BtnDeleteNoFree:SetNameByGroup(0, XLuckyTenant2Enum.Cost)
        self.BtnDeleteNoFree.gameObject:SetActiveEx(true)
    end
    if self.BtnDeleteFree then
        self.BtnDeleteFree.gameObject:SetActiveEx(false)
    end
    
    -- 设置删除道具图标
    if self.BtnDeleteNoFree then
        local XUiButton = require("XUi/XUiCommon/XUiButton")
        ---@type XUiButtonLua
        local button = XUiButton.New(self.BtnDeleteNoFree)
        local deletePropIcon = self._Control:GetDeletePropIcon()
        if deletePropIcon then
            button:SetRawImage("ImgNoFreeIcon02", deletePropIcon)
        end
        self._LuaButtonDeleteNoFree = button
    end
    if self.BtnRefreshNoFree then
        local XUiButton = require("XUi/XUiCommon/XUiButton")
        ---@type XUiButtonLua
        local button = XUiButton.New(self.BtnRefreshNoFree)
        self._LuaButtonRefresh = button
    end
    
    -- 初始化奖励提示
    if self.RewardTips then
        self.RewardTips.gameObject:SetActiveEx(false)
    end
    if self.BtnTanchuangCloseBig then
        XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.CloseRewardTips, nil, true)
    end
    
    -- 初始化羁绊组件（使用Game版本的UI）
    if self.UiLuckyTenant2Bonds then
        ---@type XUiLuckyTenant2GameUiLuckyTenant2Bonds
        self._Bonds = XUiLuckyTenant2GameUiLuckyTenant2Bonds.New(self.UiLuckyTenant2Bonds, self)
    end
end

function XUiLuckyTenant2ChessBag:OnStart(hideDelete)
    if hideDelete then
        if self.BtnDeleteNoFree then
            self.BtnDeleteNoFree.gameObject:SetActiveEx(false)
        end
        if self.BtnDeleteFree then
            self.BtnDeleteFree.gameObject:SetActiveEx(false)
        end
    end
end

function XUiLuckyTenant2ChessBag:OnEnable()
    self._Control:SelectBagPiece(false)
    self:UpdateBag()
    self:StartListen()
end

function XUiLuckyTenant2ChessBag:StartListen()
    XEventManager.AddEventListener(XEventId.EVENT_LUCKY_TENANT2_DELETE_CHESS_POPUP_CLOSE, self.OnDeleteChessPopupClose, self)
end

function XUiLuckyTenant2ChessBag:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_LUCKY_TENANT2_DELETE_CHESS_POPUP_CLOSE, self.OnDeleteChessPopupClose, self)
end

---删除棋子弹窗关闭后刷新背包界面
function XUiLuckyTenant2ChessBag:OnDeleteChessPopupClose()
    if not self._Control then
        return
    end
    self._Control:UpdateBag()
    self:UpdateBag()
end

function XUiLuckyTenant2ChessBag:UpdatePiecesAmount()
    local data = self._Control:GetUiData()
    local amount = data.PiecesAmount or 0
    if self.TxtBagNumber then
        self.TxtBagNumber.text = tostring(amount)
    end
end

function XUiLuckyTenant2ChessBag:UpdateBag()
    self:UpdatePiecesAmount()
    self:UpdateProp()

    -- 标记为脏，确保更新
    self._Control._UiData.IsBagDirty = true
    self._Control:UpdateBag()
    
    local uiData = self._Control:GetUiData()
    local bagData = uiData.Bag
    
    if self.PanelProp then
        XTool.UpdateDynamicItem(self._Grids, bagData, self.PanelProp, XUiLuckyTenant2ChessBagGroup, self)
    end

    -- 更新右侧详情面板
    if uiData.SelectedBagPiece then
        if self.PanelNotSelected then
            self.PanelNotSelected.gameObject:SetActiveEx(false)
        end
        if self._Detail then
            self._Detail:Open()
            self._Detail:Update(uiData.SelectedBagPiece)
        end
    else
        if self.PanelNotSelected then
            self.PanelNotSelected.gameObject:SetActiveEx(true)
        end
        if self._Detail then
            self._Detail:Close()
        end
    end
    
    -- 更新羁绊显示
    self:UpdateBonds()
end

---更新道具显示（刷新/删除道具在背包中的数量，调用公共 XUiLuckyTenant2PropDisplay）
function XUiLuckyTenant2ChessBag:UpdateProp()
    if self.Prop1 and self._PropGrids then
        XUiLuckyTenant2PropDisplay.UpdatePropDisplay(self._Control, self._PropGrids, self.Prop1, self)
    end

    -- 设置删除按钮文本颜色
    local coinAmount = self._Control:GetDeleteCoin()
    if self._LuaButtonDeleteNoFree then
        if coinAmount > XLuckyTenant2Enum.Cost then
            self._LuaButtonDeleteNoFree:SetTextColor("TxtNoFree", XUiHelper.Hexcolor2Color("FFFFFF"))
        else
            self._LuaButtonDeleteNoFree:SetTextColor("TxtNoFree", XUiHelper.Hexcolor2Color("24002c"))
        end
    end

    -- 刷新按钮文本颜色
    local coinAmount = self._Control:GetRefreshCoin()
    if self._LuaButtonRefresh then
        if coinAmount > XLuckyTenant2Enum.Cost then
            self._LuaButtonRefresh:SetTextColor("TxtNoFree", XUiHelper.Hexcolor2Color("FFFFFF"))
        else
            self._LuaButtonRefresh:SetTextColor("TxtNoFree", XUiHelper.Hexcolor2Color("24002c"))
        end
    end
end

---更新羁绊显示（由 Bonds 内部统一从 Control 拉取数据）
function XUiLuckyTenant2ChessBag:UpdateBonds()
    if not self._Bonds then
        return
    end
    self._Bonds:Update()
end

function XUiLuckyTenant2ChessBag:_OnClickDelete()
    if XMVCA.XLuckyTenant2:IsRequesting() then
        return
    end
    local uiData = self._Control:GetUiData()
    if uiData.SelectedBagPiece then
        if uiData.SelectedBagPiece.IsCanDelete == 0 then
            XUiManager.TipText("LuckyTenantDeleteDenied")
            return
        end
        if self._Control:HasEnoughPropToDelete() then
            XLuaUiManager.Open("UiLuckyTenant2PopupDeleteChess", uiData.SelectedBagPiece, self._Control)
        else
            XUiManager.TipText("LuckyTenantPropNotEnough")
        end
    end
end

---@param data table 奖励数据
---@param worldPosition UnityEngine.Vector3 世界位置
function XUiLuckyTenant2ChessBag:OpenRewardTips(data, worldPosition)
    if self.RewardTips then
        self.RewardTips.gameObject:SetActiveEx(true)
    end
    if self.TxtRewardTips and data then
        self.TxtRewardTips.text = data.Desc or ""
    end
    if worldPosition and self.TxtRewardTips then
        ---@type UnityEngine.RectTransform
        local transform = self.TxtRewardTips.transform.parent
        if transform then
            transform.anchorMin = Vector2(1, 1)
            transform.anchorMax = Vector2(1, 1)
            transform.pivot = Vector2(1, 1)
            transform.position = worldPosition
        end
    end
end

function XUiLuckyTenant2ChessBag:CloseRewardTips()
    if self.RewardTips then
        self.RewardTips.gameObject:SetActiveEx(false)
    end
end


return XUiLuckyTenant2ChessBag

