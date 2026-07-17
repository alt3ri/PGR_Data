local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")

local XAutoRotationType = typeof(CS.XAutoRotation)
local XDragAutoRotateType = typeof(CS.XDragAutoRotate)

---@class XUiEquipDetailV2P6 : XLuaUi
---@field _Control XEquipControl
---@field EffectUiOverrunV4P6 UnityEngine.GameObject
local XUiEquipDetailV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipDetailV2P6")

function XUiEquipDetailV2P6:OnAwake()
    -- UI初始化
    self.PanelTab.gameObject:SetActiveEx(false)

    -- 场景初始化
    local sceneRoot = self.UiSceneInfo.Transform
    local root = self.UiModelGo.transform
    self.PanelWeapon = root:FindTransform("PanelWeapon")
    self.PanelWeaponPlane = sceneRoot:FindTransform("Plane")
    self.PanelWeaponPlane.gameObject:SetActiveEx(false)
    self.ImgEffectOverrun = root:FindTransform("ImgEffectOverrun")
    self.EffectUiOverrunV4P6 = root:FindTransform("EffectUiOverrunV4P6")
    self:InitVirtualCamera(root)

    self:SetButtonCallBack()
    self:InitPanelAsset()
    self:InitTabGroup()
end

--参数isPreview为true时是装备详情预览，传templateId进来
--characterId只有需要判断武器共鸣特效时才传
function XUiEquipDetailV2P6:OnStart(equipId, isPreview, characterId, forceShowBindCharacter, childUiIndex, openUiType, openResonanceSkillPos)
    self.IsPreview = isPreview
    self.EquipId = equipId
    self.CharacterId = characterId
    self.ForceShowBindCharacter = forceShowBindCharacter
    self.TabIndex = childUiIndex
    self.TemplateId = isPreview and self.EquipId or XMVCA.XEquip:GetEquipTemplateId(equipId)
    self.OpenUiType = openUiType
    self.OpenResonanceSkillPos = openResonanceSkillPos
    self.IsWeapon = XMVCA.XEquip:IsEquipWeapon(self.TemplateId)
    self.IsAwareness = XMVCA.XEquip:IsEquipAwareness(self.TemplateId)
    if self.IsAwareness then
        self.SelectAwarenessIndex = XMVCA.XEquip:GetEquipSiteByEquipId(equipId)
    end

    if not XDataCenter.VoteManager.IsInit() then
        XDataCenter.VoteManager.GetVoteGroupListRequest()
    end
end

function XUiEquipDetailV2P6:OnEnable()
    self:UpdateView()
end

function XUiEquipDetailV2P6:OnDestroy()
    self.PanelWeaponPlane.gameObject:SetActiveEx(true)
    self:ResetWeaponRotateState()
    self.WeaponDragRotate = nil  -- DragRotate 绑在 PanelDrag 上，仅销毁时清
    self:ReleaseModel()
    self:ReleaseLihuiTimer()

    self.TabGroup = nil
end

function XUiEquipDetailV2P6:OnGetEvents()
    return {
        XEventId.EVENT_EQUIP_OVERRUN_CHANGE_NOTYFY,
    }
end

function XUiEquipDetailV2P6:OnNotify(evt, ...)
    local args = {...}
    if evt == XEventId.EVENT_EQUIP_OVERRUN_CHANGE_NOTYFY then
        self:UpdateBtnOverrunRed()
    end
end

function XUiEquipDetailV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
    self:RegisterClickEvent(self.BtnStrengthenMax, self.OnBtnStrengthenMax)

    if XUiManager.IsHideFunc then
        self.BtnHelp.gameObject:SetActiveEx(false)
    end
    
    -- 意识切换
    self:RegisterAwarenessSwitch()
end

function XUiEquipDetailV2P6:OnBtnBackClick()
    if XLuaUiManager.IsUiShow("UiEquipResonanceSelectV2P6") then
        self.PanelTabGroup:SelectIndex(XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE)
        return
    end 
    if XLuaUiManager.IsUiShow("UiEquipResonanceAwakeV2P6") then
        self.PanelTabGroup:SelectIndex(XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING)
        return
    end

    -- 超频界面，如果详情面板打开着，先关闭详情面板
    if self.CurChildName == "UiEquipOverrunV4P6" then
        ---@type XUiEquipOverrunV4P6
        local child = self:FindChildUiObj("UiEquipOverrunV4P6")
        if child and child:GetIsShowPanelDetail() then
            child:ClosePanelDetail()
            return
        end
    end
    
    self:Close()
