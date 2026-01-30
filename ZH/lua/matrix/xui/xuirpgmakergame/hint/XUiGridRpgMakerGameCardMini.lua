local XUiGridRpgMakerGameCardMini = XClass(nil, "XUiGridRpgMakerGameCardMini")

local Vector2 = CS.UnityEngine.Vector2
local Vector3 = CS.UnityEngine.Vector3
local LookRotation = CS.UnityEngine.Quaternion.LookRotation
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

--提示说明地图上节点的小图标
function XUiGridRpgMakerGameCardMini:Ctor(ui, uiRoot)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.UiRoot = uiRoot

    XTool.InitUiObject(self)
    self.ImageLineMap = {}
    self.ImageLine.gameObject:SetActiveEx(false)
    self.ImageFirstLineBg.gameObject:SetActiveEx(false)
end

function XUiGridRpgMakerGameCardMini:Refresh(row, colIndex, colDataList, mapId, isNotShowLine)
    -- local row = XRpgMakerGameConfigs.GetRpgMakerGameBlockRow(blockId)
    -- local isBlock = blockStatus == XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameBlockStatus.Block
    -- local monsterId = XRpgMakerGameConfigs.GetRpgMakerGameMonsterId(mapId, colIndex, row)
    -- local isStartPoint = XRpgMakerGameConfigs.IsRpgMakerGameStartPoint(mapId, colIndex, row)
    -- local isEndPoint = XRpgMakerGameConfigs.IsRpgMakerGameEndPoint(mapId, colIndex, row)
    -- local triggerId = XRpgMakerGameConfigs.GetRpgMakerGameTriggerId(mapId, colIndex, row)
    -- local shadowId = XRpgMakerGameConfigs.GetRpgMakerGameShadowId(mapId, colIndex, row)
    -- local trapId = XRpgMakerGameConfigs.GetRpgMakerGameTrapId(mapId, colIndex, row)
    -- local transferPointId = XRpgMakerGameConfigs.GetRpgMakerGameTransferPointId(mapId, colIndex, row)
    -- local entityTypeList = XRpgMakerGameConfigs.GetRpgMakerGameEntityTypeListByXY(mapId, colIndex, row)

    local isBlock = XRpgMakerGameConfigs.GetMixBlockInPositionByType(mapId, colIndex, row, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.BlockType)
    local monsterId = XRpgMakerGameConfigs.GetMixBlockInPositionByType(mapId, colIndex, row, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Monster)
    local isStartPoint = XRpgMakerGameConfigs.GetMixBlockInPositionByType(mapId, colIndex, row, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.StartPoint)
    local isEndPoint = XRpgMakerGameConfigs.GetMixBlockInPositionByType(mapId, colIndex, row, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.EndPoint)
    local triggerId = XRpgMakerGameConfigs.GetMixBlockInPositionByType(mapId, colIndex, row, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Trigger)
    local shadowId = XRpgMakerGameConfigs.GetMixBlockInPositionByType(mapId, colIndex, row, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Shadow)
    local trapId = XRpgMakerGameConfigs.GetMixBlockInPositionByType(mapId, colIndex, row, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Trap)
    local transferPointId = XRpgMakerGameConfigs.GetMixBlockInPositionByType(mapId, colIndex, row, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.TransferPoint)

    local bubble = XRpgMakerGameConfigs.GetMixBlockInPositionByType(mapId, colIndex, row, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Bubble)
    local drop = XRpgMakerGameConfigs.GetMixBlockInPositionByType(mapId, colIndex, row, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Drop)
    local magic = XRpgMakerGameConfigs.GetMixBlockInPositionByType(mapId, colIndex, row, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Magic)
    local switchMagic = XRpgMakerGameConfigs.GetMixBlockInPositionByType(mapId, colIndex, row, XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.SwitchSkillType)

    local entityTypeList = XRpgMakerGameConfigs.GetEntityInPositionByType(mapId, colIndex, row)
    local sameXYGapIdList = XRpgMakerGameConfigs.GetGapInPositionByType(mapId, colIndex, row)
    local sameXYElectricFenceIdList = XRpgMakerGameConfigs.GetElectricFenceInPositionByType(mapId, colIndex, row)

    --设置移动路线
    if not isNotShowLine then
        local lineParams = self.UiRoot:GetHintLineMapParams(row, colIndex)
        for i, param in ipairs(lineParams or {}) do
            local isStart = param.IsStart                   --是否是起点
            local widthPercent = param.WidthPercent         --格子宽度百分比，用来计算线在格子中的起始位置，左下角为原点
            local heightPercent = param.HeightPercent       --格子高度百分比，用来计算线在格子中的起始位置，左下角为原点
            local direction = param.Direction               --箭头方向
            local id = param.Id
            local endWidthPercent = param.EndWidthPercent      --格子宽度百分比，用来计算线在格子中的终点位置
            local endHeightPercent = param.EndHeightPercent    --格子高度百分比，用来计算线在格子中的终点位置

            local imgLine = CSUnityEngineObjectInstantiate(self.ImageLine, self.Transform)
            self.ImageLineMap[id] = imgLine

            if isStart then
                imgLine.color = XUiHelper.Hexcolor2Color("21f480")
            end

            --设置线段的起点坐标
            local size = self.Transform:GetComponent("RectTransform").rect.size
            local startPosX = size.x * widthPercent
            local startPoxY = size.y * heightPercent

            --设置线段的终点坐标
            local imgLineHeight = imgLine.rectTransform.rect.height
            local endPosX = size.x * endWidthPercent
            local endPosY = size.y * endHeightPercent

            --设置线段的方向
            local originPos = imgLine.transform.localPosition
            local directionPos = self:GetDirectionPos(originPos, direction)
            if directionPos then
                imgLine.transform.right = directionPos - originPos
            end

            --设置线段的长度
            local imgLineWidth = math.sqrt((endPosY - startPoxY) ^ 2 + (endPosX - startPosX) ^ 2)
            imgLine.rectTransform.anchorMin = Vector2(0, 0)
            imgLine.rectTransform.anchorMax = Vector2(0, 0)
            imgLine.rectTransform.pivot = Vector2(0, 0.5)
            imgLine.rectTransform.sizeDelta = Vector2(math.abs(imgLineWidth), imgLineHeight)

            --设置线段起始点的坐标
            imgLine.transform.anchoredPosition = Vector2(startPosX, startPoxY)

            imgLine.gameObject:SetActiveEx(true)
        end
    end

    -- 图标key队列
    local coverIconKeyList = {}
    if isBlock then
        table.insert(coverIconKeyList, XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.BlockIcon)
    elseif monsterId then
        local id = monsterId:GetParams()[1]
        local monsterType = XMVCA.XRpgMakerGame:GetConfig():GetMonsterType(id)
        local skillType = XMVCA.XRpgMakerGame:GetConfig():GetMonsterSkillType(id)
        table.insert(coverIconKeyList, XRpgMakerGameConfigs.GetMonsterIconKey(monsterType, skillType))
    elseif isStartPoint then
        table.insert(coverIconKeyList, XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.StartPointIcon)
    elseif isEndPoint then
        table.insert(coverIconKeyList, XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.EndPointIcon)
    elseif shadowId then
        table.insert(coverIconKeyList, XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.ShadowIcon)
    elseif transferPointId then
        local transferPointColor = XRpgMakerGameConfigs.GetTransferPointColor(transferPointId:GetParams()[1])
        table.insert(coverIconKeyList, XRpgMakerGameConfigs.GetTransferPointIconKey(transferPointColor))
    end
    if trapId then
        table.insert(coverIconKeyList, XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.TrapIcon)
    end
    if triggerId then
        local triggerType = XMVCA.XRpgMakerGame:GetConfig():GetTriggerType(triggerId:GetParams()[1])
        table.insert(coverIconKeyList, XRpgMakerGameConfigs.GetTriggerIconKey(triggerType))
    end

    if bubble then
        table.insert(coverIconKeyList, XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.Bubble)
    end
    if drop then
        table.insert(coverIconKeyList, XRpgMakerGameConfigs.GetDropIconKey(drop:GetParams()[2]))
    end
    if magic then
        table.insert(coverIconKeyList, XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.Magic)
    end
    if switchMagic then
        table.insert(coverIconKeyList, XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.SwitchSkillPoint)
    end


    if not XTool.IsTableEmpty(entityTypeList) then
        for _, data in ipairs(entityTypeList) do
            if data:GetType() == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Water then
                table.insert(coverIconKeyList, XRpgMakerGameConfigs.GetEntityIconKey(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEntityType.Water))
            elseif data:GetType() == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Ice then
                table.insert(coverIconKeyList, XRpgMakerGameConfigs.GetEntityIconKey(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEntityType.Ice))
            elseif data:GetType() == XMVCA.XRpgMakerGame.EnumConst.XRpgMakeBlockMetaType.Grass then
                table.insert(coverIconKeyList, XRpgMakerGameConfigs.GetEntityIconKey(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEntityType.Grass))
            else
                table.insert(coverIconKeyList, XRpgMakerGameConfigs.GetEntityIconKey(XMVCA.XRpgMakerGame.EnumConst.XRpgMakerGameEntityType.Steel))
            end
        end
    end

    --设置缝隙图标列表
    if not XTool.IsTableEmpty(sameXYGapIdList) then
        self:SetGapIcon(sameXYGapIdList, XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.GapIcon, XRpgMakerGameConfigs.GetGapDirection)
    end

    --设置电墙图标列表
    if not XTool.IsTableEmpty(sameXYElectricFenceIdList) then
        self:SetGapIcon(sameXYElectricFenceIdList, XMVCA.XRpgMakerGame.EnumConst.RpgMakerGameHintIconKeyMaps.ElectricFenceIcon, XRpgMakerGameConfigs.GetElectricFenceDirection)
    end

    if not XTool.IsTableEmpty(coverIconKeyList) then
        -- 图标层级排序
        table.sort(coverIconKeyList, function (a,b)
            return XMVCA.XRpgMakerGame:GetConfig():GetHintLayer(a) > XMVCA.XRpgMakerGame:GetConfig():GetHintLayer(b)
        end)
        for index, key in ipairs(coverIconKeyList) do
            if index == 1 then
                self.ImgIcon:SetRawImage(XMVCA.XRpgMakerGame:GetConfig():GetHintIcon(key))
                self.ImgIcon.gameObject:SetActiveEx(true)
            else
                local imgIcon = XUiHelper.Instantiate(self.ImgIcon, self.ImgIcons)
                imgIcon:SetRawImage(XMVCA.XRpgMakerGame:GetConfig():GetHintIcon(key))
                imgIcon.gameObject:SetActiveEx(true)
            end
            break -- 只显示一张图，层级最高的图
        end
    else
        self.ImgIcon.gameObject:SetActiveEx(false)
    end
