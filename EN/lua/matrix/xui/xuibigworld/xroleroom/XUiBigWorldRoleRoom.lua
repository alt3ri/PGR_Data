local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local XUiModelDisplayHelper = require("XUi/XUiCommon/XUiModelDisplay/XUiModelDisplayHelper")
---@class XUiBigWorldRoleRoom : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Proxy XBigWorldBattleRoomProxy
---@field _Control XBigWorldControl
---@field _PanelRoleList XUiPanelBWRoleSheet 快捷编队界面
---@field _PanelRoleInfo XUiPanelBWRoleInfo
---@field _PanelRoleVList XUiPanelBWRoleList
---@field _DisplayController XUiModelDisplayController
local XUiBigWorldRoleRoom = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldRoleRoom")

local XUiModelDisplayController = require("XUi/XUiCommon/XUiModelDisplay/XUiModelDisplayController")

local MaxTeamPos = 3

local VirtualCamera = {
    Main = 1,
    Role = 2,
    Enter = 3,
}

function XUiBigWorldRoleRoom:OnAwake()
    self:InitUi()
    self:InitCb()
    XEventManager.AddEventListener(
        XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_COMMANDER_DIY_MODEL_UPDATE,
        self.OnCommanderDiyModelUpdate,
        self
    )
end

function XUiBigWorldRoleRoom:OnStart(teamIndex, proxy)
    self._DefaultIndex = teamIndex or XMVCA.XBigWorldCharacter:GetCurrentTeamId()
    self._Proxy = proxy and proxy.New() or require("XModule/XBigWorldCharacter/Proxy/XBigWorldBattleRoomProxy").New()
    self:InitView()
end

function XUiBigWorldRoleRoom:OnEnable()
    self:PlayEnableAnimation()
    self:UpdateCommandant()
    self:RefreshExpression()
end

function XUiBigWorldRoleRoom:RefreshExpression()
    if not self._Proxy or not self._DisplayController then
        return
    end
    for index = 1, MaxTeamPos do
        local entityId = self._EntityIds[index]
        if XTool.IsNumberValid(entityId) and not self._Proxy:IsCommandant(entityId) then
            local modelId = self._Proxy:GetUiModelId(entityId)

            if self._DisplayController:IsModelExist(modelId) then
                local fashionId = self._Proxy:GetFashionId(entityId)
                local animaName = self._Proxy:GetDefaultAnimName(entityId)
                XUiModelDisplayHelper.PlayExpression(self._DisplayController, modelId, fashionId, animaName)
            end
        end
    end
end

function XUiBigWorldRoleRoom:OnDisable()
    self._DefaultIndex = self._TabIndex
    self._TabIndex = nil
    self:HideAll()
    self:HideAllChangeRoleEffect()
end

function XUiBigWorldRoleRoom:OnDestroy()
    self._LongClick1:Destroy()
    self._LongClick2:Destroy()
    self._LongClick3:Destroy()
    XEventManager.RemoveEventListener(
        XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_COMMANDER_DIY_MODEL_UPDATE,
        self.OnCommanderDiyModelUpdate,
        self
    )
end

function XUiBigWorldRoleRoom:InitUi()
    -- 快捷编队界面
    self._PanelRoleList = require("XUi/XUiBigWorld/XRoleRoom/Panel/XUiPanelBWRoleSheet").New(self.PlayerInfoBaseNew, self)
    self._PanelRoleList:Close()
    self.FullscreenClose.gameObject:SetActiveEx(false)
    self.BtnBuffDetailClose.gameObject:SetActiveEx(false)
    self.MaskWaiting.gameObject:SetActiveEx(false)
    self._EntityIds = { 0, 0, 0 }

    self._PanelRoleInfo = require("XUi/XUiBigWorld/XRoleRoom/Panel/XUiPanelBWRoleInfo").New(self.PanelOwned, self)
    self._PanelRoleInfo:Close()
    self:InitTab()
    self:InitCharBtn()

    self._LongClickTime = 0
    self._LongClickInterval = 1
    self._Camera = CS.XUiManager.Instance.UiCamera
end