end

-- 关闭界面且让上一个界面选中当前操作的装备
function XUiEquipDetailV2P6:CloseWithSelectCurEquip()
    local equipId = self.EquipId
    self:Close()
    XEventManager.DispatchEvent(XEventId.EVENT_EQUIP_SELECT_EQUIP, equipId)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_EQUIP_SELECT_EQUIP, equipId)
end

function XUiEquipDetailV2P6:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiEquipDetailV2P6:OnBtnStrengthenMax()
    XUiManager.TipText("EquipStrengthenMaxLevel")
end

function XUiEquipDetailV2P6:OnBtnHelpClick()
    local keyStr = self.IsWeapon and "EquipWeapon" or "EquipAwareness"

    local indexKey
    if self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.STRENGTHEN then
        indexKey = self.IsWeapon and "WeaponHelpStrength" or "AwarenessHelpStrength"
    elseif self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE then
        indexKey = self.IsWeapon and "WeaponHelpResonance" or "AwarenessHelpResonance"
    elseif self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING then
        indexKey = "AwarenessHelpOverclocking"
    elseif self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERRUN then
        if self:HasWeaponOverrunLevel2() then
            XUiManager.ShowHelpTip("WeaponOverrun2")
            return
        end

        indexKey = "WeaponHelpOverrun"
    end
    local index = CS.XGame.ClientConfig:GetInt(indexKey)

    XUiManager.ShowHelpTip(keyStr, nil, index)
end

function XUiEquipDetailV2P6:HasWeaponOverrunLevel2()
    local characterId = XTool.IsNumberValidEx(self.CharacterId) and self.CharacterId or XMVCA.XEquip:GetWeaponOverrunCharacterId(self.TemplateId)
    local overrunCfgIds = self._Control:GetWeaponOverrunCfgIds(self.TemplateId, characterId)
    return XTool.IsNumberValidEx(overrunCfgIds[XEnumConst.EQUIP.WEAPON_OVERRUN_LEVEL_TYPE.LEVEL2])
end

function XUiEquipDetailV2P6:IsShowOverrunSceneEffect(level)
    local characterId = XTool.IsNumberValidEx(self.CharacterId) and self.CharacterId or XMVCA.XEquip:GetWeaponOverrunCharacterId(self.TemplateId)
    local overrunCfgIds = self._Control:GetWeaponOverrunCfgIds(self.TemplateId, characterId)
    if #overrunCfgIds <= 1 then
        return true
    end

    if self.CurChildName == "UiEquipOverrunV4P6" then
        ---@type XUiEquipOverrunV4P6
        local child = self:FindChildUiObj("UiEquipOverrunV4P6")
        level = child:GetUiLayoutKey()
        if level == 0 then
            return true
        end
    end

    local overrunCfg = self._Control:GetWeaponOverrunConfigById(overrunCfgIds[level])
    return overrunCfg and overrunCfg.ShowOverrunEffect
end

function XUiEquipDetailV2P6:InitPanelAsset()
    self.DefaultAssetItemIds = {
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin,
    }
    self.OverrunAssetItemIds = {
        XDataCenter.ItemManager.ItemId.EquipOverrunCoin1,
        XDataCenter.ItemManager.ItemId.EquipOverrunCoin2,
    }
    self.AssetPanel = XUiPanelAsset.New(
        self,
        self.PanelAsset,
        table.unpack(self.DefaultAssetItemIds)
    )
end

-- 根据当前选中的页签刷新资源栏展示的物品
function XUiEquipDetailV2P6:RefreshAssetPanelByTab(tabIndex)
    if not self.AssetPanel then
        return
    end
    if tabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERRUN then
        self.AssetPanel:RefreshBindItem(table.unpack(self.OverrunAssetItemIds))
    else
        self.AssetPanel:RefreshBindItem(table.unpack(self.DefaultAssetItemIds))
    end
end

