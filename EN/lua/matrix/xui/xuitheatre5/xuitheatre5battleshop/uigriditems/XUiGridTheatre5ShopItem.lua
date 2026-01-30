local XUiGridTheatre5Item = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Item')
--- 物品类
---@class XUiGridTheatre5ShopItem: XUiGridTheatre5Item
---@field private _Control XTheatre5Control
local XUiGridTheatre5ShopItem = XClass(XUiGridTheatre5Item, 'XUiGridTheatre5ShopItem')

local DragMoveLimit = nil
local Vector3Cache = Vector3.zero
local UNITY = CS.UnityEngine

function XUiGridTheatre5ShopItem:OnStart()
    XUiGridTheatre5Item.OnStart(self)
    
    self.ContainerObj = self.Parent.GameObject
    self.DefaultLocalPosition = self.Transform.localPosition
    self.DefaultSiblingIndex = self.Transform:GetSiblingIndex()
    
    self._AfterEndDragCallBackHandler = handler(self, self._AfterEndDragCallBack)
end

function XUiGridTheatre5ShopItem:OnEnable()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CHECK_AND_FIX_DRAGGING_STATE, self.TryFixDragError, self)
end

function XUiGridTheatre5ShopItem:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CHECK_AND_FIX_DRAGGING_STATE, self.TryFixDragError, self)

    self:RemoveDraggingEvent()
    self:StopEndDragErrorCheckTimer()
end

---@overload
function XUiGridTheatre5ShopItem:OnGridBtnClickEvent()
    if self._Control.ShopControl:GetIsDraggingItem() then
        return
    end
    
    XUiGridTheatre5Item.OnGridBtnClickEvent(self)
end

--region 商店拖拽

function XUiGridTheatre5ShopItem:InitDrag()
    if DragMoveLimit == nil or XMain.IsEditorDebug then
        DragMoveLimit = self._Control.ShopControl:GetTheatre5ItemDragLimitFromClientConfig()
    end
    
    -- 物品需要支持拖拽
    ---@type XGoInputHandler
    self.UiDragCom = self.GameObject:AddComponent(typeof(CS.XGoInputHandler))
    self.UiDragCom:AddBeginDragListener(handler(self, self.OnBeginDrag))
    self.UiDragCom:AddDragListener(handler(self, self.OnDragging))
    self.UiDragCom:AddEndDragListener(handler(self, self.OnEndDrag))
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridTheatre5ShopItem:OnBeginDrag(eventData)
    if self._IsOnEndDrag or self._IsDragging then
        if XMain.IsEditorDebug then
            XLog.Debug('[仅Debug模式输出]触发OnBeginDrag，当状态缓存 _IsOnEndDrag: '..tostring(self._IsOnEndDrag)..' ;_IsDragging: '..tostring(self._IsDragging)..' 时')
        end
        -- 如果字段正在拖拽
        if self._Control.ShopControl:GetIsDraggingItem() then
            if self._Control.ShopControl:CheckIsSameItem(self.ItemData) then
                if XMain.IsEditorDebug then
                    XLog.Debug('[仅Debug模式输出]缓存中正在拖拽的数据与该UI携带的数据一致')
                end
                return
            end
        end
    end
    
    -- 缓存拖拽起点屏幕坐标
    self._BeginScreenPos = eventData.position
    self._IsDragging = false
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridTheatre5ShopItem:OnDragging(eventData)
    if self:_CheckIsCanDrag(eventData) then
        -- 取消选择，关闭详情界面
        if self.IsSelected then
            self:OnGridBtnClickEvent()
        else
            self._Control:SetItemSelected(nil)
            self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
        end
        
        -- 同步鼠标位置
        self.Transform.localPosition = self:_GetPosByEventData(eventData)
        
        -- 刷新标签显示
        if self.RawImgSelectNo then
            self.RawImgSelectNo.gameObject:SetActiveEx(not self._Control.ShopControl:CheckDraggingItemIsFitInContainer())
        end
    end
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridTheatre5ShopItem:OnEndDrag(eventData)
    self._IsOnEndDrag = true
    
    self:StopEndDragErrorCheckTimer()
    
    if self.CanvasGroup then
        self.CanvasGroup.blocksRaycasts = true
    end

    if self.RawImgSelectNo then
        self.RawImgSelectNo.gameObject:SetActiveEx(false)
    end
    
    -- 如果该物品没有被真的拖拽，则不处理数据
    if not self._IsDragging then
        return
    end

    self._IsDragging = false
    
    if not self._Control.ShopControl:OnEndDragging(self._AfterEndDragCallBackHandler) then
        self._AfterEndDragCallBackHandler()
    end

    self._IsOnEndDrag = false