function XUiBigWorldRoleRoom:InitTab()
    local tab = {}
    local index = 1
    while true do
        local btn = self["BtnRank" .. index]
        if not btn then
            break
        end
        tab[#tab + 1] = btn
        index = index + 1
    end

    self.BtnGroup:Init(tab, function(tabIndex)
        self:OnSelectTab(tabIndex)
    end)
end

function XUiBigWorldRoleRoom:InitCharBtn()
    local uiModelRoot = self.UiModelGo.transform
    self._ParentList = {
        uiModelRoot:FindTransform("PanelRoleModel1"),
        uiModelRoot:FindTransform("PanelRoleModel2"),
        uiModelRoot:FindTransform("PanelRoleModel3"),
    }
    self._DisplayController = XUiModelDisplayController.New(uiModelRoot, true)
    
    uiModelRoot:Find("UiNearRoot/PanelRoleEffect1").gameObject:SetActiveEx(true)
    uiModelRoot:Find("UiNearRoot/PanelRoleEffect2").gameObject:SetActiveEx(true)
    uiModelRoot:Find("UiNearRoot/PanelRoleEffect3").gameObject:SetActiveEx(true)

    self._FxRoleBg = {
        uiModelRoot:Find("UiNearRoot/PanelBgEffect1"),
        uiModelRoot:Find("UiNearRoot/PanelBgEffect2"),
        uiModelRoot:Find("UiNearRoot/PanelBgEffect3"),
    }
    
    ---@type XMaterialAnimation3StepRendererMuteBinder[]
    self._FxRoleDisappear = {
        uiModelRoot:Find("UiNearRoot/PanelEffectDisappear1/FxUiBigWorldRoleRoom3DXianYin"):GetComponent(typeof(CS.XMaterialAnimation3StepRendererMuteBinder)),
        uiModelRoot:Find("UiNearRoot/PanelEffectDisappear2/FxUiBigWorldRoleRoom3DXianYin"):GetComponent(typeof(CS.XMaterialAnimation3StepRendererMuteBinder)),
        uiModelRoot:Find("UiNearRoot/PanelEffectDisappear3/FxUiBigWorldRoleRoom3DXianYin"):GetComponent(typeof(CS.XMaterialAnimation3StepRendererMuteBinder)),
    }
    for _, binder in pairs(self._FxRoleDisappear) do
        binder.gameObject:SetActiveEx(false)
    end

    local vRoot = uiModelRoot:FindTransform("VirtualCameraRoot")
    self._VirtualCameraDict = {
        [VirtualCamera.Main] = vRoot.transform:Find("VCameraMain"),
        [VirtualCamera.Role] = vRoot.transform:Find("VCameraRole"),
        [VirtualCamera.Enter] = vRoot.transform:Find("VCameraEnter"),
    }

    self._NearCamera = uiModelRoot:FindTransform("UiNearCamera")

    self._RoleCameraPoints = {}
    local rolePoint = uiModelRoot:FindTransform("RoleCameraPoint")
    local index = 1
    while true do
        local t = rolePoint.transform:Find("Point" .. index)
        if not t then
            break
        end
        self._RoleCameraPoints[index] = {
            Point = t.transform.localPosition,
            Rotation = t.transform.localRotation
        }
        index = index + 1
    end

    self._LongClick1 = XUiButtonLongClick.New(self.PointerChar1, 10, self, nil, self.OnBtnChar1LongClicked, self.OnBtnChar1LongPressUp, false)
    self._LongClick2 = XUiButtonLongClick.New(self.PointerChar2, 10, self, nil, self.OnBtnChar2LongClicked, self.OnBtnChar2LongPressUp, false)
    self._LongClick3 = XUiButtonLongClick.New(self.PointerChar3, 10, self, nil, self.OnBtnChar3LongClicked, self.OnBtnChar3LongPressUp, false)

    self:RegisterClickEvent(self.BtnChar1, self.OnBtnChar1Clicked)
    self:RegisterClickEvent(self.BtnChar2, self.OnBtnChar2Clicked)
    self:RegisterClickEvent(self.BtnChar3, self.OnBtnChar3Clicked)
end

function XUiBigWorldRoleRoom:InitCb()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))

    self.BtnEnterFight:AddEventListener(handler(self, self.OnBtnEnterFight))

    self.BtnBuffDetailClose:AddEventListener(handler(self, self.OnBtnDetailClicked))

    self.BtnQuick:AddEventListener(handler(self, self.OnBtnQuickClick))

    self:RegisterClickEvent(self.FullscreenClose, self.OnBtnDetailClicked)
end

function XUiBigWorldRoleRoom:InitView()
    local start = self.UiModelGo.transform:Find("Animation/Start")
    if start then
        start:PlayTimelineAnimation(function()
            self.BtnGroup:SelectIndex(self._DefaultIndex)
        end)
    end
end

