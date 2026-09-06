-- 意识一键养成超频进度面板
---@class XUiPanelAwarenessEnhanceProgressOverclocking : XUiNode
---@field Parent XUiEquipAwarenessEnhanceProgressPopup 所属进度弹窗
---@field _Control XEquipControl 装备控制器
---@field PanelTitle UiObject
---@field BgItemWaiting UnityEngine.RectTransform
---@field BgItemProcessing UnityEngine.RectTransform
---@field BgItemDone UnityEngine.RectTransform
---@field UiTxtUnitName UnityEngine.UI.Text
---@field UiTxtPreview UnityEngine.UI.Text
---@field PanelStatusWaiting UnityEngine.RectTransform
---@field PanelStatusProcessing UnityEngine.RectTransform
---@field PanelStatusDone UnityEngine.RectTransform
---@field UiTxtWaiting UnityEngine.UI.Text
---@field IconProcessing UnityEngine.RectTransform
---@field UiTxtProcessing UnityEngine.UI.Text
---@field IconDone UnityEngine.RectTransform
---@field UiTxtDone UnityEngine.UI.Text
---@field ImgStar1 UnityEngine.UI.Image
---@field ImgOnStar1 UnityEngine.UI.Image
---@field ImgStar2 UnityEngine.UI.Image
---@field ImgOnStar2 UnityEngine.UI.Image
---@field ImgStar3 UnityEngine.UI.Image
---@field ImgOnStar3 UnityEngine.UI.Image
---@field ImgStar4 UnityEngine.UI.Image
---@field ImgOnStar4 UnityEngine.UI.Image
---@field PanelStarGoup UnityEngine.RectTransform
---@field TitleGrid XUiGridEnhanceProgressUnit 进度标题组件
---@field ExecuteCallbacks { onSuccess: fun(), onFail: fun(errorCode: number) }|nil 当前执行回调，取消或消费后清空
local XUiPanelAwarenessEnhanceProgressOverclocking = XClass(XUiNode, "XUiPanelAwarenessEnhanceProgressOverclocking")
local XUiGridEnhanceProgressUnit = require("XUi/XUiEquip/XUiEquipEnhanceProgress/XUiGridEnhanceProgressUnit")

local PROGRESS_KEY_OVERCLOCKING = "AwarenessOverclocking"

-- 初始化进度标题和异步回调状态
function XUiPanelAwarenessEnhanceProgressOverclocking:OnStart()
    self.TitleGrid = XUiGridEnhanceProgressUnit.New(self.PanelTitle, self)
    self.ExecuteCallbacks = nil
end

-- 根据超频预览结果刷新目标展示
---@param overclockingResult XAwarenessOneClickAwakePreviewResult 超频预览结果
function XUiPanelAwarenessEnhanceProgressOverclocking:Refresh(overclockingResult)
    self:RefreshTitleGrid(overclockingResult)
end

-- 刷新超频目标文案
---@param overclockingResult XAwarenessOneClickAwakePreviewResult 超频预览结果
function XUiPanelAwarenessEnhanceProgressOverclocking:RefreshTitleGrid(overclockingResult)
    local availableAwakeCount = overclockingResult.PreviewAwakeCount
    local unawakenedSkillCount = overclockingResult.UnawakenedSkillCount
    self.TitleGrid:Update({
        Key = PROGRESS_KEY_OVERCLOCKING,
        Name = self.TitleGrid.UiTxtUnitName.text,
        Target = XUiHelper.GetText("AwarenessOneClickAwakeProgressDesc", availableAwakeCount, unawakenedSkillCount),
    })
end

-- 仅更新展示状态；实际超频请求由父界面完成固定等待后调用 Execute 发起。
function XUiPanelAwarenessEnhanceProgressOverclocking:PrepareExecute()
    self.TitleGrid:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Processing)
end

-- 启动超频流程，并通过回调返回执行结果
---@param overclockingResult XAwarenessOneClickAwakePreviewResult 超频预览结果
---@param callbacks { onSuccess: fun(), onFail: fun(errorCode: number) } 执行结果回调
function XUiPanelAwarenessEnhanceProgressOverclocking:Execute(overclockingResult, callbacks)
    self.ExecuteCallbacks = callbacks

    self._Control.AwakeControl:StartAwarenessAwake(overclockingResult, function(isSuccess, errorCode)
        local executeCallbacks = self.ExecuteCallbacks
        self.ExecuteCallbacks = nil
        if not executeCallbacks then
            return
        end

        if isSuccess then
            self.TitleGrid:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Done)
            executeCallbacks.onSuccess()
        else
            self.TitleGrid:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Waiting)
            executeCallbacks.onFail(errorCode)
        end
    end)
end

-- 取消超频流程，并使尚未返回的异步回调失效
function XUiPanelAwarenessEnhanceProgressOverclocking:Cancel()
    self.ExecuteCallbacks = nil
    self._Control.AwakeControl:CancelAwarenessAwake()
    self.TitleGrid:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Waiting)
end

return XUiPanelAwarenessEnhanceProgressOverclocking
