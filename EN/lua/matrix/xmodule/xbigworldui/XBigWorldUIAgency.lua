---@class XBigWorldUIAgency : XAgency
---@field private _Model XBigWorldUIModel
---@field private _QueueHelper XBigWorldQueueUiHelper
local XBigWorldUIAgency = XClass(XAgency, "XBigWorldUIAgency")

local ExitIgnoreCloseUiName = {
    ["UiDialogCanvasDialog"] = true,
    ["UiDialog"] = true,
    ["UiSuperWaterMarks"] = true,
    ["UiWaterMask"] = true,
}

local XBigWorldUi = require("XModule/XBigWorldUI/Base/XBigWorldUi")

function XBigWorldUIAgency:OnInit()
    self._FightUiCb = {}

    self._QueueHelper = require("XModule/XBigWorldUI/Base/XBigWorldQueueUiHelper").New()
    self._UiDestroyHandler = Handler(self, self.OnUiDestroy)

    -- 当前已打开的、继承自 XBigWorldUi 的面板缓存（uiName -> true）
    -- 由 XBigWorldUi:OnAwakeUi/OnDestroyUi 通过 RecordOpenedBigWorldUi/RemoveOpenedBigWorldUi 维护
    -- CloseAllBigWorldUi 遍历此集合关闭，避免遍历 C# UI 栈
    self._OpenedBigWorldUiSet = {}

    self.UiThemeModule = {
        None = 0,
        Quest = 1,
    }
end

function XBigWorldUIAgency:InitRpc()
end

function XBigWorldUIAgency:OnRelease()
    self:OnExitBigWorld()
end

function XBigWorldUIAgency:OnEnterBigWorld()
    self._QueueHelper:Init()
    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_DESTROY, self._UiDestroyHandler)
end

function XBigWorldUIAgency:OnExitBigWorld()
    self._QueueHelper:Release()
    for key, _ in pairs(self._FightUiCb) do
        self._FightUiCb[key] = nil
    end
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_DESTROY, self._UiDestroyHandler)
end

function XBigWorldUIAgency:ClearBigWorldUI()
    self:RunMain()
    local index = 0
    while true do
        local uiName = CS.XUiManager.Instance:GetTopXUiName(index)
        if string.IsNilOrEmpty(uiName) then
            break
        end
        ---@type XUiData
        local uiData = CS.XUiManager.Instance:FindUiData(uiName)
        --子界面直接通过关掉父界面处理
        if uiData and uiData.IsChildUi then
            index = index + 1
            goto continue
        end
        --这些界面不关闭 || 战斗界面不关闭，交由战斗管理
        if ExitIgnoreCloseUiName[uiName] or XUiManager.IsFightUi(uiName) then
            index = index + 1
            goto continue
        end
        self:CloseImmediately(uiName)
        ::continue::
    end
end

