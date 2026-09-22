-- 意识一键养成强化进度面板
---@class XUiPanelAwarenessEnhanceProgressStrengthen : XUiNode
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
local XUiPanelAwarenessEnhanceProgressStrengthen = XClass(XUiNode, "XUiPanelAwarenessEnhanceProgressStrengthen")
local XUiGridEnhanceProgressUnit = require("XUi/XUiEquip/XUiEquipEnhanceProgress/XUiGridEnhanceProgressUnit")

local PROGRESS_KEY_STRENGTHEN = "AwarenessStrengthen"

-- 初始化进度标题和异步回调状态
function XUiPanelAwarenessEnhanceProgressStrengthen:OnStart()
    self.TitleGrid = XUiGridEnhanceProgressUnit.New(self.PanelTitle, self)
    self.ExecuteCallbacks = nil
end

-- 根据强化预览结果刷新目标展示
---@param strengthenResult XEquipAwarenessStrengthenPreviewResult 强化预览结果
function XUiPanelAwarenessEnhanceProgressStrengthen:Refresh(strengthenResult)
    self:RefreshTitleGrid(strengthenResult)
end

-- 刷新目标等级文案
---@param strengthenResult XEquipAwarenessStrengthenPreviewResult 强化预览结果
function XUiPanelAwarenessEnhanceProgressStrengthen:RefreshTitleGrid(strengthenResult)
    local targetText = XUiHelper.GetText(
        "AwarenessOneClickStrengthenTargetDesc",
        strengthenResult.OperationAwarenessCount,
        strengthenResult.TargetLevel
    )
    self.TitleGrid:Update({
        Key = PROGRESS_KEY_STRENGTHEN,
        Name = self.TitleGrid.UiTxtUnitName.text,
        Target = targetText,
    })

    local breakThroughIcon = self._Control:GetEquipBreakThroughIcon(strengthenResult.TargetBreakthrough)
    self.TitleGrid.ImgBreakIcon:SetSprite(breakThroughIcon)
end

-- 仅更新展示状态；实际强化请求由父界面完成固定等待后调用 Execute 发起。
function XUiPanelAwarenessEnhanceProgressStrengthen:PrepareExecute()
    self.TitleGrid:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Processing)
end

-- 启动强化流程，并通过回调返回执行结果
---@param strengthenResult table 强化预览结果
---@param callbacks { onSuccess: fun(), onFail: fun(errorCode: number) } 执行结果回调
function XUiPanelAwarenessEnhanceProgressStrengthen:Execute(strengthenResult, callbacks)
    self.ExecuteCallbacks = callbacks

    self._Control.StrengthenControl:StartAwarenessStrengthen(strengthenResult, function(isSuccess, errorCode)
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

-- 取消强化流程，并使尚未返回的异步回调失效
function XUiPanelAwarenessEnhanceProgressStrengthen:Cancel()
    self.ExecuteCallbacks = nil
    self._Control.StrengthenControl:CancelAwarenessStrengthen()
    self.TitleGrid:SetStatus(XUiGridEnhanceProgressUnit.STATUS.Waiting)
end

return XUiPanelAwarenessEnhanceProgressStrengthen