-- 初始化武器模型/意识立绘
function XUiEquipDetailV2P6:InitModel()
    self:ResetWeaponRotateState()

    self.PanelWeapon.gameObject:SetActiveEx(false)
    self.FxUiLihuiChuxian01.gameObject:SetActiveEx(false)
    if self.IsWeapon then
        self.PanelWeapon.gameObject:SetActiveEx(true)
        local breakthroughTimes = not self.IsPreview and XMVCA.XEquip:GetEquipBreakthroughTimes(self.EquipId) or 0
        local resonanceCount = not self.IsPreview and XMVCA.XEquip:GetEquipResonanceCount(self.EquipId) or 0
        local modelTransformName = "UiEquipDetail"
        local modelConfig = XMVCA.XEquip:GetWeaponModelCfg(self.TemplateId, modelTransformName, breakthroughTimes, resonanceCount)
        if modelConfig then
            XModelManager.LoadWeaponModel(
                modelConfig.ModelId,
                self.PanelWeapon,
                modelConfig.TransformConfig,
                modelTransformName,
                function(model)
                    self.WeaponModel = model
                    if not XTool.UObjIsNil(model) then
                        self.WeaponAutoRotate = model:GetComponent(XAutoRotationType)
                        -- 记录初始位置和旋转，供 DoTweenRotateWeaponToOrigin 还原
                        self.WeaponOriginPos = model.transform.localPosition
                        self.WeaponOriginEuler = model.transform.localEulerAngles
                    end
                    if not self.WeaponDragRotate and not XTool.UObjIsNil(self.PanelDrag) then
                        self.WeaponDragRotate = self.PanelDrag:GetComponent(XDragAutoRotateType)
                    end
                end,
                {gameObject = self.GameObject, usage = XEnumConst.EQUIP.WEAPON_USAGE.SHOW, IsDragRotation = true, AntiClockwise = true},
                self.PanelDrag
            )
        end
    elseif self.IsAwareness then
        self:ReleaseModel()

        local breakthroughTimes = not self.IsPreview and XMVCA.XEquip:GetEquipBreakthroughTimes(self.EquipId) or 0
        local resPath = XMVCA.XEquip:GetEquipLiHuiPath(self.TemplateId, breakthroughTimes)
        self.Loader = self.Loader or self.Transform:GetLoader()
        local texture = self.Loader:Load(resPath)
        self.MeshLihui.sharedMaterial:SetTexture("_MainTex", texture)
        
        self:ReleaseLihuiTimer()
        self.LihuiTimer = XScheduleManager.ScheduleOnce(function()
            self.FxUiLihuiChuxian01.gameObject:SetActiveEx(true)
            self.LihuiTimer = nil
        end, 500)
    end
end

-- 释放模型
function XUiEquipDetailV2P6:ReleaseModel()
    
end

-- 释放定时器
function XUiEquipDetailV2P6:ReleaseLihuiTimer()
    if self.LihuiTimer then
        XScheduleManager.UnSchedule(self.LihuiTimer)
        self.LihuiTimer = nil
    end
end

function XUiEquipDetailV2P6:InitTabGroup()
    self.TabGroup = {
        self.BtnStrengthen,
        self.BtnResonance,
        self.BtnOverclocking,
        self.BtnOverrun,
    }

    self.PanelTabGroup:Init(self.TabGroup, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

-- 显示或隐藏页签
function XUiEquipDetailV2P6:ShowPanelTabGroup(isShow)
    self.PanelTabGroup.gameObject:SetActiveEx(isShow)
end

function XUiEquipDetailV2P6:OnClickTabCallBack(tabIndex)
    if tabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.STRENGTHEN then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipStrengthen) then
            return
        end
        self:OpenChildUiByName("UiEquipStrengthenV2P6", self)
    elseif tabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE then
        if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipResonance) then
            return
        end
        if self.OpenResonanceSkillPos then 
            self:OpenChildUiResonanceSelect(self.OpenResonanceSkillPos)
            self.OpenResonanceSkillPos = nil
        else
            self:OpenChildUiByName("UiEquipResonanceSkillV2P6", self, self.CharacterId, self.ForceShowBindCharacter)
        end
        
    elseif tabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING then
        if not self:CheckCanOverclocking(self.EquipId) then
            XUiManager.TipText("SuperAwareness")
            return
        end
        if self.OpenResonanceSkillPos then
            self:OpenChildUiResonanceAwake(self.OpenResonanceSkillPos)
            self.OpenResonanceSkillPos = nil
        else
            self:OpenChildUiByName("UiExhibitionOverclockingV2P6", self, self.CharacterId, self.ForceShowBindCharacter)
        end
    elseif tabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERRUN then
        if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun) then 
            local tips = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.EquipOverrun)
            XUiManager.TipError(tips)
            return
        end
        self:SaveEnterOverrunRedData()
        self:UpdateBtnOverrunRed()

        -- 打开超限界面
        local childUiName = self:HasWeaponOverrunLevel2() and "UiEquipOverrunV4P6" or "UiEquipOverrunV2P6"
        self:OpenChildUiByName(childUiName, self)
    end

    self.TabIndex = tabIndex
    self:RefreshAssetPanelByTab(tabIndex)
    if self.IsAwareness then
        self:UpdateAwarenessSwitchBtn()
    end