--- 关闭所有"通过 Open 路径打开过、且继承自 XBigWorldUi"的面板
--- 通过 _OpenedBigWorldUiSet 缓存查找，无需扫 C# UI 栈
function XBigWorldUIAgency:CloseAllBigWorldUi()
    local closeCount = 0
    -- 复制一份 key 列表，避免边遍历边删（OnUiDestroy 会回写 _OpenedBigWorldUiSet）
    local toClose = {}
    for uiName in pairs(self._OpenedBigWorldUiSet) do
        toClose[#toClose + 1] = uiName
    end
    for _, uiName in ipairs(toClose) do
        self:CloseImmediately(uiName)
        closeCount = closeCount + 1
    end
end

function XBigWorldUIAgency:IsPauseFight(uiName)
    return self._Model:IsPauseFight(uiName)
end

function XBigWorldUIAgency:IsChangeInput(uiName)
    return self._Model:IsChangeInput(uiName)
end

function XBigWorldUIAgency:IsQueueUI(uiName)
    return self._Model:IsQueue(uiName)
end

function XBigWorldUIAgency:IsHideFightUi(uiName)
    return self._Model:IsHideFightUi(uiName)
end

function XBigWorldUIAgency:IsCloseCameraControl(uiName)
    return self._Model:IsCloseCameraControl(uiName)
end

function XBigWorldUIAgency:IsVirtual(uiName)
    return self._Model:IsVirtual(uiName)
end

function XBigWorldUIAgency:IsPopupModality(uiName)
    return self._Model:IsPopupModality(uiName)
end

function XBigWorldUIAgency:IsLockOperation()
    return not XLoginManager.IsLogin() or not XMVCA.XBigWorldGamePlay:IsInGame()
end

function XBigWorldUIAgency:GetPopupPriority(uiName)
    return self._Model:GetPopupPriority(uiName)
end

function XBigWorldUIAgency:GetPopupCustomModalityParams(uiName)
    return self._Model:GetPopupCustomModalityParams(uiName)
end

function XBigWorldUIAgency:GetPopupSpecificModalityUi(UiName)
    return self._Model:GetPopupSpecificModalityUi(UiName)
end

function XBigWorldUIAgency:Open(uiName, ...)
    if not self._Model:CheckAllowOpenWithImpact(uiName) then
        return false
    end

    if self:IsQueueUI(uiName) then
        self._QueueHelper:Open(uiName, ...)
    else
        self:ImpactUiOpening(uiName)
        XLuaUiManager.Open(uiName, ...)
    end
    return true
end

--- 记录一个继承自 XBigWorldUi 的面板已打开（由 XBigWorldUi:OnAwakeUi 调用）
--- CloseAllBigWorldUi 遍历此集合关闭，避免遍历 C# UI 栈
---@param uiName string
function XBigWorldUIAgency:RecordOpenedBigWorldUi(uiName)
    if string.IsNilOrEmpty(uiName) then
        return
    end
    self._OpenedBigWorldUiSet[uiName] = true
end

--- 移除一个已打开的 XBigWorldUi 面板记录（由 XBigWorldUi:OnDestroyUi 调用）
---@param uiName string
function XBigWorldUIAgency:RemoveOpenedBigWorldUi(uiName)
    if string.IsNilOrEmpty(uiName) then
        return
    end
    self._OpenedBigWorldUiSet[uiName] = nil
end

function XBigWorldUIAgency:OpenWithFightSequence(uiName, immidiateOpen, ...)
    if not self:CheckAllowOpenWithImpact(uiName) then
        return false
    end
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_OPEN_UI_BY_SEQUENTIAL_SYSTEM, {
        Serial = XMVCA.XBigWorldCommon.ESequentialJobsSerial.Main,
        UiName = uiName,
        ImmidiateOpen = immidiateOpen or false,
        OpenArgs = { ... }
    })
    return true
end

function XBigWorldUIAgency:OpenWithCallback(uiName, callback, ...)
    self:ImpactUiOpening(uiName)
    XLuaUiManager.OpenWithCallback(uiName, callback, ...)
end

function XBigWorldUIAgency:OpenSingleUi(uiName, ...)
    if self:IsShow(uiName) then
        self:Close(uiName)
    elseif XLuaUiManager.IsUiLoad(uiName) then
        XLuaUiManager.Remove(uiName)
    end

    self:ImpactUiOpening(uiName)
    self:Open(uiName, ...)
end

function XBigWorldUIAgency:PopThenOpen(uiName, ...)
    self:ImpactUiOpening(uiName)
    XLuaUiManager.PopThenOpen(uiName, ...)
end

function XBigWorldUIAgency:CloseAllUpperUiWithCallback(uiName, cb)
    XLuaUiManager.CloseAllUpperUiWithCallback(uiName, cb)
end

--- 关闭目标 UI 上方所有层，可能带有刷新事件。
--- 若目标UI不在栈中，则直接打开
function XBigWorldUIAgency:PopToAndOpen(uiName, ...)
    if XLuaUiManager.IsStackUiOpen(uiName) then
        XLuaUiManager.CloseAllUpperUi(uiName)
    else
        self:Open(uiName, ...)
    end
end

function XBigWorldUIAgency:Close(uiName, callback)
    if self:IsLockOperation() then
        return
    end
    if callback then
        XLuaUiManager.CloseWithCallback(uiName, callback)
    else
        XLuaUiManager.Close(uiName)
    end
end

function XBigWorldUIAgency:CloseImmediately(uiName)
    CS.XUiManager.Instance:CloseImmediately(uiName)
end

function XBigWorldUIAgency:Remove(uiName)
    if self:IsLockOperation() then
        return
    end
    if XLuaUiManager.IsUiLoad(uiName) then
        XLuaUiManager.Remove(uiName)
    end
end

function XBigWorldUIAgency:SafeClose(uiName)
    if self:IsLockOperation() then
        return
    end
    XLuaUiManager.SafeClose(uiName)
end

function XBigWorldUIAgency:IsShow(uiName)
    return XLuaUiManager.IsUiShow(uiName)
end

function XBigWorldUIAgency:IsUiLoad(uiName)
    return XLuaUiManager.IsUiLoad(uiName)
end

function XBigWorldUIAgency:GetTopUiName()
    return XLuaUiManager.GetTopUiName()
