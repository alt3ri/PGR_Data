local XUiPlotExhibitionUtil = {}

---@param ui XLuaUi|XUiNode
function XUiPlotExhibitionUtil.Init(ui, path)
    path = path or "SafeAreaContentPane/PanelDetail/UiPlotExhibitionPanelMode/BtnToggle"
    ui.SpeedrunBtnToggle = ui.SpeedrunBtnToggle or XUiHelper.TryGetComponent(ui.Transform, path, "XUiButton")
    if ui.SpeedrunBtnToggle then
        ui.SpeedrunTips = ui.SpeedrunTips or XUiHelper.TryGetComponent(ui.SpeedrunBtnToggle.transform.parent.transform, "PanelTips", "RectTransform")
    end
    if ui.SpeedrunBtnToggle then
        local txtTips = XUiHelper.TryGetComponent(ui.SpeedrunBtnToggle.transform.parent, "PanelTips/TxtTips", "Text")
        if txtTips then
            txtTips.text = XUiHelper.GetText("SpeedRunTips")
        else
            XLog.Warning("[XUiPlotExhibitionUtil] 修改速通提示文本失败")    
        end
    end
end

---@param ui XLuaUi|XUiNode
function XUiPlotExhibitionUtil.UpdateSpeedrunBtnToggle(ui, stageId)
    if not ui.SpeedrunBtnToggle then
        return
    end

    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SpeedrunStage, nil, true) then
        ui.SpeedrunBtnToggle.gameObject:SetActiveEx(false)
        XUiPlotExhibitionUtil.UpdateTips(ui, false)
        return
    end

    -- 没有配置的关卡，不显示速通模式
    local parent = ui.SpeedrunBtnToggle.transform.parent
    if not XMVCA.XPlotExhibition:IsShowSpeedrunToggle(stageId) then
        parent.gameObject:SetActiveEx(false)
        return
    end
    parent.gameObject:SetActiveEx(true)
    
    -- 悄悄把stageId记录下来, 供后续使用
    ui.__SpeedRunOriginalStageId = stageId

    local isSpeedrun = XMVCA.XPlotExhibition:GetIsSpeedrun(stageId)
    if isSpeedrun then
        ui.SpeedrunBtnToggle:SetButtonState(CS.UiButtonState.Select)
    else
        ui.SpeedrunBtnToggle:SetButtonState(CS.UiButtonState.Normal)
    end
    if not ui.SpeedrunBtnToggle.CallBack then
        ui.SpeedrunBtnToggle.CallBack = function(isOn)
            XUiPlotExhibitionUtil.OnClickToggle(ui, isOn == 1)
        end
    end
    XUiPlotExhibitionUtil.UpdateTips(ui, isSpeedrun)
end

---@param ui XLuaUi|XUiNode
function XUiPlotExhibitionUtil.OnClickToggle(ui, isOn)
    XMVCA.XPlotExhibition:SetIsSpeedrun(ui.__SpeedRunOriginalStageId, isOn)
    XUiPlotExhibitionUtil.UpdateTips(ui, isOn)
end

function XUiPlotExhibitionUtil.UpdateTips(ui, isOn)
    if ui.SpeedrunTips then
        ui.SpeedrunTips.gameObject:SetActiveEx(isOn)
    end
end

return XUiPlotExhibitionUtil