end

-- 在该类内自己打开ui
function XUiEquipDetailV2P6:OpenChildUiByName(uiname, ...)
    self.CurChildName = uiname
    self:OpenOneChildUi(uiname, ...)
end

-- 打开共鸣对应位置界面
function XUiEquipDetailV2P6:OpenChildUiResonanceSelect(pos)
    self:OpenOneChildUi("UiEquipResonanceSelectV2P6", self, self.CharacterId, self.ForceShowBindCharacter)
    self.ChildUiEquipResonanceSelectV2P6:SetPos(self.EquipId, pos)
    self:UpdateAwarenessSwitchBtn()
end

-- 打开超频对应位置界面
function XUiEquipDetailV2P6:OpenChildUiResonanceAwake(pos)
    self:OpenOneChildUi("UiEquipResonanceAwakeV2P6", self, self.CharacterId, self.ForceShowBindCharacter)
    self.ChildUiEquipResonanceAwakeV2P6:SetPos(self.EquipId, pos)
    self:UpdateAwarenessSwitchBtn()
end

-- 共鸣成功
function XUiEquipDetailV2P6:OnResonanceSuccess(pos, openInEnable)
    self.ResonanceSuccessPos = pos
    if openInEnable then
        self.TabIndex = XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE
    else
        self:UpdateOverclockingBtn()
        self.PanelTabGroup:SelectIndex(XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE)
    end
end

-- 清除共鸣成功的位置记录
function XUiEquipDetailV2P6:ClearResonanceSuccessPos()
    self.ResonanceSuccessPos = nil
end

-- 超频成功
function XUiEquipDetailV2P6:OnOverClockingSuccess(pos, openInEnable)
    self.OverClockingSuccessPos = pos
    if openInEnable then
        self.TabIndex = XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING
    else
        self.PanelTabGroup:SelectIndex(XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING)
    end
end

-- 清除超频成功的位置记录
function XUiEquipDetailV2P6:ClearOverClockingSuccessPos()
    self.OverClockingSuccessPos = nil
end

-- 跳转到共鸣页签，对应位置共鸣界面
function XUiEquipDetailV2P6:JumpToEquipResonanceSelect(pos)
    if self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE then
        self:OpenChildUiResonanceSelect(pos)
    else
        self.OpenResonanceSkillPos = pos
        self.PanelTabGroup:SelectIndex(XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE)
    end
end

function XUiEquipDetailV2P6:UpdateTabBtnState()
    if self.IsPreview then
        self.PanelTabGroup.gameObject:SetActiveEx(false)
        return
    end

    -- 强化
    self:UpdateStrengthenBtn()

    -- 共鸣
    local isShowResonance = not XFunctionManager.CheckFunctionFitter(XFunctionManager.FunctionName.EquipResonance) and
        XMVCA.XEquip:CanResonanceByTemplateId(self.TemplateId)
    self.BtnResonance.gameObject:SetActiveEx(isShowResonance)
    if isShowResonance then
        self.BtnResonance:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipResonance))
    end

    -- 超频
    self:UpdateOverclockingBtn()

    -- 超限
    local canOverrun = self._Control:CanOverrunByTemplateId(self.TemplateId)
    self.BtnOverrun.gameObject:SetActiveEx(canOverrun)
    if canOverrun then
        self.BtnOverrun:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun))
        self:UpdateBtnOverrunRed()
    end
end

-- 刷新界面
function XUiEquipDetailV2P6:UpdateView()
    self:InitModel()
    self:UpdateOverrunSceneEffect()
    self:UpdateTabBtnState()
    self.PanelTabGroup:SelectIndex(self.TabIndex)
end