function XUiBigWorldRoleRoom:UpdateView()
    for i = 1, MaxTeamPos do
        self:UpdateSingleModel(i, self._Team:GetEntityId(i))
        self:DisableLookAtIK(i)
    end
    self:UpdateCurrentTeam()
end

function XUiBigWorldRoleRoom:HideAll()
    self._DisplayController:HideAllModel()
end

function XUiBigWorldRoleRoom:HideAllChangeRoleEffect()
    if not self._FxRoleChange then
        return
    end
    for _, effect in pairs(self._FxRoleChange) do
        effect.gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldRoleRoom:HideModel(index)
    local entityId = self._EntityIds[index]
    if not entityId or entityId <= 0 then
        return
    end
    local modelId = self._Proxy:GetUiModelId(entityId)
    self._DisplayController:SetModelActive(modelId, false)
end

function XUiBigWorldRoleRoom:UpdateCommandant()
    if self.isCommandantModelDirty ~= true then
        return
    end
    if not self._Proxy or not self._DisplayController then
        return
    end
    self.isCommandantModelDirty = false
    for index = 1, MaxTeamPos do
        local entityId = self._EntityIds[index]
        if XTool.IsNumberValid(entityId) and self._Proxy:IsCommandant(entityId) then
            self:ForceUpdateCommandant(index, entityId)
            break
        end
    end
end

function XUiBigWorldRoleRoom:ForceUpdateCommandant(index, entityId)
    local isValid = XTool.IsNumberValid(entityId)
    if isValid == false then
        return
    end
    local display = self._DisplayController
    local modelId = self._Proxy:GetUiModelId(entityId)
    if XTool.IsNumberValid(self.effectTimerId) then
        XMVCA.XBigWorldUI:SetMaskActive(false)
        XScheduleManager.UnSchedule(self.effectTimerId)
        self.effectTimerId = 0
    end

    index = self._CurrentSelectIndex or index

    XMVCA.XBigWorldCommanderDIY:ForceUpdateCommandant(display, self._NearCamera, self._ParentList[index])
end

function XUiBigWorldRoleRoom:UpdateSingleModel(index, entityId)
    local isValid = XTool.IsNumberValid(entityId)
    self["ImgAdd" .. index].gameObject:SetActiveEx(not isValid)
    self["PanelName" .. index].gameObject:SetActiveEx(isValid)
    local display = self._DisplayController
    local oldId = self._EntityIds[index]
    local isPlayEffect = oldId ~= entityId and isValid
    local modelGo
    if isValid then
        self["TxtRank" .. index].text = string.format("%02d", index)
        self["TxtName" .. index].text = XMVCA.XBigWorldCharacter:GetCharacterLogName(entityId)
        self["UiBigWorldPanelStory" .. index].gameObject:SetActiveEx(XMVCA.XBigWorldCharacter:CheckCharacterTrial(entityId))
        local modelId = self._Proxy:GetUiModelId(entityId)
        local fashionId = self._Proxy:GetFashionId(entityId)

        if self._Proxy:IsCommandant(entityId) then
            XMVCA.XBigWorldCommanderDIY:LoadCurrentModel(display, self._NearCamera, self._ParentList[index])
            modelGo = display:GetModelObject(modelId, XEnumConst.PlayerFashion.PartType.Fashion)
        else
            local modelUrl = self._Proxy:GetModelUrl(entityId)
            local controllerUrl = self._Proxy:GetModelController(entityId)
            local helper = display:GetDisplayHelper()
            local modelInfo = helper.CreateBWModelDisplayInfo(modelId, modelUrl, controllerUrl, self._NearCamera,
                    self._ParentList[index], 0)

            helper.AddEffectInfos(modelInfo, fashionId)

            display:AddOrSetParentModel(modelInfo)
            modelGo = display:GetModelObject(modelId, 0)
            self:SetShowOrDisappear(index)
        end
        local animaName = self._Proxy:GetDefaultAnimName(entityId)
        display:PlayAnimation(modelId, animaName)
        --非指挥官根据动作摆放表情
        if self._Proxy:IsCommandant(entityId) then

        else
            XUiModelDisplayHelper.PlayExpression(display, modelId, fashionId, animaName)
        end
    end
    if modelGo and isPlayEffect then
        --比较无语的解法
        --由于渐显特效生效是跟加载出来不在同一帧，为了避免闪，先将模型移到比较远的地方
        --生效时再挪回来
        modelGo.transform:SetLocalPosition(500, 500, 500)
    end
    self._EntityIds[index] = entityId
    self:SetShowOrDisappear(index, modelGo)
    self:PlayChangeRoleEffect(index, isPlayEffect, modelGo)
    