end

function XBigWorldUIAgency:SetActive(uiName, isActive)
    XLuaUiManager.SetUiActive(uiName, isActive)
end

--- 注册UI
---@param super XLuaUi 为空时，默认参数为XBigWorldUI
---@return
function XBigWorldUIAgency:Register(super, uiName)
    if XMain.IsEditorDebug then
        if super and not CheckClassSuper(super, XBigWorldUi) then
            XLog.Error("父类必须继承自XBigWorldUi, UIName = " .. uiName)
            super = XBigWorldUi
        end
    end
    if not super then
        super = XBigWorldUi
    end
    return XLuaUiManager.Register(super, uiName)
end

--- 该 UI 是否继承自 XBigWorldUi
--- 通过 XLuaUiManager 的 ClassType 反查 super 链；要求该 UI 已被 require 注册过
---@param uiName string
---@return boolean
function XBigWorldUIAgency:IsBigWorldUi(uiName)
    if string.IsNilOrEmpty(uiName) then
        return false
    end
    local uiClass = XLuaUiManager.GetUiClass(uiName)
    if not uiClass then
        return false
    end
    return uiClass == XBigWorldUi or CheckClassSuper(uiClass, XBigWorldUi)
end

-- region UI效果

function XBigWorldUIAgency:GetUiImpactType(id)
    return self._Model:GetUiImpactType(id)
end

function XBigWorldUIAgency:GetUiImpactParams(id)
    return self._Model:GetUiImpactParams(id)
end

-- endregion

-- region 弹窗管理

function XBigWorldUIAgency:ChangeUiDataArgByIndex(uiName, index, value)
    self._QueueHelper:ChangeUiDataArgByIndex(uiName, index, value)
end

function XBigWorldUIAgency:InsertHeaderAwaitUi(uiName, ...)
    self._QueueHelper:InsertHeaderAwaitUi(uiName, ...)
end

function XBigWorldUIAgency:IsQueueEmpty()
    if not self._QueueHelper then
        return true
    end
    return self._QueueHelper:IsEmpty()
end

-- endregion

-- region 常用接口

function XBigWorldUIAgency:SetMaskActive(isActive, key)
    XLuaUiManager.SetMask(isActive, key)
end

function XBigWorldUIAgency:IsMaskShow(isActive, key)
    XLuaUiManager.IsMaskShow(key)
end

function XBigWorldUIAgency:TipCode(code, ...)
    XUiManager.TipCode(code, ...)
end

function XBigWorldUIAgency:TipMsg(msg, type, cb, hideCloseMark, hideUnderlineInfo)
    XUiManager.TipMsg(msg, type, cb, hideCloseMark, hideUnderlineInfo)
end

function XBigWorldUIAgency:TipText(key, args, type, cb, hideCloseMark, hideUnderlineInfo)
    local params = args and table.unpack(args) or nil
    local text = XMVCA.XBigWorldService:GetText(key, params)

    XUiManager.TipMsg(text, type, cb, hideCloseMark, hideUnderlineInfo)
end

-- endregion

-- region 通用界面

---@param data XBWPopupConfirmData
function XBigWorldUIAgency:OpenConfirmPopup(data)
    if self._Model:IsNotRepeatConfirmPopup(data.Key) then
        if data.IsNotify then
            self:SendConfirmPopupCloseCommand(data.Key, false, true, true)
        end

        data:Dispose()

        return false
    else
        self:Open("UiBigWorldPopupConfirm", data)

        return true
    end
end

function XBigWorldUIAgency:OpenConfirmPopupUiWithCmd(data)
    local confrimData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

    confrimData:InitKey(data.Key):InitInfo(data.Title, data.Tips, true)
    confrimData:InitSureClick(data.SureText, nil, not data.IsOnlyCancel)
    confrimData:InitCancelAndCloseClick(data.CancelText, nil, true)

    self:OpenConfirmPopup(confrimData)
end

---@param data XBWPopupQuitConfirmData
function XBigWorldUIAgency:OpenQuitConfirmPopup(data)
    self:Open("UiBigWorldPopupQuitShow", data)
end

function XBigWorldUIAgency:OpenQuitConfirmPopupWithCmd(data)
    local confrimData = XMVCA.XBigWorldCommon:GetPopupQuitConfirmData()

    confrimData:InitInfo(data.Title, data.Tips, true)
    confrimData:InitCancelAndCloseClick(data.CancelText)
    confrimData:InitSureClick(data.SureText)

    self:OpenQuitConfirmPopup(confrimData)
end

