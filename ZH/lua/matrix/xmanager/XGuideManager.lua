XGuideManagerCreator = function()
    ---@class XGuideManager 引导管理类
    local XGuideManager = {}
    
    local IsRequireAgent = false        --是否require引导
    ---@type BehaviorTree.XAgent
    local GuideAgent = nil              --引导主体
    ---@type XTableGuideGroup
    local RunningGuideTemplate = false  --正在运行的引导配置
    local IsGuiding = false             --引导运行中   
    local IsOpenControl = false         -- 引导是否可以接受按键隐射，默认关闭
    local DisableFunctionFlag = 0      --功能屏蔽标记（调试模式时使用）
    --引导代理类型
    XGuideManager.ProxyType = {
        --基础内容
        Basic = 1,
        --空花
        SkyGarden = 2,
    }
    local ProxyUrl = {
        [XGuideManager.ProxyType.Basic] = "XGuide/Proxy/XBasicGuideProxy",
        [XGuideManager.ProxyType.SkyGarden] = "XGuide/Proxy/XSkyGardenGuideProxy",
    }
    local ProxyClass = {
        [XGuideManager.ProxyType.Basic] = false,
        [XGuideManager.ProxyType.SkyGarden] = false,
    }
    
    local CurrentProxyType = nil        --当前代理类型
    local LastProxyType = nil           --上一个代理类型
    ---@type table<number, number>
    local GuideData = nil               --已经完成的引导
    local ForceDisableGuide = nil       --强制禁用引导
    ---@type XGuideProxy
    local CurrentProxy = nil            --引导代理

    -- 埋点类型
    XGuideManager.BuryingPointType = {
        Start   = 1, --引导开始
        Skip    = 2, --引导跳过(确认脱离卡死)
        End     = 3, --引导结束
        FocusOn = 4, --聚焦Ui(交互开始)
        Trigger = 5, --触发脱离卡死
        Click   = 6, --点击脱离卡死
    }

    -- 引导类型
    XGuideManager.GuideType = {
        --系统
        Default = 1,
        --战斗
        Fight = 2,
    }

    XGuideManager.GuideDisableFlag = {
        --不屏蔽
        None = 1,
        --屏蔽全部
        All = 1 << 1 | 1 << 2,
        --屏蔽主干
        Trunk = 1 << 1,
        --屏蔽空花
        BigWorld = 1 << 2,
    }

    --引导跳过检测
    local SKIP_CHECK_UI_NAME = {
        UiAutoFightTip      = true,
        UiLeftPopupTip      = true,
        UiTipLayer          = true,
        UiNoticeTips        = true,
        UiAchievementTips   = true,
        UiPortraitTip       = true,
        UiFightNieRTips     = true,
        UiPartnerPopupTip   = true,
        UiRestaurantRadio   = true,
        UiLeftPopupTips     = true,
        UiRogueSimComponent = true,
        UiDormComponent     = true,
        UiGuildDormCommon   = true,
        UiSkyGardenShoppingStreetVideoRecording     = true,
        UiSkyGardenShoppingStreetGameTargetPopup    = true,
        UiBigWorldSetControllerTips     = true,
        UiBigWorldLoading               = true,
        UiBigWorldBlackMaskLoading      = true,
        UiBigWorldBlackMaskNormal       = true,
        UiBigWorldShowLoading           = true,
        UiDlcRelinkPopupInvitation      = true,
        UiDlcRelinkToastCommon          = true,
        UiDlcRelinkToastCommonSmall     = true,
    }
    local NextGridCb = nil
    local CbProxy = nil
    local IsDebugBuild = CS.XApplication.Debug
    
    --region 这一堆不知道干啥的先屏蔽了
    
    --[[
    -- 引导组记录状态
    XGuideManager.RecordState = {
        None = 0, --
        RequestRecord = 1, --请求记录中
        Record = 2, --已记录
    }
    
    -- 该事件类型包括了引导的触发、完成类型
    XGuideManager.GuideEventType = {
        TeamLevel            = 1, --战队等级：等级
        PassStage            = 2, --副本相关：副本id， 是否通关
        CompleteTask        = 3, --完成任务：任务id
        FunctionOpen        = 4, --功能开启：功能id
        GainCharacter        = 5, --获得角色：角色id
        GainEquip            = 6, --获得装备：装备id
        GainItem            = 7, --获得道具：道具id，数量
        CharacterUpgrade    = 8, --角色培养：角色id，等级，改造阶段， 晋升等级
        CharacterUpgradeSkill = 9, --角色技能：角色id， 技能id， 等级
        EquipUpgrade        = 10, --装备升级：装备id， 等级，突破次数，觉醒等级
        CompleteGuide        = 11, --完成引导：引导组id
        CompleteGuideStep    = 12, --完成步骤：步骤id
        OpenPanel            = 13, --打开界面：Ui名
        ClosePanel            = 14, --关闭界面：UI名
        ClickSpecify        = 15, --点击指定区域
    }

    XGuideManager.GroupOpenType = {
        FightTeamLevel = 1, --战队等级：等级
        PassStage    = 2, --通过副本：副本id
        FunctionOpen    = 3, --功能开启：功能id
        GainCharacter = 4, --获得角色：角色id
        GainEquip    = 5, --获得装备：装备id
        GainItem        = 6, --获得道具：道具id
        CompleteGuide = 7, --完成引导：引导组id
        CompleteTask    = 8, --完成任务：任务id
    }

    XGuideManager.GroupCompleteType = {
        CompleteStep        = 1, --步骤结束：步骤id
        Stage            = 2, --副本相关：副本id， 是否通关
        CompleteTask        = 3, --完成任务：任务id
        CharacterDevelop    = 4, --角色培养：角色id，等级，改造阶段， 晋升等级
        CharacterSkill    = 5, --角色技能：角色id， 技能id， 等级
        EquipUpgrade        = 6, --装备升级：装备id， 等级，突破次数，觉醒等级
        GainItem            = 7, --获得道具：道具id， 数量
        EquipPutOn        = 8, --穿装备：装备id
        UseItem            = 9, --使用道具：道具id，数量
        PartUpgrade        = 10, --部件升级：角色id，部件id，部件等级
        TeamChanged        = 11, --战斗编队
        CompleteCourse    = 12, --完成历程：副本id
        GainReward        = 13, --领取奖励 ：奖励ID
    }

    XGuideManager.StepOpenType = {
        OpenPanel    = 1, --打开界面：Ui名
        ClosePanel    = 2, --关闭界面：UI名
        CompleteStep    = 3, --完成步骤：步骤id
        GainItem        = 4, --获得道具：道具id
        CompleteTask    = 5, --完成任务：任务id
        CustomEvent    = 6, --自定义消息 ：参数
        GainReward    = 7, --领取奖励 ：奖励ID
    }

    XGuideManager.StepCompleteType = {
        DefaultClick    = 0, --默认：点击
        OpenPanel    = 1, --打开界面：UI名
        ClosePanel    = 2, --关闭界面：UI名
        GainItem        = 3, --获得道具：道具id
        CompleteTask    = 4, --完成任务：任务id
        CustomEvent    = 5, --自定义消息 ：参数
        GainReward    = 6, --领取奖励 ：奖励ID
    }
    --]]
    --endregion
    
    --region 引导流程
    
    function XGuideManager.Init()
        --监听登出
        XEventManager.AddEventListener(XEventId.EVENT_USER_LOGOUT, XGuideManager.HandleSignOut)
        XEventManager.AddEventListener(XEventId.EVENT_GUIDE_OPEN_CONTROL_EVENT, XGuideManager.SwitchOpenControlEvent)
        --XEventManager.AddEventListener(XEventId.EVENT_NETWORK_DISCONNECT, XGuideManager.HandleSignOut)
        --监听Ui打开
        CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_ALLOWOPERATE, function(evt, args)
            local index = 0
            ---@type XUi
            local xui = args[index]
            if not xui then
                return
            end
            local uiName = xui.UiData.UiName
            XGuideManager.HandleUiOpen(uiName)
        end)
        --监听引导开启
        CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_GUIDE_START, XGuideManager.OnGuideStart)
        --监听引导结束
        CsXGameEventManager.Instance:RegisterEvent(XEventId.EVENT_GUIDE_END, XGuideManager.OnGuideEnd)

        XGuideManager.InitDisableState()
    end
    
    function XGuideManager.InitDisableState()
        if IsDebugBuild then
            local state = XSaveTool.GetData(XPrefs.GuideTrigger)
            if state and type(state) == "number" then
                DisableFunctionFlag = state
            else
                DisableFunctionFlag = CS.XRemoteConfig.DisableGuide
            end
        else
            DisableFunctionFlag = CS.XRemoteConfig.DisableGuide
        end
    end
    
    --登录时初始化
    function XGuideManager.InitGuideData(finishGuideDataList)
        RunningGuideTemplate = false 
        ForceDisableGuide = false
        LastProxyType = nil
        CurrentProxyType = nil
        GuideData = {}
        if not XTool.IsTableEmpty(finishGuideDataList) then
            for _, guideId in pairs(finishGuideDataList) do
                GuideData[guideId] = guideId
            end
        end
        --登录时切换到基础引导类型
        XGuideManager.SwitchGuideProxy(XGuideManager.ProxyType.Basic)
    end
    
    --- 创建引导主体
    function XGuideManager.CreateAgent()
        if XGuideManager.IsAgentValid() then
            return
        end
        
        if not IsRequireAgent then
            require("XGuide/Agent/XGuideAgent")
        end
        IsRequireAgent = true
        
        ---@type UnityEngine.GameObject
        local gameObject = CS.UnityEngine.GameObject("GuideAgent")
        --进入战斗后会销毁NormalScene, 所以放到DonDestroyOnLoad场景中,由引导统一控制
        CS.UnityEngine.Object.DontDestroyOnLoad(gameObject)
        
        GuideAgent = gameObject:AddComponent(typeof(CS.BehaviorTree.XAgent))
        GuideAgent.ProxyType = "Guide"
        GuideAgent:InitProxy()
    end
    
    --重载引导配置 即使重载资源 Agent还是会引用旧的内存 所以会不生效
    function XGuideManager.ReloadAgent()
        if XGuideManager.IsAgentValid() then
            XUiHelper.Destroy(GuideAgent.gameObject)
            GuideAgent = nil
        end
    end
    
    --重置引导
    function XGuideManager.ResetGuide()
        if XGuideManager.IsAgentValid() then
            GuideAgent.gameObject:SetActiveEx(false)

            if GuideAgent.Proxy.LuaAgentProxy then
                GuideAgent.Proxy.LuaAgentProxy.UiGuide = nil
            end
        end
        IsGuiding = false
        RunningGuideTemplate = false
        XLuaUiManager.Close("UiGuide")
        if CurrentProxy then
            CurrentProxy:OnGuideReset()
        end
    end
    
    function XGuideManager.HandleSignOut()
        XGuideManager.ReloadAgent()
    end
    
    ---- UI打开时检测引导开启
    ---@param uiName string UiName
    function XGuideManager.HandleUiOpen(uiName)
        --引导还在跑
        if XGuideManager.CheckIsInGuide() or not CurrentProxy then
            return false
        end
        
        if XUiManager.IsHideFunc or ForceDisableGuide or CurrentProxy:CheckDisableGuide()
                or not XLoginManager.IsStartGuide() then
            return false
        end

        if CurrentProxy:IsIntercept() then
            return false
        end
        
        local guideList = CurrentProxy:FindActiveGuide()
        if XTool.IsTableEmpty(guideList) then
            return false
        end

        local active = false
        for _, guideTemplate in ipairs(guideList) do
            local activeUis = string.Split(guideTemplate.ActiveUi, '|')
            for _, activeUiName in pairs(activeUis) do
                if activeUiName == uiName then
                    active = true
                    break
                end
            end

            if active and XGuideManager.TryActiveGuide(guideTemplate, true) then
                break
            end
        end
        return active
    end
    
    --- 检测当前界面能否有引导触发
    function XGuideManager.CheckGuideOpen()
        if XGuideManager.CheckIsInGuide() then
            return true
        end
        if not CurrentProxy then
            return false
        end
        if CurrentProxy:CheckDisableGuide() or ForceDisableGuide or XUiManager.IsHideFunc then
            return false
        end
        local guideList = CurrentProxy:FindActiveGuide()
        if XTool.IsTableEmpty(guideList) then
            return false
        end
        local active = false
        for _, guideTemplate in ipairs(guideList) do
            if XGuideManager.TryActiveGuide(guideTemplate) then
                active = true
                break
            end
        end
        return active
    end
    
    ---- 尝试启动引导
    ---@param guideTemplate XTableGuideGroup
    function XGuideManager.TryActiveGuide(guideTemplate, isUiOpen)
        if not guideTemplate then
            return false
        end
        --关闭
        if XUiManager.IsHideFunc or ForceDisableGuide or not XLoginManager.IsStartGuide() then
            return false
        end
        --只触发默认类型引导
        if guideTemplate.GuideType ~= XGuideManager.GuideType.Default then
            return false
        end
        
        local active = false
        --栈顶UiName
        local uiName = CurrentProxy:GetTopUiName(SKIP_CHECK_UI_NAME)
        local activeUis = string.Split(guideTemplate.ActiveUi, '|')
        if not XTool.IsTableEmpty(activeUis) then
            for _, achieveUi in pairs(activeUis) do
                --当前Ui正在展示 && 处于栈顶
                if uiName == achieveUi and CsXUiManager.Instance:IsUiShow(achieveUi) then
                    local ui = XUiManager.GetTopUi(achieveUi)
                    local checkNodes = string.Split(guideTemplate.CheckNodeActive, '|')
                    if XGuideManager.CheckTopUiNodeActive(ui, checkNodes) then
                        active = true
                        break
                    end
                end
            end
        end
        
        if not active then
            return false
        end
        
        --RunningGuideTemplate = guideTemplate
        --XGuideManager.PlayGuide(guideTemplate.Id)
        CurrentProxy:ExecuteGuide(guideTemplate, isUiOpen)
        return true
    end
    
    --- 切换引导的代理
    ---@param proxyType number 代理类型
    function XGuideManager.SwitchGuideProxy(proxyType)
        if CurrentProxyType == proxyType then
            return
        end
        LastProxyType = CurrentProxyType
        CurrentProxyType = proxyType
        --清空上一个引导
        if CurrentProxy then
            CurrentProxy:InActive()
        end
        local proxyClass = ProxyClass[proxyType]
        if not proxyClass then
            proxyClass = require(ProxyUrl[proxyType])
            ProxyClass[proxyType] = proxyClass
        end
        CurrentProxy = proxyClass.New(DisableFunctionFlag)
        CurrentProxy:Active()
    end

    --- 恢复上一个代理
    function XGuideManager.RevertGuideProxy()
        if not XLoginManager.IsLogin() then
            LastProxyType = nil
            CurrentProxyType = nil
            CurrentProxy = nil
            return
        end
        if not LastProxyType then
            XLog.Warning("复原上一个引导代理异常!!!")
            return
        end
        XGuideManager.SwitchGuideProxy(LastProxyType)
    end
    
    --启动引导
    function XGuideManager.PlayGuide(guideId)
        if not XGuideManager.IsAgentValid() then
            XGuideManager.CreateAgent()
        end
        GuideAgent.gameObject:SetActiveEx(true)
        XLuaBehaviorManager.PlayId(guideId, GuideAgent)
        XEventManager.DispatchEvent(XEventId.EVENT_GUIDE_BEGIN_PLAY)
    end
    
    ---@param template XTableGuideGroup
    function XGuideManager.ExecuteGuide(template)
        if not template then
            XLog.Error("执行引导失败!")
        end
        RunningGuideTemplate = template
        XGuideManager.PlayGuide(template.Id)
    end
    
    function XGuideManager.OnGuideStart()
        IsGuiding = true
        XGuideManager.RecordBuryingPoint(XGuideManager.BuryingPointType.Start)
        CurrentProxy:OnGuideStart()
    end
    
    function XGuideManager.OnGuideEnd()
        IsOpenControl = false
        CurrentProxy:OnGuideEnd()
        XGuideManager.RecordBuryingPoint(XGuideManager.BuryingPointType.End)
        XGuideManager.ResetGuide()
        XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
    end

    --endregion
    
    --region Getter And Setter
    
    --- 满足游戏内某些界面禁用引导所需接口
    ---@param isDisable boolean
    function XGuideManager.SetDisableGuide(isDisable)
        ForceDisableGuide = isDisable
    end
    
    function XGuideManager.CheckFuncDisable()
        return (CurrentProxy and CurrentProxy:CheckDisableGuide())
    end
    
    function XGuideManager.CheckFuncDisableWithState(state)
        return (state & DisableFunctionFlag) ~= 0
    end
    
    function XGuideManager.ChangeFuncDisable(flag)
        DisableFunctionFlag = flag
        if IsDebugBuild then
            XSaveTool.SaveData(XPrefs.GuideTrigger, flag)
        end
        if CurrentProxy then
            CurrentProxy:ChangeDisableGuide(flag)
        end
    end
    
    function XGuideManager.AddFuncDisableFlag(flag)
        DisableFunctionFlag = DisableFunctionFlag | flag
        if IsDebugBuild then
            XSaveTool.SaveData(XPrefs.GuideTrigger, DisableFunctionFlag)
        end
        if CurrentProxy then
            CurrentProxy:ChangeDisableGuide(DisableFunctionFlag)
        end
    end
    
    function XGuideManager.SubFuncDisableFlag(flag)
        DisableFunctionFlag = DisableFunctionFlag & (~flag)
        if IsDebugBuild then
            XSaveTool.SaveData(XPrefs.GuideTrigger, DisableFunctionFlag)
        end
        if CurrentProxy then
            CurrentProxy:ChangeDisableGuide(DisableFunctionFlag)
        end
    end
    
    function XGuideManager.GetDisableState()
        return DisableFunctionFlag
    end
    
    function XGuideManager.IsAgentValid()
        return GuideAgent and GuideAgent:Exist()
    end
    
    --- 引导是否已经完成
    ---@param guideId number
    ---@return boolean
    function XGuideManager.CheckIsGuide(guideId)
        if XTool.IsTableEmpty(GuideData) then
            return
        end
        return GuideData[guideId] ~= nil
    end
    
    --- 是否处于引导流程中
    ---@return boolean
    function XGuideManager.CheckIsInGuide()
        return IsGuiding and RunningGuideTemplate ~= nil
    end

    function XGuideManager.GetIsOpenControl()
        return IsOpenControl
    end

    function XGuideManager.SwitchOpenControlEvent(argsStr)
        IsOpenControl = argsStr == "1"
    end
    
    ---@return XTableGuideGroup
    function XGuideManager.GetGuideGroupTemplatesById(guideId)
        if not CurrentProxy then
            XLog.Error("获取引导配置异常, 当前无引导代理")
            return XGuideConfig.GetGuideGroupTemplatesById(guideId)
        end
        return CurrentProxy:GetGuideGroupTemplate(guideId)
    end

    ---@return XTableGuideComplete
    function XGuideManager.GetGuideCompleteTemplatesById(completeId)
        if not CurrentProxy then
            XLog.Error("获取引导配置异常, 当前无引导代理")
            return XGuideConfig.GetGuideCompleteTemplatesById(completeId)
        end
        return CurrentProxy:GetGuideCompleteTemplate(completeId)
    end

    ---@return string
    function XGuideManager.GetGuideIcon(iconId)
        if not CurrentProxy then
            XLog.Error("获取引导配置异常, 当前无引导代理")
            return XGuideConfig.GetGuideIcon(iconId)
        end
        return CurrentProxy:GetGuideIcon(iconId)
    end

    ---@return XTableGuideText
    function XGuideManager.GetGuideTextTemplate(textId)
        if not CurrentProxy then
            XLog.Error("获取引导配置异常, 当前无引导代理")
            return XGuideConfig.GetGuideTextTemplate(textId)
        end
        return CurrentProxy:GetGuideTextTemplate(textId)
    end
    
    --endregion
    
    --region 战斗引导

    --是否是战斗引导
    function XGuideManager.CheckIsFightGuide()
        if RunningGuideTemplate and RunningGuideTemplate.GuideType == XGuideManager.GuideType.Fight then
            return true
        end

        return false
    end

    function XGuideManager.GetNextGuideFight()
        if not CurrentProxy then
            return false
        end
        
        if CurrentProxy:CheckDisableGuide() or ForceDisableGuide or XGuideManager.CheckIsInGuide() then
            return false
        end


        local guideList = CurrentProxy:FindActiveGuide()
        if XTool.IsTableEmpty(guideList) then
            return false
        end 

        local result = nil
        for _, guideTemplate in ipairs(guideList) do
            if guideTemplate.GuideType == XGuideManager.GuideType.Fight then
                local cfg = XGuideConfig.GetGuideFightTemplatesById(guideTemplate.Id)
                if cfg then
                    result = cfg
                    break
                end
            end
        end
        
        return result
    end

    --c#-调用
    function XGuideManager.IsPrologueFight()
        local result = XGuideManager.GetNextGuideFight()
        if not result then
            return false
        end
        return result ~= nil
    end
    --endregion
    
    --region 埋点
    
    -- 记录埋点
    function XGuideManager.RecordBuryingPoint(buryingPointType, nodeIds)
        if not RunningGuideTemplate or not IsGuiding then
            return
        end
        -- 无节点Id
        if not nodeIds then
            nodeIds = {}
        end
        -- 确认脱离卡死时 获取正在执行的节点Ids
        if buryingPointType == XGuideManager.BuryingPointType.Skip and XGuideManager.IsAgentValid() then
            local tempNodeIds = GuideAgent:GetRunningNodeIds()
            if tempNodeIds then
                nodeIds = XTool.CsList2LuaTable(tempNodeIds)
            end
        end
        local dict = {}
        dict["role_id"] = XPlayer.Id
        dict["role_level"] = XPlayer.GetLevel()
        dict["guide_id"] = RunningGuideTemplate.Id
        dict["node_ids"] = table.concat(nodeIds, ",")
        dict["ui_name"] = XLuaUiManager.GetTopUiName()
        dict["type"] = buryingPointType
        CS.XRecord.Record(dict, "200014", "Guide")
    end
    --endregion
    
    --region Util

    --- 检查Ui的节点是否显示
    ---@param luaUi XLuaUi UI类 
    ---@param nodes string[]|string
    ---@return boolean
    --------------------------
    function XGuideManager.CheckTopUiNodeActive(luaUi, nodes)
        if not luaUi then
            return false
        end
        
        --没有需要检查的节点，默认通过
        if XTool.IsTableEmpty(nodes) or string.IsNilOrEmpty(nodes) then
            return true
        end
        for _, node in ipairs(nodes) do
            --根据名称查找, 这个接口找不到会返回lua.Transform 还需要判断节点名
            local tmp = luaUi.Transform:FindActiveTransformWithSplit(node)
            if not XTool.UObjIsNil(tmp) and tmp.gameObject.activeInHierarchy and tmp.name == node then
                return true
            end
        end
        return false
    end

    -- V1.30 新动态列表(大量动画)兼容相关
    function XGuideManager.SetGridNextCb(cb, proxy)
        -- 设置侧边栏点击回调（因为指引会截断侧边栏滚动结束的函数，所以提前存储结束后的函数，在指引点击的时候就调用）
        NextGridCb = cb
        CbProxy = proxy
    end

    function XGuideManager.GetGridNextCb(cb, proxy)
        return NextGridCb
    end

    function XGuideManager.DoNextGridCb(...)
        if NextGridCb and CbProxy then
            NextGridCb(CbProxy, ...)
        end
    end
    
    function XGuideManager.TriggerUnlockBigWorldTeach(guideId)
        if not XMVCA.XBigWorldGamePlay:IsInGame() then
            return
        end
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_HELP_COURSE_UNLOCK_TRIGGER, 
                XEnumConst.BWHelpCourse.UnlockTriggerType.GuideFinish, guideId)
    end
    --endregion
    
    --region 协议
    
    function XGuideManager.OnSyncGuideData(guideId)
        GuideData[guideId] = guideId
        XGuideManager.TriggerUnlockBigWorldTeach(guideId)
        if RunningGuideTemplate and RunningGuideTemplate.Id == guideId 
                and RunningGuideTemplate.GuideType ~= XGuideManager.GuideType.Default then
            XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUIDE_COMPLETED_SUCCESS, guideId)
    end
    
    function XGuideManager.OnSyncGuideGroupData(groupId)
        if CurrentProxy then
            local templates = CurrentProxy:GetAllGuideGroupTemplate()
            for guideId, template in pairs(templates) do
                if template.GroupId == groupId then
                    GuideData[guideId] = guideId
                    XGuideManager.TriggerUnlockBigWorldTeach(guideId)
                end
            end
        else
            XLog.Error("同步数据失败,不存在引导代理!")
        end
        if RunningGuideTemplate
                and RunningGuideTemplate.GuideType ~= XGuideManager.GuideType.Default then
            XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_GUIDE_COMPLETED_SUCCESS)
    end
    
    --- 引导开始
    ---@param guideId number
    function XGuideManager.ReqGuideOpen(guideId, cb)
        XNetwork.Call("GuideOpenRequest", { GuideGroupId = guideId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
            end

            if cb then cb() end
        end)
    end
    
    --- 引导完成
    ---@param guideId number
    function XGuideManager.ReqGuideComplete(guideId, cb)
        local orginalGuideId = guideId
        guideId = tonumber(guideId)
        if guideId == nil then
            XLog.Error("引导完成失败, guideId有问题: " .. tostring(orginalGuideId))
            return
        end
        XNetwork.Call("GuideCompleteRequest", { GuideGroupId = guideId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
            else
                if res.RewardGoodsList then
                    if CurrentProxy then
                        CurrentProxy:OpenUiObtain(res.RewardGoodsList)
                    else
                        XUiManager.OpenUiObtain(res.RewardGoodsList)
                    end
                end
                
                XGuideManager.OnSyncGuideData(guideId)
            end

            if cb then cb() end
        end)
    end

    function XGuideManager.ReqMultiGuideComplete(guideIds, cb)
        if XTool.IsTableEmpty(guideIds) then
            if cb then
                cb()
            end
            return
        end

        local total, cur = #guideIds, 0
        for _, guideId in pairs(guideIds) do
            XGuideManager.ReqGuideComplete(guideId, function()
                cur = cur + 1
                if cur >= total and cb then
                    cb()
                end
            end)
        end
    end
    
    --- 当前引导组完成
    function XGuideManager.ReqCompleteGuideGroup(cb)
        if not RunningGuideTemplate or not CurrentProxy then
            if cb then cb() end
            return
        end
        local groupId = RunningGuideTemplate.GroupId
        XNetwork.Call("GuideGroupFinishRequest", { GroupId = groupId }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
            else
                if res.RewardGoodsList then
                    if CurrentProxy then
                        CurrentProxy:OpenUiObtain(res.RewardGoodsList)
                    else
                        XUiManager.OpenUiObtain(res.RewardGoodsList)
                    end
                end
                XGuideManager.OnSyncGuideGroupData(groupId)
            end

            if cb then cb() end
        end)
    end
    
    --endregion
    

    XGuideManager.Init()
    
    return XGuideManager
end

XRpc.NotifyGuide = function(data)
    XDataCenter.GuideManager.OnSyncGuideData(data.GuideGroupId)
end