end

function XUiBigWorldRoleRoom:UpdateCurrentTeam()
    local currentTeamId = XMVCA.XBigWorldCharacter:GetCurrentTeamId()
    local index = 1
    while true do
        local btn = self["BtnRank" .. index]
        if not btn then
            break
        end
        local teamId = XMVCA.XBigWorldCharacter:GetCommonTeamId(index)
        btn:ShowTag(teamId == currentTeamId)
        index = index + 1
    end
    local isCurrent = self._TeamId == currentTeamId
    self.BtnEnterFight:SetDisable(isCurrent, not isCurrent)
end

function XUiBigWorldRoleRoom:SetShowOrDisappear(index, model)
    if not model then
        -- 必须要有值才会更新
        model = self._NearCamera.gameObject
    end
    self._FxRoleDisappear[index].TargetModel = model
end

function XUiBigWorldRoleRoom:OnSelectTab(tabIndex)
    if self._TabIndex == tabIndex then
        return
    end
    self:PlayAnimation("Refresh")
    self._TabIndex = tabIndex
    self._TeamId = XMVCA.XBigWorldCharacter:GetCommonTeamId(tabIndex)
    self._Team = XMVCA.XBigWorldCharacter:GetDlcTeam(self._TeamId)
    self:HideAll()
    self:UpdateView()
end

function XUiBigWorldRoleRoom:OnBtnDetailClicked()
    self.BtnBuffDetailClose.gameObject:SetActiveEx(false)
    self.PanelUnder.gameObject:SetActiveEx(true)
    if self._PanelRoleList and self._PanelRoleList:IsNodeShow() then
        self:HideAll()
        --直接关闭界面时，恢复原队伍数据
        self._Team:Restore()
        self._PanelRoleList:Close()
        self.FullscreenClose.gameObject:SetActiveEx(false)
        self:UpdateView()
    end
    
    if self._PanelRoleVList and self._PanelRoleVList:IsNodeShow() then
        self:UpdateCamera(VirtualCamera.Main)
        local pos, entityId = self._PanelRoleVList:GetPosAndEntityId()
        if entityId ~= self._EntityIds[pos] then
            self:HideModel(pos)
        end
        self._PanelRoleVList:Close()
        self._PanelRoleInfo:Close()
        self._CurrentSelectIndex = false
        self.PanelRoom.gameObject:SetActiveEx(true)
        self:UpdateView()
        self:UpdateRoleActive(0)
        self:SetFxRoleBgShow(-1)
    end
end

function XUiBigWorldRoleRoom:OnBtnChar1Clicked()
    self:OnClickRole(1)
end

function XUiBigWorldRoleRoom:OnBtnChar2Clicked()
    self:OnClickRole(2)
end

function XUiBigWorldRoleRoom:OnBtnChar3Clicked()
    self:OnClickRole(3)
end

function XUiBigWorldRoleRoom:OnClickRole(index)
    if not self._PanelRoleVList then
        self.PanelCharacterFilter.gameObject:SetActiveEx(true)
        local url = XMVCA.XBigWorldResource:GetAssetUrl("PanelVList")
        local ui = self.PanelCharacterFilter:LoadPrefab(url)
        self._PanelRoleVList = require("XUi/XUiBigWorld/XRoleRoom/Panel/XUiPanelBWRoleList").New(ui, self, true)
    end
    self:SetFxRoleBgShow(index)
    local data = self._RoleCameraPoints[index]
    if data then
        self._VirtualCameraDict[VirtualCamera.Role].transform.localPosition = data.Point
        self._VirtualCameraDict[VirtualCamera.Role].transform.localRotation = data.Rotation
    end

    self._CurrentSelectIndex = index

    self.PanelRoom.gameObject:SetActiveEx(false)
    self.PanelUnder.gameObject:SetActiveEx(false)
    self._PanelRoleVList:RefreshView(self._TeamId, self._EntityIds[index], index)
    self.BtnBuffDetailClose.gameObject:SetActiveEx(true)
    self:UpdateCamera(VirtualCamera.Role)
    self:UpdateRoleActive(index)
end

function XUiBigWorldRoleRoom:OnBtnChar1LongClicked(time)
    self:OnBtnCharLongClicked(1, time)
end

function XUiBigWorldRoleRoom:OnBtnChar1LongPressUp()
    self:OnBtnCharLongPressUp(1)
end

