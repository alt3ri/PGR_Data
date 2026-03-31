---@class XUiPhotographSDKPanel
local XUiPhotographSDKPanel = XClass(XSignalData, "XUiPhotographSDKPanel")
local DBEUG_SHOW_CUSTOM_SHARE_TEXT = true

function XUiPhotographSDKPanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiPhotographSDKPanel:Init()
    self.ShareBtnList = {
        self.BtnShare1,
        self.BtnShare2,
        self.BtnShare3,
        self.BtnShare4,
        self.BtnShare5,
        self.BtnShare6,
        self.BtnShare7,
        self.BtnShare8,
    }
    self:AutoRegisterBtn()
end

function XUiPhotographSDKPanel:AutoRegisterBtn()
    local shareSDKIds = XDataCenter.PhotographManager.GetShareSDKIds()
    if XOverseaManager.IsOverSeaRegion() then 
        if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc then
            shareSDKIds = 
            {
                [1] = XPhotographConfigs.OverseaSharePlatform.ShareLink,
            }
        end
    end
    local shareBtnCount = #shareSDKIds
    
    -- 先全部隐藏
    for i, v in ipairs(self.ShareBtnList) do
        v.gameObject:SetActiveEx(false)
    end
    
    -- 逐一检测和显示开启的分享入口
    if not XTool.IsTableEmpty(shareSDKIds) then
        local btnIndex = 1

        for i, id in ipairs(shareSDKIds) do
            local shareInfo = XPhotographConfigs.GetShareInfoByType(id)
            -- 存在数据且功能开启，需要显示入口
            local isShow = false
            if XOverseaManager.IsOverSeaRegion()  then
                isShow = shareInfo and (shareInfo.Id == XPhotographConfigs.OverseaSharePlatform.ShareLink or XHeroSdkManager.SharePlatformIsEnable(shareInfo.Id) )
            else
                isShow = shareInfo and XHeroSdkManager.SharePlatformIsEnable(shareInfo.Id)
            end
            if isShow then
                if btnIndex <= shareBtnCount then
                    local btn = self.ShareBtnList[btnIndex]

                    if btn then
                        self.ShareBtnList[btnIndex].gameObject:SetActiveEx(true)
                        self.ShareBtnList[btnIndex].CallBack = function()
                            self:OnClickShareBtn(shareInfo.Id)
                        end
                        self.ShareBtnList[btnIndex]:SetSprite(shareInfo.IconPath)
                        self.ShareBtnList[btnIndex]:SetName(shareInfo.Name)

                        btnIndex = btnIndex + 1
                    end
                else
                    XLog.Error('有效的分享入口数量超过UI上限')
                end
            end
        end
    end
    
    self.BtnSave.CallBack = function()
        XDataCenter.PhotographManager.SharePhotoBefore(self.RootUi.PhotoName, self:GetParentCacheTexture(), XPlatformShareConfigs.PlatformType.Local)
        if self.RootUi.OnBtnSaveCallBack then
            self.RootUi:OnBtnSaveCallBack()
        end
    end
    if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc then
        if self.BtnExplorerPc then
            self.BtnExplorerPc.gameObject:SetActiveEx(not XOverseaManager.IsOverSeaRegion())
            self.BtnExplorerPc.CallBack = function()
                local path = CS.XTool.GetPhotoAlbumPath()
                path = string.gsub(path, "/", "\\")
                if not CS.System.IO.Directory.Exists(path) then
                    CS.System.IO.Directory.CreateDirectory(path)
                end
                CS.UnityEngine.Application.OpenURL(path)
            end
        end
    else
        if self.BtnExplorerPc then
            self.BtnExplorerPc.gameObject:SetActiveEx(false)
        end
        if XOverseaManager.IsOverSeaRegion() then
            self.BtnSave.gameObject:SetActiveEx(false)
        end
    end
 
end

function XUiPhotographSDKPanel:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiPhotographSDKPanel:Hide()
    self.GameObject:SetActiveEx(false)
end

--shareId,shareInfo中的Id，且与枚举XEnumConst.SharePlatform对应
function XUiPhotographSDKPanel:OnClickShareBtn(shareId)
    if shareId == XPhotographConfigs.OverseaSharePlatform.ShareLink then 
        local info = XPhotographConfigs.GetShareInfoByType(shareId)
        XTool.CopyToClipboard(info.Text)
        XUiManager.TipMsg("HoldRegressionShareNetLinkTW")
        if self.RootUi.OnBtnSaveCallBack then
            self.RootUi:OnBtnSaveCallBack()
        end
        return
    end

    local result = self:EmitSignal("ShareBtnClicked", shareId, self)
    if result and result.isAwait then
        RunAsyn(function()
            local signalCode = self:AwaitSignal("FinishedReadyShare", self)
            if signalCode ~= XSignalCode.SUCCESS then
                return
            end
            self:Share(shareId)
        end)
        return
    end
    self:Share(shareId)
end

function XUiPhotographSDKPanel:GetParentCacheTexture()
    local cacheTexture = self.RootUi.ShareTexture
    if not cacheTexture then
        cacheTexture = self.RootUi:GetCacheTexture(2) or self.RootUi:GetCacheTexture(1) or self.RootUi:GetCacheTexture(0)
    end
    return cacheTexture
end

function XUiPhotographSDKPanel:Share(shareId)
    local customText
    if self.RootUi.GetPlatformType2CustomText then
        customText = self.RootUi.GetPlatformType2CustomText(self.RootUi, shareId)
    end
    if DBEUG_SHOW_CUSTOM_SHARE_TEXT then
        XLog.Warning(customText or "其他系统测试分享")
    end
    XDataCenter.PhotographManager.SharePhoto(self.RootUi.PhotoName, self:GetParentCacheTexture(), shareId, customText)
end

return XUiPhotographSDKPanel