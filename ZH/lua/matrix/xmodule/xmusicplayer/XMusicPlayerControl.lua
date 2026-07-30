---@class XMusicPlayerControl : XControl
---@field private _MainModel XMusicPlayerModel
---@field private _CdViewModel XMusicPlayerCDViewModel
---@field private _MusicListControl XMusicPlayerMusicListControl
---@field private _MusicPlayerConfigControl XMusicPlayerConfigControl
---@field private _MusicPlayerNetWorkControl XMusicPlayerNetWorkControl
---@field private _CdPlayerControl XMusicPlayerCDPlayerControl
local XMusicPlayerControl = XClass(XControl, "XMusicPlayerControl")

function XMusicPlayerControl:OnInit()
    self._MainModel = self._Model
    self._CdViewModel = self._Model:GetCDViewModel()

    self._MusicListControl = self:AddSubControl(require('XModule/XMusicPlayer/Controller/XMusicPlayerMusicListControl'))
    self._MusicPlayerNetWorkControl =  self:AddSubControl(require('XModule/XMusicPlayer/Controller/XMusicPlayerNetWorkControl'))
    self._MusicPlayerConfigControl =  self:AddSubControl(require('XModule/XMusicPlayer/Controller/XMusicPlayerConfigControl'))
    self._CdPlayerControl =  self:AddSubControl(require('XModule/XMusicPlayer/Controller/XMusicPlayerCDPlayerControl'))

    self:_InitReferenceHues()
    self:_InitColorMaterials()
end


--- Control在生命周期启动时注册Agency事件及对外Agency事件
function XMusicPlayerControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XMusicPlayerControl:RemoveAgencyEvent()

end

function XMusicPlayerControl:OnRelease()
   self._ReferenceHues = {}
   self._JumpAlbumCollectionClickMusicID = nil
   self._CDAutoRotateEnabled = nil
   self._ColorMaterialDic = nil
   self._PathAssetDic = nil
   self._ColorMaterialLoadCount = nil
end

---region 获取子controller

---@return XMusicPlayerConfigControl
function XMusicPlayerControl:GetMusicPlayerconfigControl()
    return self._MusicPlayerConfigControl  
end

---@return XMusicPlayerMusicListControl
function XMusicPlayerControl:GetMusicmusicListControl()
    return self._MusicListControl 
end

---@return XMusicPlayerNetWorkControl
function XMusicPlayerControl:GetMusicPlayerNetWorkControl()
    return self._MusicPlayerNetWorkControl 
end

---@return XMusicPlayerCDPlayerControl
function XMusicPlayerControl:GetCDPlayerControl()
    return self._CdPlayerControl
end
---endregion


--region ----------UI按钮图集查询----------

--- 根据控件键获取当前颜色的Sprite路径（从配置表读取）
---@param key XMusicPlayerEnum.UiSpriteKey 控件键枚举
---@return string Sprite路径
function XMusicPlayerControl:GetCurColorUiSprite(key)
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    if not self._CurColorEnum then
        self._CurColorEnum = XMusicPlayerEnum.UiButtonColor.Blue
    end

    local co = self:GetMusicPlayerconfigControl():GetMusicPlayerColorStyleCO(self._CurColorEnum)
    if not co then
        return nil
    end

    if key == XMusicPlayerEnum.UiSpriteKey.BgmListBtn then
        return co.BgmListBtnSprite
    elseif key == XMusicPlayerEnum.UiSpriteKey.PlayMusicBtn then
        return co.PlayMusicBtnSprite
    elseif key == XMusicPlayerEnum.UiSpriteKey.StopMusicBtn then
        return co.StopMusicBtnSprite
    elseif key == XMusicPlayerEnum.UiSpriteKey.ListCellSelectedBg then
        return co.ListCellSelectedBgSprite
    end
    return nil
end
--endregion ----------UI按钮图集查询----------

--region ----------Cell 点击跳转----------

--- 设置 CD cell 点击时选中的歌ID（供 AlbumCollectionView 定位用）
---@param musicID number
function XMusicPlayerControl:SetJumpAlbumCollectionClickMusicID(musicID)
    self._JumpAlbumCollectionClickMusicID = musicID
end

--- 清空 CD cell 点击的歌ID
function XMusicPlayerControl:ClearJumpAlbumCollectionClickMusicID()
    self._JumpAlbumCollectionClickMusicID = nil
end

--- 获取 CD cell 点击的歌ID
---@return number|nil
function XMusicPlayerControl:GetJumpAlbumCollectionClickMusicID()
    return self._JumpAlbumCollectionClickMusicID