function XBigWorldUIAgency:OpenBigWorldObtain(rewardData, title, closeCb, disableAutoClose, isSequence)
    return self:_OpenBigWorldObtain("UiBigWorldObtain", rewardData, title, closeCb, disableAutoClose, isSequence)
end

function XBigWorldUIAgency:OpenBigWorldObtainSpecial(rewardData, title, closeCb, disableAutoClose, isSequence)
    return self:_OpenBigWorldObtain("UiBigWorldObtainSpecial", rewardData, title, closeCb, disableAutoClose, isSequence)
end

function XBigWorldUIAgency:_OpenBigWorldObtain(uiName, rewardData, title, closeCb, disableAutoClose, isSequence)
    if isSequence then
        return self:OpenWithFightSequence(uiName, false, rewardData, title, closeCb, disableAutoClose)
    end
    return self:Open(uiName, rewardData, title, closeCb, disableAutoClose)
end

function XBigWorldUIAgency:OpenBigWorldObtainWithCmd(data)
    if not data then
        return
    end
    self:OpenBigWorldObtain(data.RewardData, data.Title, data.CloseCb)
end

function XBigWorldUIAgency:OpenBigWorldRewardGoods(rewardData, title, closeCb)
    if type(rewardData) == "number" then
        local dataType = XMVCA.XBigWorldService.RewardDisplayDataType.Reward

        if XMVCA.XBigWorldService:CheckSpecialReward(rewardData, dataType) then
            self:OpenBigWorldObtainSpecial(rewardData, title, nil, nil, true)
        elseif XMVCA.XBigWorldService:CheckExpensiveReward(rewardData, dataType) then
            self:OpenBigWorldObtain(rewardData, title, nil, nil, true)
        else
            self:OpenBigWorldRewardSidebar(rewardData, closeCb, true)
        end

        return
    end

    local expensiveRewards = {}
    local specialRewards = {}
    local rewardGoodsType = XMVCA.XBigWorldService.RewardDisplayDataType.RewardGoods

    for _, reward in ipairs(rewardData) do
        if XMVCA.XBigWorldService:CheckExpensiveReward(reward.TemplateId) 
            or XMVCA.XBigWorldService:CheckExpensiveReward(reward.Id, rewardGoodsType) then
            table.insert(expensiveRewards, reward)
        elseif XMVCA.XBigWorldService:CheckSpecialReward(reward.TemplateId) 
            or XMVCA.XBigWorldService:CheckSpecialReward(reward.Id, rewardGoodsType)then
            table.insert(specialRewards, reward)
        end
    end

    local emptyExp = XTool.IsTableEmpty(expensiveRewards)
    local emptySpecial = XTool.IsTableEmpty(specialRewards)
    if emptyExp and emptySpecial then
        self:OpenBigWorldRewardSidebar(rewardData, closeCb, true)
        return
    end
    --优先弹特殊奖励
    if not emptySpecial then
        self:OpenBigWorldObtainSpecial(specialRewards, title, nil, nil, true)
    end
    --再弹珍稀奖励
    if not emptyExp then
        self:OpenBigWorldObtain(expensiveRewards, title, nil, nil, true)
    end
    self:OpenBigWorldRewardSidebar(rewardData, closeCb, true)
end

function XBigWorldUIAgency:OpenBigWorldRewardGoodsWithCmd(data)
    if not data then
        return
    end
    self:OpenBigWorldRewardGoods(data.RewardData, data.Title, data.CloseCb)
end

function XBigWorldUIAgency:OpenBigWorldRewardSidebar(rewardData, closeCb, isSequence)
    if XTool.IsTableEmpty(rewardData) then
        return
    end
    
    if isSequence then
        return self:OpenWithFightSequence("UiBigWorldRewardSidebar", false, rewardData, closeCb)
    end
    return self:Open("UiBigWorldRewardSidebar", rewardData, closeCb)
end

function XBigWorldUIAgency:OpenBigWorldRewardSidebarWithCmd(data)
    if not data then
        return
    end
    self:OpenBigWorldRewardSidebar(data.RewardData, data.CloseCb)
end

function XBigWorldUIAgency:OpenDramaSkipPopup(content)
    self:Open("UiBigWorldPopupSkipDialogue", content)
end

function XBigWorldUIAgency:OpenDramaSkipPopupWithCmd(data)
    if not data then
        return
    end

    self:OpenDramaSkipPopup(data.Content)
end

function XBigWorldUIAgency:OpenLoadingMask(loadingType, ...)
    loadingType = loadingType or XMVCA.XBigWorldLoading.LoadingType.ImageMask

    XMVCA.XBigWorldLoading:OpenLoadingByType(loadingType, ...)