function XUiBigWorldRoleRoom:OnBtnChar2LongClicked(time)
    self:OnBtnCharLongClicked(2, time)
end

function XUiBigWorldRoleRoom:OnBtnChar2LongPressUp()
    self:OnBtnCharLongPressUp(2)
end

function XUiBigWorldRoleRoom:OnBtnChar3LongClicked(time)
    self:OnBtnCharLongClicked(3, time)
end

function XUiBigWorldRoleRoom:OnBtnChar3LongPressUp()
    self:OnBtnCharLongPressUp(3)
end

function XUiBigWorldRoleRoom:OnBtnCharLongClicked(index, time)
    if not self._Proxy:DragEnable() then
        return
    end
    local entityId = self._Team:GetEntityId(index)
    if entityId <= 0 then
        return
    end
    self._LongClickTime = self._LongClickTime + time / 1000
    if self._LongClickTime < self._LongClickInterval then
        return
    end

    self.ImgRoleRepace.gameObject:SetActiveEx(true)
    self.ImgRoleRepace.transform.localPosition = self:GetClickPosition()
end

function XUiBigWorldRoleRoom:OnBtnCharLongPressUp(index)
    if not self.ImgRoleRepace or not self.ImgRoleRepace.gameObject.activeSelf then
        return
    end

    self._LongClickTime = 0
    self.ImgRoleRepace.gameObject:SetActiveEx(false)
    local transformWidth = self.Transform.rect.width
    local targetX = math.floor(self:GetClickPosition().x + transformWidth / 2)
    local oneThirdWidth = transformWidth / 3
    local switchPos = index
    if targetX <= oneThirdWidth then
        switchPos = 1
    elseif targetX > oneThirdWidth and targetX <= oneThirdWidth * 2 then
        switchPos = 2
    else
        switchPos = 3
    end

    if index == switchPos then
        return
    end

    self._Team:SwitchPos(index, switchPos)
    --不同步给服务器
    --self:UpdateView()
    --同步给服务器
    local team = self._Team
    XMVCA.XBigWorldCharacter:RequestUpdateTeam(self._TeamId, function()
        self:UpdateSingleModel(index, team:GetEntityId(index))
        self:UpdateSingleModel(switchPos, team:GetEntityId(switchPos))
    end)
end

function XUiBigWorldRoleRoom:GetClickPosition()
    return XUiHelper.GetScreenClickPosition(self.Transform, self._Camera)
end

function XUiBigWorldRoleRoom:OnSelectSingle(index, entityId, lerpTime)
    self:HideModel(index)
    local lastIndex = self:GetEntityIndex(entityId)
    if lastIndex > 0 and lastIndex ~= index then
        --先显示上一个
        self._FxRoleDisappear[lastIndex].gameObject:SetActiveEx(true)
        --置空上一个
        self:SetShowOrDisappear(lastIndex)
        --再显示这个一个
        self._FxRoleDisappear[index].gameObject:SetActiveEx(true)
        --隐藏上一个，避免切换角色时不显示
        self._FxRoleDisappear[lastIndex].gameObject:SetActiveEx(false)
        self._FxRoleDisappear[index].gameObject:SetActiveEx(false)
    end
    self:UpdateSingleModel(index, entityId)
    if entityId and entityId > 0 then
        self._PanelRoleInfo:RefreshView(self._TeamId, entityId, index)
    end
    self:SetLookAtIK(index, lerpTime)
end

function XUiBigWorldRoleRoom:OnBtnQuickClick()
    self.PanelUnder.gameObject:SetActiveEx(false)
    self._PanelRoleList:Open()
    self._PanelRoleList:RefreshView(self._TeamId)
    self.FullscreenClose.gameObject:SetActiveEx(true)
end

function XUiBigWorldRoleRoom:OnBtnEnterFight()
    local team = XMVCA.XBigWorldCharacter:GetDlcTeam(self._TeamId)
    if team:IsEmpty() then
        local text = XMVCA.XBigWorldService:GetText("EmptyTeamTip")
        XUiManager.TipMsg(text)
        return
    end

    XMVCA.XBigWorldCharacter:RequestSetFightingTeam(self._TeamId, function()
        self:UpdateCurrentTeam()
    end)
end

function XUiBigWorldRoleRoom:OnBtnBackClick()
    if self._PanelRoleList and self._PanelRoleList:IsNodeShow() then
        return self:OnBtnDetailClicked()
    end
    self:Close()
    --self.MaskWaiting.gameObject:SetActiveEx(true)
    --XMVCA.XBigWorldCharacter:SyncTeamDataToServer()
    --XMVCA.XBigWorldCharacter:SyncTeamData(XMVCA.XBigWorldCharacter:GetCurrentTeamId())