end

function XUiGridRpgMakerGameCardMini:SetGapIcon(idList, hintIconKey, directionFunc)
    local icon = XMVCA.XRpgMakerGame:GetConfig():GetHintIcon(hintIconKey)
    local imgIcon
    local direction
    local gapSize = self.ImgIcon.transform.sizeDelta
    local originPos = self.ImgIcon.transform.localPosition
    local directionPos
    local lookRotation

    for i, gapId in ipairs(idList) do
        direction = directionFunc(gapId)
        imgIcon = CSUnityEngineObjectInstantiate(self.ImgIcon, self.Transform)
        directionPos = self:GetDirectionPos(originPos, direction, gapSize.x / 2, gapSize.y / 2)

        if directionPos then
            imgIcon.transform.localPosition = directionPos
            imgIcon.transform.up = originPos - directionPos
        end
        imgIcon:SetRawImage(icon)
        imgIcon.gameObject:SetActiveEx(true)
    end
end

function XUiGridRpgMakerGameCardMini:GetDirectionPos(originLocalPos, direction, changeWidth, changeHeight)
    local directionPos
    local width = changeWidth and Vector3(changeWidth, 0, 0) or Vector3(1, 0, 0)
    local height = changeHeight and Vector3(0, changeHeight, 0) or Vector3(0, 1, 0)
    if direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridLeft then
        directionPos = originLocalPos - width
    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridRight then
        directionPos = originLocalPos + width
    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridTop then
        directionPos = originLocalPos + height
    elseif direction == XMVCA.XRpgMakerGame.EnumConst.RpgMakerGapDirection.GridBottom then
        directionPos = originLocalPos - height
    end
    return directionPos
end

function XUiGridRpgMakerGameCardMini:GetImageLine(id)
    return self.ImageLineMap[id]
end

return XUiGridRpgMakerGameCardMini