-- 刷新强化按钮
function XUiEquipDetailV2P6:UpdateStrengthenBtn()
    if self.IsPreview then
        return
    end
    local equipId = self.EquipId

    if XMVCA.XEquip:CanBreakThrough(equipId) then
        self.BtnStrengthen:SetNameByGroup(0, XUiHelper.GetText("EquipBreakthroughBtnTxt1"))
        self.BtnStrengthen:SetNameByGroup(1, XUiHelper.GetText("EquipBreakthroughBtnTxt2"))
    else
        self.BtnStrengthen:SetNameByGroup(0, XUiHelper.GetText("EquipStrengthenBtnTxt1"))
        self.BtnStrengthen:SetNameByGroup(1, XUiHelper.GetText("EquipStrengthenBtnTxt2"))
    end

    local isMaxLevel = XMVCA.XEquip:IsMaxLevelAndBreakthrough(equipId)
    self.BtnStrengthenMax.gameObject:SetActiveEx(isMaxLevel)
    self.BtnStrengthen.gameObject:SetActiveEx(not isMaxLevel)
    if not isMaxLevel then 
        self.BtnStrengthen:SetDisable(not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipStrengthen))
    end
end

-- 刷新超频按钮
function XUiEquipDetailV2P6:UpdateOverclockingBtn()
    local isShowOverclocking = self.IsAwareness and XMVCA.XEquip:CheckEquipStarCanAwake(self.EquipId)
    self.BtnOverclocking.gameObject:SetActiveEx(isShowOverclocking)
    if isShowOverclocking then
        self.BtnOverclocking:SetDisable(not self:CheckCanOverclocking(self.EquipId))
    end
end

--------------------#region 武器 --------------------

-- 刷新超限按钮红点
function XUiEquipDetailV2P6:UpdateBtnOverrunRed()
    if self.IsPreview then
        return
    end

    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    self.BtnOverrun:ShowReddot(equip:IsShowOverrunRed())
end

-- 保存进入过超限界面的红点数据
function XUiEquipDetailV2P6:SaveEnterOverrunRedData()
    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    equip:SaveEnterOverrunRedData()
end

-- 刷新超限场景特效
function XUiEquipDetailV2P6:UpdateOverrunSceneEffect()
    self.ImgEffectOverrun.gameObject:SetActiveEx(false)
    if self.IsPreview then
        return
    end

    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    local level = equip:GetOverrunLevel()
    if level < 1 then
        return
    end
    if not self:IsShowOverrunSceneEffect(level) then
        return
    end

    self.ImgEffectOverrun.gameObject:SetActiveEx(true)
    local sceneLoopEffectPath = self._Control:GetWeaponDeregulateUISceneLoopEffectPath(level)
    if sceneLoopEffectPath then
        self.ImgEffectOverrun:LoadPrefab(sceneLoopEffectPath)
    end
end

-- 播放超限升级特效
function XUiEquipDetailV2P6:PlayOverrunLevelUpEffect()
    self.ImgEffectOverrun.gameObject:SetActiveEx(false)
    if self.IsPreview then
        return
    end

    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    local level = equip:GetOverrunLevel()
    if level < 1 then
        return
    end
    if not self:IsShowOverrunSceneEffect(level) then
        return
    end

    self.ImgEffectOverrun.gameObject:SetActiveEx(true)
    local sceneStartEffectPath = self._Control:GetWeaponDeregulateUISceneStartEffectPath(level)
    if sceneStartEffectPath then
        self.ImgEffectOverrun:LoadPrefab(sceneStartEffectPath)
    end
end

-- 杀掉武器旋转 DoTween，避免叠加和野回调
function XUiEquipDetailV2P6:KillWeaponRotateTween()
    if self.WeaponRotateTween then
        self.WeaponRotateTween:Kill(false)
        self.WeaponRotateTween = nil
    end
end

-- 重置武器旋转相关状态（不含 DragRotate，DragRotate 绑在 PanelDrag 上）
function XUiEquipDetailV2P6:ResetWeaponRotateState()
    self:KillWeaponRotateTween()
    self.WeaponModel = nil
    self.WeaponAutoRotate = nil
    self.WeaponOriginPos = nil
    self.WeaponOriginEuler = nil
end