end

function XBigWorldUIAgency:CloseLoadingMask(loadingType, callback)
    loadingType = loadingType or XMVCA.XBigWorldLoading.LoadingType.ImageMask

    XMVCA.XBigWorldLoading:CloseLoadingByType(loadingType, callback)
end

function XBigWorldUIAgency:OpenGoodsInfo(data, title)
    self:Open("UiBigWorldTip", data, title)
end

function XBigWorldUIAgency:OpenNarrative(id, callback)
    self:OpenWithFightSequence("UiBigWorldNarrative", false, id, callback)
end

function XBigWorldUIAgency:OpenPerspectiveUi(levelId, isShowClose, txtExplain, confirmCb)
    if not levelId or not XTool.IsNumberValid(levelId) then
        XLog.Error("XBigWorldUIAgency:OpenPerspectiveUi error: levelId is invalid")
        return
    end

    self:Open("UiBigWorldFirstPerson", levelId, isShowClose, txtExplain, confirmCb)
end

function XBigWorldUIAgency:OpenTextDialog(dialogId)
    self:Open("UiBigWorldTextDialog", dialogId)
end

-- endregion 通用界面

-- region 其他

function XBigWorldUIAgency:RecordNotRepeatConfirmPopup(key, isNotRepeat)
    if key then
        self._Model:SetIsNotRepeatConfirmPopup(key, isNotRepeat)
    end
end

function XBigWorldUIAgency:ImpactUiOpening(uiName)
    self._Model:TryAdditionImpact(uiName)
    self._Model:OnUiOpeningWithImpact(uiName)
end

function XBigWorldUIAgency:CheckAllowOpenWithImpact(uiName)
    return self._Model:CheckAllowOpenWithImpact(uiName)
end

function XBigWorldUIAgency:ChangeTheme(module, themeId)
    if not module or module <= 0 then
        return
    end
    if not themeId or themeId <= 0 then
        return
    end
    CS.XUiBigWorldTheme.ChangeTheme(module, themeId)
end

function XBigWorldUIAgency:RunMain()
    self:CloseAllUpperUiWithCallback("UiFightDLC")
end

-- endregion

--region X3C

function XBigWorldUIAgency:OnFightOpenUi(data)
    local uiName = data.UiName
    if string.IsNilOrEmpty(uiName) then
        return
    end
    local funcData = self._FightUiCb[uiName]
    local openCb = funcData and funcData.OpenCb or nil
    if openCb then
        openCb(data)
    end
end

function XBigWorldUIAgency:OnFightCloseUi(data)
    local uiName = data.UiName
    if string.IsNilOrEmpty(uiName) then
        return
    end

    local funcData = self._FightUiCb[uiName]
    local closeCb = funcData and funcData.CloseCb or nil
    if closeCb then
        closeCb(data)
    end
end

function XBigWorldUIAgency:AddFightUiCb(uiName, openCb, closeCb)
    local data = self._FightUiCb[uiName]
    if not data then
        data = {
            OpenCb = false,
            CloseCb = false,
        }
        self._FightUiCb[uiName] = data
    end
    data.OpenCb = openCb
    data.CloseCb = closeCb
end

function XBigWorldUIAgency:SendConfirmPopupCloseCommand(key, isSure, isNoLongerPopup, isBlocked)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CONFIRM_POPUP_CLOSE_NOTIFY, {
        Key = key,
        IsSure = isSure or false,
        IsNoLongerPopup = isNoLongerPopup or false,
        IsBlocked = isBlocked or false,
    })
end

function XBigWorldUIAgency:SendQuitConfirmPopupCloseCommand(isSure)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_QUIT_CONFIRM_POPUP_CLOSE_NOTIFY, {
        IsSure = isSure or false,
    })
end

function XBigWorldUIAgency:SendDramaSkipPopupCloseCommand(isSkip)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_DRAMA_SKIP_POPUP_CLOSE_NOTIFY, {
        IsSkip = isSkip or false,
    })
end

--endregion

--region Event

function XBigWorldUIAgency:OnUiDestroy(event, args)
    local uiName = self:__GetUiNameByArgs(args)

    self._Model:TryRemoveImpact(uiName)
end

--endregion

function XBigWorldUIAgency:__GetUiNameByArgs(args)
    if not args or args.Length <= 0 then
        return ""
    end

    local ui = args[0]

    if not ui or not ui.UiData then
        return ""
    end

    return ui.UiData.UiName or ""
end

return XBigWorldUIAgency
