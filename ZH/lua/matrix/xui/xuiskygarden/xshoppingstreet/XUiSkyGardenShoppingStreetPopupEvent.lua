---@class XUiSkyGardenShoppingStreetPopupEvent : XLuaUi
---@field BtnCustomer XUiComponent.XUiButton
---@field BtnStore XUiComponent.XUiButton
---@field TxtDetail UnityEngine.UI.Text
---@field TxtDetailCustomer UnityEngine.UI.Text
---@field RImgStory UnityEngine.UI.RawImage
---@field PanelTop UnityEngine.RectTransform
local XUiSkyGardenShoppingStreetPopupEvent = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetPopupEvent")
local XUiSkyGardenShoppingStreetAsset = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetAsset")
local ProgressAnimTime = 0.5

--region 生命周期

function XUiSkyGardenShoppingStreetPopupEvent:OnAwake()
    ---@type XUiSkyGardenShoppingStreetAsset
    self.PanelTopUi = XUiSkyGardenShoppingStreetAsset.New(self.PanelTop, self, true)
    self:_RegisterButtonClicks()

    local rt = self.PanelProgressBar.transform:GetComponent(typeof(CS.UnityEngine.RectTransform))
    self._RtBaseSize = rt.sizeDelta
    self._CustomerRt = self.ImgCustomer.transform:GetComponent(typeof(CS.UnityEngine.RectTransform))
end

function XUiSkyGardenShoppingStreetPopupEvent:OnStart(taskData)
    if not taskData then return end
    self._IsSelect = false
    self.BtnClose.gameObject:SetActive(self._IsSelect)

    self._EventData = taskData.EventData
    local eventId = self._EventData.EmergencyEventId
    self._Config = self._Control:GetCustomerEventEmergencyById(eventId)

    self.TxtTitle.text = self._Config.Desc
    if string.IsNilOrEmpty(self._Config.Icon) then
        self.RImgStory.gameObject:SetActive(false)
    else
        self.RImgStory:SetRawImage(self._Config.Icon)
        self.RImgStory.gameObject:SetActive(true)
    end
    self.TxtDetail.text = self._Config.OptionDescs[2]
    self.TxtDetailCustomer.text = self._Config.OptionDescs[1]
    
    self:UpdateBarInfo(0.5)
    self.TxtBtnCustomerNum.text = ""
    self.TxtBtnStoreNum.text = ""
end

function XUiSkyGardenShoppingStreetPopupEvent:UpdateBarInfo(percentage, animTime)
    local per = percentage
    if not per then
        local total = 0
        local right = 0
        for _, num in ipairs(self._EventData.EmergencyOptionTimesList or {80, 20}) do
            total = total + num
            right = num
        end
        per = (total - right) / total
    end
    local showPer = XMath.Clamp(per, 0.12, 0.88)
    local sizeData = self._CustomerRt.sizeDelta
    sizeData.x = self._RtBaseSize.x * showPer

    if showPer < 0.25 then
        self.BtnCustomer.gameObject:SetActive(false)
    elseif showPer < 0.4 then
        self.BtnCustomer.transform.localPosition = CS.UnityEngine.Vector3(-423, 0, 0)
    elseif showPer > 0.75 then
        self.BtnStore.gameObject:SetActive(false)
    elseif showPer > 0.6 then
        self.BtnStore.transform.localPosition = CS.UnityEngine.Vector3(423, 0, 0)
    end
    
    if animTime then
        local startDelta = self._CustomerRt.sizeDelta
        self:Tween(animTime, function(t)
            local gap = sizeData.x - startDelta.x
            local delta = CS.UnityEngine.Vector2(startDelta.x + gap * t, startDelta.y)
            self._CustomerRt.sizeDelta = delta
        end)
    else
        self._CustomerRt.sizeDelta = sizeData
    end

    local leftNum = XTool.MathGetRoundingValue(per, 2) * 100
    self.TxtBtnCustomerNum.text = leftNum .. "%"
    self.TxtBtnStoreNum.text = (100 - leftNum) .. "%"

    self.PanelProgressBar.gameObject:SetActive(true)
end

function XUiSkyGardenShoppingStreetPopupEvent:OnDestroy()
    self:_KillSequence()
end

--endregion

function XUiSkyGardenShoppingStreetPopupEvent:_KillSequence()
    if self._ScrollFlashSequence then
        if self._ScrollFlashSequence:IsActive() then
            self._ScrollFlashSequence:Kill(true)
        end
        self._ScrollFlashSequence = nil
    end
end

function XUiSkyGardenShoppingStreetPopupEvent:CalculateControlPoint(startPos, endPos, slopeFactor)
    -- // 简单计算控制点，这里的计算方式可根据坡度含义调整
    local midX = (startPos.x + endPos.x) / 2
    local midY = (startPos.y + endPos.y) / 2
    local midZ = (startPos.z + endPos.z) / 2
    -- // 根据坡度因子调整控制点的 Y 坐标，这里只是示例计算，可根据实际调整
    return CS.UnityEngine.Vector3(midX, midY + slopeFactor, midZ)
end

function XUiSkyGardenShoppingStreetPopupEvent:CalculateBezierPoint(t, startPos, controlPos, endPos)
    local x = math.pow(1 - t, 2) * startPos.x + 2 * (1 - t) * t * controlPos.x + math.pow(t, 2) * endPos.x
    local y = math.pow(1 - t, 2) * startPos.y + 2 * (1 - t) * t * controlPos.y + math.pow(t, 2) * endPos.y
    local z = math.pow(1 - t, 2) * startPos.z + 2 * (1 - t) * t * controlPos.z + math.pow(t, 2) * endPos.z
    return CS.UnityEngine.Vector3(x, y, z)