end

function XUiBigWorldRoleRoom:UpdateCamera(state)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    for s, vCamera in pairs(self._VirtualCameraDict) do
        vCamera.gameObject:SetActiveEx(s == state)
    end
end

function XUiBigWorldRoleRoom:UpdateRoleActive(index)
    if index <= 0 then
        for i, parent in pairs(self._FxRoleDisappear) do
            parent.gameObject:SetActiveEx(false)
        end
    else
        for i, parent in pairs(self._FxRoleDisappear) do
            parent.gameObject:SetActiveEx(i ~= index)
        end
    end
end

function XUiBigWorldRoleRoom:PlayChangeRoleEffect(index, isPlay, modelGo)
    if not self._FxRoleChange then
        self._FxRoleChange = {}
        local uiModelRoot = self.UiModelGo.transform
        self._FxRoleChange = {
            uiModelRoot:Find("UiNearRoot/PanelEffectHuanren1/FxUiBigWorldRoleRoom3DHuanrenMA(Clone)"):GetComponent(typeof(CS.XMaterialAnimation3StepRendererMuteBinder)),
            uiModelRoot:Find("UiNearRoot/PanelEffectHuanren2/FxUiBigWorldRoleRoom3DHuanrenMA(Clone)"):GetComponent(typeof(CS.XMaterialAnimation3StepRendererMuteBinder)),
            uiModelRoot:Find("UiNearRoot/PanelEffectHuanren3/FxUiBigWorldRoleRoom3DHuanrenMA(Clone)"):GetComponent(typeof(CS.XMaterialAnimation3StepRendererMuteBinder)),
        }
    end
    modelGo = modelGo or self._NearCamera.gameObject
    self._FxRoleChange[index].TargetModel = modelGo
    local effect = self._FxRoleChange[index]
    if not effect then
        return
    end
    if isPlay then
        effect.gameObject:SetActiveEx(false)
        XMVCA.XBigWorldUI:SetMaskActive(true)
        self.effectTimerId = XScheduleManager.ScheduleOnce(function()
            self.effectTimerId = 0
            XMVCA.XBigWorldUI:SetMaskActive(false)
            effect.gameObject:SetActiveEx(true)
            modelGo.transform:SetLocalPosition(0, 0, 0)
        end, 10)
        
    else
        effect.gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldRoleRoom:PlayEnableAnimation(finCb)
    self:PlayAnimation("Enable", finCb)
end

function XUiBigWorldRoleRoom:PlayDisableAnimation(finCb)
    self:PlayAnimation("Disable", finCb)
end

function XUiBigWorldRoleRoom:SetFxRoleBgShow(index)
    for i = 1, #self._FxRoleBg do
        self._FxRoleBg[i].gameObject:SetActiveEx(i == index)
    end
end

function XUiBigWorldRoleRoom:SetLookAtIK(index, lerpTime)
    local controller = self._DisplayController
    if not controller then
        return
    end
    local entityId = self._EntityIds[index]
    if not entityId or entityId <= 0 then
        return
    end
    if self._Proxy:IsCommandant(entityId) then
        XMVCA.XBigWorldCommanderDIY:SetLookAtIK(controller, self._NearCamera.transform, lerpTime)

    else
        local id = self._Proxy:GetUiModelId(entityId)
        local componentId = 0
        controller:SetLookAtIKWithInfo(id, componentId, self._NearCamera.transform, lerpTime)
    end
end

function XUiBigWorldRoleRoom:DisableLookAtIK(index)
    local controller = self._DisplayController
    if not controller then
        return
    end
    local entityId = self._EntityIds[index]
    if not entityId or entityId <= 0 then
        return
    end

    if self._Proxy:IsCommandant(entityId) then
        XMVCA.XBigWorldCommanderDIY:DisableLookAtIK(controller)
    else
        local id = self._Proxy:GetUiModelId(entityId)
        local componentId = 0
        controller:DisableLookAtIK(id, componentId)
    end
end

function XUiBigWorldRoleRoom:GetEntityIndex(entityId)
    for i, id in pairs(self._EntityIds) do
        if id == entityId then
            return i
        end
    end
    return -1
end

function XUiBigWorldRoleRoom:OnCommanderDiyModelUpdate()
    self.isCommandantModelDirty = true
end