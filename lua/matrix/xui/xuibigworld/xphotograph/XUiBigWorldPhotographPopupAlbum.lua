
---@class XUiBigWorldPhotographPopupAlbum : XLuaUi
local XUiBigWorldPhotographPopupAlbum = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPhotographPopupAlbum")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

function XUiBigWorldPhotographPopupAlbum:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiBigWorldPhotographPopupAlbum:OnStart(...)
    self._selectCount = 0
    self._selectTabel = {}
    self.PhotoDatas = self._Control:GetPhotoDatas() or {}
    
    local XUiBigWorldPhotographPopupAlbumGridPhoto = require("XUi/XUiBigWorld/XPhotograph/XUiBigWorldPhotographPopupAlbumGridPhoto")
    self.DynamicTable = XDynamicTableNormal.New(self.ListPhoto.gameObject)
    self.DynamicTable:SetProxy(XUiBigWorldPhotographPopupAlbumGridPhoto, self)
    self.DynamicTable:SetDelegate(self)

    self:SetMultipleSelect(false)
end

function XUiBigWorldPhotographPopupAlbum:OnEnable()
    self:Refresh(true)
end

--================
--动态列表事件
--================
function XUiBigWorldPhotographPopupAlbum:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.PhotoDatas[index], index)
    end
end

--================
--刷新动态列表
--================
function XUiBigWorldPhotographPopupAlbum:_UpdateUIView()
    self.TxtNum.text = self._Control:GetPhotoCurrentNum() .. "/" .. self._Control:GetPhotoMaxNum()
    local isCancelAll = self._selectCount > 0
    local key = isCancelAll and "SG_P_UnselectAll" or "SG_P_SelectAll"
    local btnName = XMVCA.XBigWorldService:GetText(key)
    self.BtnCancel:SetName(btnName)
end

function XUiBigWorldPhotographPopupAlbum:Refresh(isAsync)
    self:_UpdateUIView()
    self.DynamicTable:SetDataSource(self.PhotoDatas)
    self.DynamicTable:ReloadDataSync()

    if self.PanelNone then self.PanelNone.gameObject:SetActive(#self.PhotoDatas <= 0) end
    if #self.PhotoDatas <= 0 then
        self:SetMultipleSelect(false)
    end
end

function XUiBigWorldPhotographPopupAlbum:IsSelectedByPhotoIndex(photoIndex)
    if self._IsMultipleSelect then
        return self._selectTabel[photoIndex] or false
    else
        return false
    end
end

function XUiBigWorldPhotographPopupAlbum:ClearList()
    self._selectCount = 0
    self._selectTabel = {}
    self.TxtSelectNum.text = self._selectCount
    self:Refresh()
end

function XUiBigWorldPhotographPopupAlbum:SelectAll()
    self._selectCount = 0
    self._selectTabel = {}
    for photoIndex, photoData in pairs(self.PhotoDatas) do
        self._selectTabel[photoIndex] = true
        self._selectCount = self._selectCount + 1
    end
    self.TxtSelectNum.text = self._selectCount
    self:Refresh()
end

function XUiBigWorldPhotographPopupAlbum:OnPhotoClick(photoIndex)
    if self._IsMultipleSelect then
        self._selectTabel[photoIndex] = not self._selectTabel[photoIndex]
        local grid = self.DynamicTable:GetGridByIndex(photoIndex)
        if self._selectTabel[photoIndex] then
            self._selectCount = self._selectCount + 1
        else
            self._selectCount = self._selectCount - 1
        end
        grid:SetSelected(self._selectTabel[photoIndex])
        self.TxtSelectNum.text = self._selectCount

        self:_UpdateUIView()
    else
        self._Control:SetSelectPhotoIndex(photoIndex)
        XMVCA.XBigWorldUI:Open("UiBigWorldPhotographPopupAlbumDetail")
    end
end

function XUiBigWorldPhotographPopupAlbum:SetMultipleSelect(isMultipleSelect)
    if self._IsMultipleSelect == isMultipleSelect then return end
    if self.BtnSelectOff then
        self.BtnSelectOff.gameObject:SetActive(isMultipleSelect)
        self.BtnSelect.gameObject:SetActive(not isMultipleSelect)
    end

    self._IsMultipleSelect = isMultipleSelect
    self.PanelBtn.gameObject:SetActive(self._IsMultipleSelect)
    self:ClearList()
end

function XUiBigWorldPhotographPopupAlbum:OnBtnSelectClick()
    if #self.PhotoDatas <= 0 then
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("SG_P_NotEdit"))
        return
    end
    self:SetMultipleSelect(not self._IsMultipleSelect)
end

function XUiBigWorldPhotographPopupAlbum:OnBtnTanchuangCloseClick()
    self:Close()
end

function XUiBigWorldPhotographPopupAlbum:OnBtnDeteleClick()
    local removeTable = {}
    for photoIndex, isSelected in pairs(self._selectTabel) do
        if isSelected then
            table.insert(removeTable, self.PhotoDatas[photoIndex].Id)
        end
    end
    self._Control:DeletePhoto(removeTable, function()
        self:ClearList()
    end)
end

function XUiBigWorldPhotographPopupAlbum:OnBtnCancelClick()
    local isCancelAll = self._selectCount > 0
    if isCancelAll then
        self:ClearList()
    else
        self:SelectAll()
    end
end

function XUiBigWorldPhotographPopupAlbum:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnSelect:AddEventListener(handler(self, self.OnBtnSelectClick))
    if self.BtnSelectOff then
        self.BtnSelectOff:AddEventListener(handler(self, self.OnBtnSelectClick))
    end
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnTanchuangCloseClick))
    self.BtnDetele:AddEventListener(handler(self, self.OnBtnDeteleClick))
    self.BtnCancel:AddEventListener(handler(self, self.OnBtnCancelClick))
end

return XUiBigWorldPhotographPopupAlbum