-- 禁用武器拖拽旋转 + 自动旋转
function XUiEquipDetailV2P6:DisableWeaponRotate()
    if self.WeaponDragRotate then
        self.WeaponDragRotate.enabled = false
    end
    if self.WeaponAutoRotate then
        self.WeaponAutoRotate.IsAutoRotation = false
    end
end

-- 重新启用武器拖拽旋转 + 自动旋转
function XUiEquipDetailV2P6:EnableWeaponRotate()
    if self.WeaponDragRotate then
        self.WeaponDragRotate.enabled = true
    end
    if self.WeaponAutoRotate then
        self.WeaponAutoRotate.IsAutoRotation = true
        self.WeaponAutoRotate.Inited = false
    end
end

-- DoTween 把武器还原到加载时记录的初始位置和旋转
-- @param duration    时长，秒；默认 0.5
-- @param onComplete  完成回调（可选）
function XUiEquipDetailV2P6:DoTweenRotateWeaponToOrigin(duration, onComplete)
    if XTool.UObjIsNil(self.WeaponModel) or not self.WeaponOriginEuler then
        return
    end

    self:DisableWeaponRotate()
    self:KillWeaponRotateTween()

    duration = duration or 0.5
    local ease = CS.DG.Tweening.Ease.OutQuart
    self.WeaponModel.transform:DOLocalMove(self.WeaponOriginPos, duration):SetEase(ease)
    self.WeaponRotateTween = self.WeaponModel.transform:DOLocalRotate(self.WeaponOriginEuler, duration)
        :SetEase(ease)
        :OnComplete(function()
            self.WeaponRotateTween = nil
            if onComplete then
                onComplete()
            end
        end)
end

--------------------#endregion 武器 --------------------

--------------------#region 意识 --------------------

-- 注册切换意识事件
function XUiEquipDetailV2P6:RegisterAwarenessSwitch()
    self:RegisterClickEvent(self.BtnLeft, self.OnBtnLeft)
    self:RegisterClickEvent(self.BtnRight, self.OnBtnRight)

    local btns = {}
    for index = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        table.insert(btns, self["BtnNumber" .. index])
    end
    self.BtnGridGroup:Init(btns, function(index)
        self:OnClickSwitchAwareness(index)
    end)
end

function XUiEquipDetailV2P6:OnBtnLeft()
    local index = self.SelectAwarenessIndex
    while(index > 1) do
        index = index - 1
        local canSwitch = self:CheckCanSwitchAwareness(index)
        if canSwitch then
            self:OnClickSwitchAwareness(index)
            return
        end
    end
end

function XUiEquipDetailV2P6:OnBtnRight()
    local index = self.SelectAwarenessIndex
    while(index < XEnumConst.EQUIP.WEAR_AWARENESS_COUNT) do
        index = index + 1
        local canSwitch = self:CheckCanSwitchAwareness(index)
        if canSwitch then
            self:OnClickSwitchAwareness(index)
            return
        end
    end
end

-- 点击切换意识
function XUiEquipDetailV2P6:OnClickSwitchAwareness(index)
    if self.SelectAwarenessIndex == index then
        return
    end
    
    local canSwitch = self:CheckCanSwitchAwareness(index)
    if not canSwitch then
        return
    end

    self.SelectAwarenessIndex = index
    self.EquipId = XMVCA.XEquip:GetCharacterEquipId(self.CharacterId, index)
    self.TemplateId = XMVCA.XEquip:GetEquipTemplateId(self.EquipId)
    self:UpdateView()
end

-- 检查是否可以切换到对应位置的意识
function XUiEquipDetailV2P6:CheckCanSwitchAwareness(index)
    local equipId = XMVCA.XEquip:GetCharacterEquipId(self.CharacterId, index)
    if not equipId then
        return false
    end

    -- 强化页签
    if self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.STRENGTHEN then 
        local isMaxLevel = XMVCA.XEquip:IsMaxLevelAndBreakthrough(equipId)
        return not isMaxLevel

    -- 共鸣页签
    elseif self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE then  
        local canResonance = XMVCA.XEquip:CanResonance(equipId)
        return canResonance

    -- 超频页签
    elseif self.TabIndex == XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERCLOCKING then
        local canOverlocking = self:CheckCanOverclocking(equipId)
        return canOverlocking
    end

    return false
end