end
--endregion ----------Cell 点击跳转----------

--region ----------CD 封面旋转状态----------

--- 设置 CD 封面是否应旋转（由事件驱动: ZhenEnable完成/暂停/切歌）
---@param enabled boolean
function XMusicPlayerControl:SetCDAutoRotateEnabled(enabled)
    self._CDAutoRotateEnabled = enabled
end

--- 获取 CD 封面是否应旋转（指针已落下 且 音乐正在播放）
---@return boolean
function XMusicPlayerControl:GetCDAutoRotateEnabled()
    return self._CDAutoRotateEnabled == true and self:GetCDPlayerControl():IsPlaying()
end
--endregion ----------CD 封面旋转状态----------


--region ----------背景主色→UI色调----------

--- 色相环形距离(0-0.5, Unity HSV hue 范围 0-1)
---@param h1 number
---@param h2 number
---@return number
local function HueDistance(h1, h2)
    local diff = math.abs(h1 - h2)
    return math.min(diff, 1.0 - diff)
end

--- OnInit 时用 Unity Color.RGBToHSV 预计算参考色相(0-1)
function XMusicPlayerControl:_InitReferenceHues()
    self._ReferenceHues = {}
    local refRgb = XMVCA.XMusicPlayer.Enum.UiButtonColorRgb
    for name, rgb in pairs(refRgb) do
        local color = CS.UnityEngine.Color(rgb[1], rgb[2], rgb[3], 1.0)
        local h = CS.UnityEngine.Color.RGBToHSV(color)
        self._ReferenceHues[name] = h
    end
end

--- 由 UI 层在背景图分析完成后注入主色
---@param color UnityEngine.Color
function XMusicPlayerControl:SetMusicBgMainColor(color)
    self._MusicBgMainColor = color
    self._CurColorEnum = self:_FindClosestColorEnum(self._MusicBgMainColor)
    self:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_CHANGE_UI_COLOR_STYLE)
end


---@param color UnityEngine.Color
---@return string UiButtonColor 枚举名
function XMusicPlayerControl:_FindClosestColorEnum(color)
    local targetHue = CS.UnityEngine.Color.RGBToHSV(color)
    local minDist = math.huge
    local closestName = XMVCA.XMusicPlayer.Enum.UiButtonColor.Blue
    for name, refHue in pairs(self._ReferenceHues) do
        local diff = math.abs(targetHue - refHue)
        local dist = math.min(diff, 1.0 - diff)
        if dist < minDist then
            minDist = dist
            closestName = name
        end
    end
    return closestName
end

--endregion ----------背景主色→UI色调----------


--region ----------颜色材质加载与查询----------

function XMusicPlayerControl:_InitColorMaterials()
    self._ColorMaterialDic = {}
    self._PathAssetDic = {}
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local configControl = self:GetMusicPlayerconfigControl()
    local loader = self:GetLoader()

    -- 1. 先收集所有唯一路径
    local pathSet = {}
    for _, colorType in pairs(XMusicPlayerEnum.UiButtonColor) do
        local co = configControl:GetMusicPlayerColorStyleCO(colorType)
        if co then
            self._ColorMaterialDic[colorType] = {}
            for _, matKey in pairs(XMusicPlayerEnum.UiMaterialKey) do
                local path = co[matKey]
                if path and path ~= "" then
                    pathSet[path] = true
                end
            end
        end
    end

    local count = 0
    for _ in pairs(pathSet) do
        count = count + 1
    end
    self._ColorMaterialLoadCount = count

    if count <= 0 then
        self:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_COLOR_MATERIAL_LOADED)
        return
    end

    for path in pairs(pathSet) do
        loader:LoadAsync(path, function(asset)
            if asset then
                self._PathAssetDic[path] = asset
            end
            self._ColorMaterialLoadCount = self._ColorMaterialLoadCount - 1
            if self._ColorMaterialLoadCount <= 0 then
                self:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_COLOR_MATERIAL_LOADED)
            end
        end)
    end
end

---@param matKey string XMusicPlayerEnum.UiMaterialKey
---@return UnityEngine.Material
function XMusicPlayerControl:GetCurColorMat(matKey)
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local colorType = self._CurColorEnum or XMusicPlayerEnum.UiButtonColor.Blue
    local co = self:GetMusicPlayerconfigControl():GetMusicPlayerColorStyleCO(colorType)
    local path = co[matKey]
    return  self._PathAssetDic[path]
end

--endregion ----------颜色材质加载与查询----------


return XMusicPlayerControl


