---@class XUiTheatre6PopupSanDetail : XLuaUi San值详情弹窗
---@field _Control XTheatre6Control
---@field BtnTanchuangCloseWhite XUiComponent.XUiButton
---@field PanelSan UnityEngine.RectTransform
---@field ListBuff UnityEngine.RectTransform
---@field GridSanCard UnityEngine.RectTransform
---@field JiantouLeft UnityEngine.GameObject
---@field JiantouRight UnityEngine.GameObject
local XUiTheatre6PopupSanDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupSanDetail")
local XUiPanelTheatre6BuffDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6BuffDetail")


function XUiTheatre6PopupSanDetail:OnAwake()
    self.BtnTanchuangCloseWhite:AddEventListener(handler(self, self.Close))
    self.BtnDetail:AddEventListener(handler(self, self.OnBtnTitleInfoClick))
    self.JiantouRight:AddEventListener(handler(self, self.MoveRight))
    self.JiantouLeft:AddEventListener(handler(self, self.MoveLeft))
    self.ListBuff.onValueChanged:AddListener(handler(self, self.OnScrollValueChanged))
end

function XUiTheatre6PopupSanDetail:OnStart()
    self:InitSanBar()
    self:RefreshTitle()
    self:RefreshCardList()
end

function XUiTheatre6PopupSanDetail:OnEnable()
    self:RefreshScrollArrows()
end

---初始化San值条（详情弹窗模式）
function XUiTheatre6PopupSanDetail:InitSanBar()
    self._PanelSan = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6TopSan").New(self.UiTheatre6PanelSan, self)
    self._PanelSan:Open()
end

---刷新理智状态标题
function XUiTheatre6PopupSanDetail:RefreshTitle()
    local curSanType = self._Control:GetCurrentSanType()
    self.Buff.gameObject:SetActiveEx(curSanType == XEnumConst.Theatre6.SanType.Normal)
    self.Debuff.gameObject:SetActiveEx(curSanType ~= XEnumConst.Theatre6.SanType.Normal)
    
    self.BuffTxt.text =self._Control:GetClientConfigValue("SanTypeName", curSanType)
    self.DebuffTxt.text =self._Control:GetClientConfigValue("SanTypeName", curSanType)
end

---点击标题详情按钮，弹出理智状态说明
function XUiTheatre6PopupSanDetail:OnBtnTitleInfoClick()
    local title = self._Control:GetSanTitleText()
    local desc = XUiHelper.GetText("Theatre6SanTipDesc")
    self._Control:OpenPopupCommonWithoutButton(title, desc)
end

---刷新卡片列表
function XUiTheatre6PopupSanDetail:RefreshCardList()
    local sortedCards = self._Control:GetSortedSanCardsForDetail()
    local cardCount = #sortedCards
    if cardCount == 0 then
        return
    end

    local curConfig = self._Control:GetCurSanConfig()


    -- 锚点索引，默认取当前配置索引
    local anchorIndex = table.indexof(sortedCards, curConfig)
    if anchorIndex == 0 then
        anchorIndex = math.ceil(cardCount / 2)
    end
    local latestActiveDebuffIndex = nil

    -- 找到Normal项的索引，用于判断箭头方向
    local normalIndex = nil
    for i, cfg in ipairs(sortedCards) do
        if cfg.SanType == XEnumConst.Theatre6.SanType.Normal then
            normalIndex = i
            break
        end
    end

    self._CardGrids = {}

    XUiHelper.RefreshCustomizedList(self.GridSanCard.transform.parent, self.GridSanCard.gameObject, cardCount,
        function(i, go)
            local ui = XTool.InitUiObjectByUi({}, go)
            local sanConfig = sortedCards[i]
            local buffId = sanConfig.BuffIds[1] --todo 默认第一个
            if XTool.IsNumberValid(buffId) then
                ui.UiTheatre6BubbleBuffDetail.gameObject:SetActiveEx(true)
                ---@type XUiPanelTheatre6BuffDetail
                local buffDetail = XUiPanelTheatre6BuffDetail.New(ui.UiTheatre6BubbleBuffDetail, self)
                buffDetail:SetBuffId(buffId)
                buffDetail:IsBuffCanClick(false)
                buffDetail:SetDebuff(sanConfig.SanType ~= XEnumConst.Theatre6.SanType.Normal)
            else
                ui.UiTheatre6BubbleBuffDetail.gameObject:SetActiveEx(false)
            end
            
            local isNormal = false
            local showSanValue = 0
            if sanConfig.SanType == XEnumConst.Theatre6.SanType.Normal then
                isNormal = true
                showSanValue = 0
            elseif sanConfig.SanType == XEnumConst.Theatre6.SanType.Below then
                showSanValue = sanConfig.MaxSan
            elseif sanConfig.SanType == XEnumConst.Theatre6.SanType.Above then
                showSanValue = sanConfig.MinSan
            elseif sanConfig.SanType == XEnumConst.Theatre6.SanType.Death then
                showSanValue = sanConfig.MaxSan
            end
            ui.TagBuffDescription:SetNameByGroup(0, string.format(self._Control:GetClientConfigValue("SanTypeDesc", sanConfig.SanType), showSanValue))               -- 理智值范围显示
           
            local showLeftArrowOn = false
            local showLeftArrowOff = false
            local showRightArrowOn = false
            local showRightArrowOff = false

            local buttonStatus = XUiButtonState.Normal
            if curConfig.Id == sanConfig.Id then
                buttonStatus = isNormal and XUiButtonState.Select or XUiButtonState.Disable
            end
            ui.TagBuffDescription:SetButtonState(buttonStatus)

            if i <= normalIndex and i > 1 then
                local prevConfig = sortedCards[i - 1]
                if prevConfig.Id == curConfig.Id then
                    showLeftArrowOn = true
                else
                    showLeftArrowOff = true
                end
            end

            if i >= normalIndex and i < cardCount then
                local nextConfig = sortedCards[i + 1]
                if nextConfig.Id == curConfig.Id then
                    showRightArrowOn = true
                else
                    showRightArrowOff = true
                end
            end

            ui.JiantouLeftOn.gameObject:SetActiveEx(showLeftArrowOn)
            ui.JiantouLeftOff.gameObject:SetActiveEx(showLeftArrowOff)
            ui.JiantouRightOn.gameObject:SetActiveEx(showRightArrowOn)
            ui.JiantouRightOff.gameObject:SetActiveEx(showRightArrowOff)
        end)

    self:ScrollToAnchor(anchorIndex, latestActiveDebuffIndex, cardCount)
