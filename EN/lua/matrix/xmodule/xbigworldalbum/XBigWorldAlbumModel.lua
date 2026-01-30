---@class XBigWorldAlbumModel : XModel
local XBigWorldAlbumModel = XClass(XModel, "XBigWorldAlbumModel")

local TableKey = {
    BigWorldPhotographParams = "BigWorldPhotographParams",
    -- BigWorldPhotographParams = { DirPath = XConfigUtil.DirectoryType.Client },
}

function XBigWorldAlbumModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Photograph", TableKey)
end

function XBigWorldAlbumModel:ClearPrivate()
    --这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XBigWorldAlbumModel:ResetAll()
    --这里执行重登数据清理
    -- XLog.Error("重登数据清理")
    self._photoDatas = nil
end

function XBigWorldAlbumModel:GetParamConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldPhotographParams, id)
end

----------public start----------

--region 获取相册数据

function XBigWorldAlbumModel:SetPhotoDatas(photoDatas)
    self._photoDatas = photoDatas
end

function XBigWorldAlbumModel:GetPhotoDatas()
    return self._photoDatas
end

function XBigWorldAlbumModel:AddPhotoDatas(photoData)
    if not self._photoDatas then self._photoDatas = {} end
    table.insert(self._photoDatas, photoData)
    return photoData
end

function XBigWorldAlbumModel:DeletePhotoDatas(photoIdList)
    for i = 1, #photoIdList do
        local id = photoIdList[i]
        for j = 1, #self._photoDatas do
            if self._photoDatas[j].Id == id then
                table.remove(self._photoDatas, j)
                break
            end
        end
    end
end

function XBigWorldAlbumModel:UpdatePhotoDatas(photoId, remake)
    for j = 1, #self._photoDatas do
        if self._photoDatas[j].Id == photoId then
            self._photoDatas[j].Remark = remake
            break
        end
    end
end

--endregion

----------public end----------

----------private start----------


----------private end----------

----------config start----------


----------config end----------


return XBigWorldAlbumModel