-- 刷新意识切换按钮
function XUiEquipDetailV2P6:UpdateAwarenessSwitchBtn()
    local isShow = not XLuaUiManager.IsUiShow("UiEquipResonanceSelectV2P6")
        and not XLuaUiManager.IsUiShow("UiEquipResonanceAwakeV2P6")
        and self.CharacterId and (XMVCA.XEquip:GetCharacterAwarenessCnt(self.CharacterId) > 1)
        and XMVCA.XEquip:IsEquipWearingByCharacterId(self.EquipId, self.CharacterId)
    
    self.PanelTab.gameObject:SetActiveEx(isShow)
    if not isShow then return end

    local canLast = false
    local canNext = false
    for index = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local canSwitch = self:CheckCanSwitchAwareness(index)
        if canSwitch then
            if index < self.SelectAwarenessIndex then
                canLast = true
            end
            if index > self.SelectAwarenessIndex then
                canNext = true
            end

            local state = index == self.SelectAwarenessIndex and CS.UiButtonState.Select or CS.UiButtonState.Normal
            self["BtnNumber" .. index]:SetButtonState(state)
        else
            self["BtnNumber" .. index]:SetButtonState(CS.UiButtonState.Disable)
        end
    end

    self.BtnLeft.gameObject:SetActiveEx(canLast)
    self.BtnRight.gameObject:SetActiveEx(canNext)
end

-- 检查是否可超频
function XUiEquipDetailV2P6:CheckCanOverclocking(equipId)
    if not XTool.IsNumberValid(equipId) then
        return
    end 
    for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
        if XMVCA.XEquip:CheckEquipCanAwake(equipId, pos) then
            return true
        end
    end

    return false
end
--------------------#endregion 意识 --------------------

--------------------#region 虚拟摄像机 --------------------
function XUiEquipDetailV2P6:InitVirtualCamera(root)
    -- VCDetail: 退出 UiEquipOverrunV4P6 时切换的虚拟相机，也是装备详情其他页签使用的虚拟相机
    -- VCOverrun: UiEquipOverrunV4P6 使用的默认虚拟相机
    -- VCOverrunLv1-7: 选中谐振等级 1-7 时显示的虚拟相机
    self.VCDetail = root:FindTransform("VCDetail")
    self.VCOverrun = root:FindTransform("VCOverrun")
    self.VCOverrunLvList = {}
    for i = 1, 7 do
        self.VCOverrunLvList[i] = root:FindTransform("VCOverrunLv" .. i)
    end
end

function XUiEquipDetailV2P6:SetVirtualCameraActive(virtualCamera, isActive)
    if not XTool.UObjIsNil(virtualCamera) then
        virtualCamera.gameObject:SetActiveEx(isActive)
    end
end

function XUiEquipDetailV2P6:CloseAllVirtualCamera()
    self:SetVirtualCameraActive(self.VCDetail, false)
    self:SetVirtualCameraActive(self.VCOverrun, false)
    for i = 1, 7 do
        self:SetVirtualCameraActive(self.VCOverrunLvList[i], false)
    end
end

-- 切换 UiEquipOverrunV4P6 内部相机；level 为空时使用超限页默认相机
function XUiEquipDetailV2P6:SwitchVirtualCamera(level, overrunCfg)
    self:CloseAllVirtualCamera()
    self:SetVirtualCameraActive(self.VCOverrun, level == nil)
    for i = 1, 7 do
        self:SetVirtualCameraActive(self.VCOverrunLvList[i], i == level)
    end
    if level ~= nil and overrunCfg then
        local vc = self.VCOverrunLvList[level]
        if not XTool.UObjIsNil(vc) then
            vc.localPosition    = CS.UnityEngine.Vector3(overrunCfg.SelectedCameraPosX, overrunCfg.SelectedCameraPosY, overrunCfg.SelectedCameraPosZ)
            vc.localEulerAngles = CS.UnityEngine.Vector3(overrunCfg.SelectedCameraRotX,  overrunCfg.SelectedCameraRotY,  overrunCfg.SelectedCameraRotZ)
        end
    end
end
--------------------#endregion 虚拟摄像机 --------------------

-- 退出 UiEquipOverrunV4P6 时切回装备详情其他页签使用的相机
function XUiEquipDetailV2P6:SwitchOverrunExitVirtualCamera()
    self:CloseAllVirtualCamera()
    self:SetVirtualCameraActive(self.VCDetail, true)
end

return XUiEquipDetailV2P6