end

---判断某个San档位卡片是否已被"经过"（即当前San值已越过该阈值）
---@param sanConfig XTableTheatre6StageSan
---@return boolean
function XUiTheatre6PopupSanDetail:IsCardReached(sanConfig)
    local curConfig = self._Control:GetCurSanConfig()
    if not curConfig then
        return false
    end

    local curSan = self._Control:GetSanCurValue()

    if sanConfig.SanType == XEnumConst.Theatre6.SanType.Normal then
        return curConfig.SanType == XEnumConst.Theatre6.SanType.Normal
    elseif sanConfig.SanType == XEnumConst.Theatre6.SanType.Below then
        return curSan <= sanConfig.MaxSan
    elseif sanConfig.SanType == XEnumConst.Theatre6.SanType.Above then
        return curSan >= sanConfig.MinSan
    elseif sanConfig.SanType == XEnumConst.Theatre6.SanType.Death then
        if sanConfig.MinSan == 0 and sanConfig.MaxSan == 0 then
            return curSan <= 0
        else
            return curSan >= sanConfig.MaxSan
        end
    end

    return false
end

---滚动到锚点位置
function XUiTheatre6PopupSanDetail:ScrollToAnchor(activeIndex, latestDebuffIndex, totalCount)
    if not self.ListBuff or totalCount <= 1 then
        return
    end

    local targetIndex = latestDebuffIndex or activeIndex
    if not targetIndex then
        local normalIndex = math.ceil(totalCount / 2)
        targetIndex = normalIndex
    end

    local normalizedPos = (targetIndex - 1) / (totalCount - 1)
    normalizedPos = math.max(0, math.min(1, normalizedPos))

    XScheduleManager.ScheduleOnce(function()
        if self.ListBuff and not XTool.UObjIsNil(self.ListBuff) then
            self.ListBuff.horizontalNormalizedPosition = normalizedPos
            self:RefreshScrollArrows()
        end
    end, 0)
end

---刷新左右滑动指示箭头
function XUiTheatre6PopupSanDetail:RefreshScrollArrows()
  
    local pos = self.ListBuff.horizontalNormalizedPosition
    local threshold = 0.01
    self.JiantouLeft.gameObject:SetActiveEx(pos > threshold)
    self.JiantouRight.gameObject:SetActiveEx(pos < (1 - threshold))
end

function XUiTheatre6PopupSanDetail:OnScrollValueChanged()
    self:RefreshScrollArrows()
end

function XUiTheatre6PopupSanDetail:MoveRight()
    -- listbuff 向右移动
    self.ListBuff.horizontalNormalizedPosition = self.ListBuff.horizontalNormalizedPosition + 0.1
end

function XUiTheatre6PopupSanDetail:MoveLeft()
    -- listbuff 向左移动
    self.ListBuff.horizontalNormalizedPosition = self.ListBuff.horizontalNormalizedPosition - 0.1
end

return XUiTheatre6PopupSanDetail