end

function XUiSkyGardenShoppingStreetPopupEvent:GenerateCurvePoints(startPos, controlPos, endPos, numPoints)
    local points = {}
    for i = 1, numPoints do
        local t = (i - 1) / (numPoints - 1)
        local curvePoint = self:CalculateBezierPoint(t, startPos, controlPos, endPos)
        table.insert(points, curvePoint)
    end
    return points
end

function XUiSkyGardenShoppingStreetPopupEvent:_PlayEffect(index)
    local effect, startPos, endPos
    if index == 1 then
        startPos = self.FxUiPanelChoiceBtnCustomer.transform.position
    else
        startPos = self.FxUiPanelChoiceBtnStore.transform.position
    end

    local buffId
    if self._Control:HasEmergencyRewardSpOptionBuff() then
        buffId = self._Config.SpOptionBuffs[index]
    else
        buffId = self._Config.OptionBuffs[index]
    end
    local buffParams = self._Control:ParseBuffDescParamsById(buffId)
    local buffInfo = buffParams.buffs[1] or {}
    local bType = buffInfo.bType or 2
    local cType
    if bType == 1 then
        cType = XMVCA.XSkyGardenShoppingStreet.StageResType.InitGold
        effect = self.EffectA2
    else
        cType = XMVCA.XSkyGardenShoppingStreet.StageResType.InitEnvironment
        effect = self.EffectA1
    end

    endPos = self.PanelTopUi:GetResUiPos(cType) or startPos

    -- effect = self.EffectA2
    -- endPos = self.PanelTopUi:GetResUiPos(XMVCA.XSkyGardenShoppingStreet.StageResType.InitGold)

    if not effect then return end
    -- effect.transform.position = endPos
    -- local targetLocalPos = effect.transform.localPosition

    effect.transform.position = startPos
    effect.gameObject:SetActive(true)

    self:_KillSequence()
    local scrollFlashSequence = CS.DG.Tweening.DOTween.Sequence()
    scrollFlashSequence:AppendInterval(0.3)

    -- local controlPos = self:CalculateControlPoint(startPos, endPos, -2)
    -- local points = self:GenerateCurvePoints(startPos, controlPos, endPos, 5)
    -- scrollFlashSequence:Append(effect:DOPath(points, 0.5, CS.DG.Tweening.PathType.CatmullRom))
    -- scrollFlashSequence:Append(effect:DOMove(endPos, 0.5))
    
    scrollFlashSequence:AppendCallback(function()
        local moveTime = 0.4
        effect.transform:DOMoveX(endPos.x, moveTime):SetEase(CS.DG.Tweening.Ease.InOutQuad)
        effect.transform:DOMoveY(endPos.y, moveTime):SetEase(CS.DG.Tweening.Ease.InQuad)
        effect.transform:DOMoveZ(endPos.z, moveTime):SetEase(CS.DG.Tweening.Ease.InQuad)
    end)
    scrollFlashSequence:AppendInterval(0.5)
    scrollFlashSequence:AppendCallback(function()
        self.PanelTopUi:UpdatePanel()
    end)
    scrollFlashSequence:AppendInterval(0.5)
    scrollFlashSequence:AppendCallback(function()
        effect.gameObject:SetActive(false)
    end)
    scrollFlashSequence:Play()
    self._ScrollFlashSequence = scrollFlashSequence
    -- effect:DOPath
end

--region 按钮事件

function XUiSkyGardenShoppingStreetPopupEvent:OnBtnCustomerClick()
    if self._IsSelect then return end
    self:_PlayEffect(1)
    self:_DoEmergencyEventByIndex(1)
end

function XUiSkyGardenShoppingStreetPopupEvent:OnBtnStoreClick()
    if self._IsSelect then return end
    self:_PlayEffect(2)
    self:_DoEmergencyEventByIndex(2)
end

function XUiSkyGardenShoppingStreetPopupEvent:OnBtnCloseClick()
    self:Close()
end

--endregion

--region 私有方法

function XUiSkyGardenShoppingStreetPopupEvent:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnCustomer:AddEventListener(handler(self, self.OnBtnCustomerClick))
    self.BtnStore:AddEventListener(handler(self, self.OnBtnStoreClick))
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
end

function XUiSkyGardenShoppingStreetPopupEvent:_SetSelectState()
    self._IsSelect = true
    self.BtnClose.gameObject:SetActive(self._IsSelect)
    self.BtnCustomer:SetButtonState(CS.UiButtonState.Disable)
    self.BtnStore:SetButtonState(CS.UiButtonState.Disable)
end

function XUiSkyGardenShoppingStreetPopupEvent:_DoEmergencyEventByIndex(index)
    self:_SetSelectState()
    if self._Control:HasEmergencyRewardSpOptionBuff() then
        self._Control:DoEmergencyEvent(self._EventData.Id, index, self._Config.SpOptionBuffs[index])
    else
        self._Control:DoEmergencyEvent(self._EventData.Id, index, self._Config.OptionBuffs[index])
    end
    self:UpdateBarInfo(nil, ProgressAnimTime)
end

--endregion

return XUiSkyGardenShoppingStreetPopupEvent