end

function XUiGridTheatre5ShopItem:_AfterEndDragCallBack(opType)
    if opType == XMVCA.XTheatre5.EnumConst.ShopOperationType.SellGem then
        -- 卖掉宝珠，需要显示特效
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_GEM_SELLOUT_EFFECT_SHOW, self.Transform.position)
    end
    
    -- 假拖拽，即结束拖拽后始终返回原位置
    self.Transform:SetParent(self.ContainerObj.transform)
    self.Transform.localPosition = self.DefaultLocalPosition
    self.Transform:SetSiblingIndex(self.DefaultSiblingIndex)

    self._Control.ShopControl:SetDraggingItemData(nil)

    -- 关闭商店遮罩
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_FULLSHOPAREA_SHOW_STATE, false)

    -- 隐藏售出图标
    self.PanelSellPrice.gameObject:SetActiveEx(false)

    -- 移除拖拽过程中的进入和退出商店区域的事件监听
    self:RemoveDraggingEvent()
end


function XUiGridTheatre5ShopItem:RemoveDraggingEvent()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_ENTER_FULLSHOPAREA, self.OnFullShopEnterEvent, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_EXIT_FULLSHOPAREA, self.OnFullShopExitEvent, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_APPLICATION_PAUSE, self.OnApplicationPauseEvent, self)
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridTheatre5ShopItem:_GetPosByEventData(eventData)
    ---@type UnityEngine.RectTransform
    local transform = self.Transform.parent.transform
    local hasValue, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not hasValue then
        return -99999, -99999
    end

    Vector3Cache.x = point.x
    Vector3Cache.y = point.y
    
    return Vector3Cache
end

--- 检查是否满足拖拽
function XUiGridTheatre5ShopItem:_CheckIsCanDrag(eventData)
    if not self._IsDragging then
        -- 如果已经有正在拖拽的了则不能再拖
        if self._Control.ShopControl:GetIsDraggingItem() then
            return false
        end
        
        if Vector2.Distance(self._BeginScreenPos, eventData.position) > DragMoveLimit then
            self._IsDragging = true

            if self.CanvasGroup then
                self.CanvasGroup.blocksRaycasts = false
            end
            
            -- 执行开始拖拽的初始化
            
            -- 取消选择，关闭详情界面
            if self.IsSelected then
                self:OnGridBtnClickEvent()
            end

            -- 设置到拖拽节点
            self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SET_ITEM_TO_DRAGGINGROOT, self)
            
            -- 缓存
            self._Control.ShopControl:SetDraggingItemData(self.ItemData, self.OwnerContainerType, self.BelongIndex)

            -- 打开商店遮罩
            self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_FULLSHOPAREA_SHOW_STATE, true)

            -- 添加进入和退出商店区域的事件监听
            self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_ENTER_FULLSHOPAREA, self.OnFullShopEnterEvent, self)
            self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_EXIT_FULLSHOPAREA, self.OnFullShopExitEvent, self)
            
            -- 添加应用切后台的监听
            XEventManager.AddEventListener(XEventId.EVENT_APPLICATION_PAUSE, self.OnApplicationPauseEvent, self)
            
            -- 添加保底逻辑定时器
            self:StopEndDragErrorCheckTimer()
            self.EndErrorCheckTimeId = XScheduleManager.ScheduleForever(handler(self, self.EndDragErrorCheckTimer), 0)
            
            return true
        end
    else
        return true
    end
    
    return false
end

function XUiGridTheatre5ShopItem:OnFullShopEnterEvent()
    if self.OwnerContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.Goods and self.OwnerContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillSelection then
        self.PanelSellPrice.gameObject:SetActiveEx(true)

        -- 技能显示“废弃”
        if self.ItemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
            self.TxtSellNum.text = self._Control.ShopControl:GetClientConfigSellSkillLabel()
        else
            ---@type XTableTheatre5Item
            local cfg = self._Control:GetTheatre5ItemCfgById(self.ItemData.ItemId)

            if cfg and self.TxtSellNum then
                local content = string.gsub(self._Control.ShopControl:GetClientConfigSellItemWithPriceShow(), '\\', '')
                self.TxtSellNum.text = XUiHelper.FormatText(content, cfg.SellPrice)
            end
        end
    end
end

function XUiGridTheatre5ShopItem:OnFullShopExitEvent()
    if self.OwnerContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.Goods and self.OwnerContainerType ~= XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillSelection then
        self.PanelSellPrice.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre5ShopItem:OnApplicationPauseEvent(isPause)
    self._IsDragging = false

    if self.CanvasGroup then
        self.CanvasGroup.blocksRaycasts = true
    end
    
    self:_AfterEndDragCallBack()

    if self.RawImgSelectNo then
        self.RawImgSelectNo.gameObject:SetActiveEx(false)
    end
    
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CANCEL_CONTAINERS_FOCUS, isPause)
end

--- 保底逻辑，检查当未拖拽，且OnEndDrag未触发时手动触发
function XUiGridTheatre5ShopItem:EndDragErrorCheckTimer()
    if self._IsDragging then
        if UNITY.Input.GetMouseButtonUp(0) or (UNITY.Input.touchCount > 0 and UNITY.Input.GetTouch(0).phase == UNITY.TouchPhase.Ended) then
            if XMain.IsEditorDebug then
                XLog.Debug('触发拖拽结束的保底逻辑')
            end
            self:OnEndDrag(nil)
            self:StopEndDragErrorCheckTimer()
        end
    end
end

function XUiGridTheatre5ShopItem:StopEndDragErrorCheckTimer()
    if self.EndErrorCheckTimeId then
        XScheduleManager.UnSchedule(self.EndErrorCheckTimeId)
        self.EndErrorCheckTimeId = nil
    end
end

--- 保底逻辑：检查当前是否卡缓存了
function XUiGridTheatre5ShopItem:TryFixDragError()
    local needFix = false
    
    -- 先检查是否卡缓存
    if self._Control.ShopControl:CheckIsSameItem(self.ItemData) or self._IsDragging then
        needFix = true
        if XMain.IsEditorDebug then
            XLog.Debug('[仅Debug模式输出]触发检查缓存状态异常，当状态缓存 SameDraggingData: '..tostring(self._Control.ShopControl:CheckIsSameItem(self.ItemData))..' ;_IsDragging: '..tostring(self._IsDragging)..' 时')
        end
    end
    
    -- 再检查是否UI卡状态
    if self.Transform.parent.gameObject ~= self.ContainerObj or self.Transform.localPosition ~= self.DefaultLocalPosition then
        needFix = true
        if XMain.IsEditorDebug then
            XLog.Debug('[仅Debug模式输出]触发检查UI状态异常')
        end
    end

    if needFix then
        self:OnApplicationPauseEvent(false)
        if XMain.IsEditorDebug then
            XLog.Debug('[仅Debug模式输出]尝试修复状态')
        end
    end
end
--endregion

return XUiGridTheatre5ShopItem