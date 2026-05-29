---
--- Created by Jaylin.
--- DateTime: 2023-03-06-006 11:27
---
local IsWindowsEditor = XMain.IsWindowsEditor
---@class XModelBase
---@field _SaveUtil XSaveUtil
---@field _MainModel XModelBase
XModelBase = XClass(nil, "XModelBase")

local XSaveUtil = require('MVCA/XSaveUtil')

function XModelBase:Ctor(id, mainModel)
    self._Id = id
    self._SaveUtil = XSaveUtil.New(id)
    ---@type table<string, XModelBase>
    self._SubModels = false --子Model
    self._MainModel = mainModel
    self:InitInternal(id, mainModel)
end

function XModelBase:InitInternal(id, mainModel)
    self:OnInit()
end

---初始化函数,提供给子类重写
function XModelBase:OnInit()
end

function XModelBase:ClearAllPrivate()
    if self._SubModels then
        for _, subModel in pairs(self._SubModels) do
            subModel:ClearAllPrivate()
        end
    end
    self:ClearPrivate()
end

---清理内部数据, 在Control生命周期结束的时候会触发
function XModelBase:ClearPrivate()
    XLog.Error("请子类重写Model.ClearPrivate方法")
end

function XModelBase:ClearPrivateConfig()
    if self._SubModels then
        for _, subModel in pairs(self._SubModels) do
            subModel:ClearPrivateConfig()
        end
    end
end


--region 子Model

---@param cls any
---@return XModelBase
function XModelBase:AddSubModel(cls)
    if not self._SubModels then
        self._SubModels = {}
    end
    if not self._SubModels[cls] then
        local model = cls.New(self._Id, self)
        self._SubModels[cls] = model
        return model
    end
    XLog.Error(string.format("模块：%s 重复添加子Model：%s", self._Id, cls))
end

---@param model XModelBase
function XModelBase:RemoveSubModel(model)
    if not self._SubModels then
        --未初始化过
        XLog.Error(string.format("模块：%s 移除子Model失败，未添加过子Model", self._Id))
        return
    end
    local modelName = model.__class
    if not self._SubModels[modelName] then
        --未添加过
        XLog.Error(string.format("模块：%s 移除子Model：%s 失败，不存在", self._Id, modelName))
        return
    end
    self._SubModels[modelName] = nil
    model:CallResetAll()
    model:Release()
end

---获取一个子model
---@return XModelBase
function XModelBase:GetSubModel(cls)
    if not self._SubModels then
        --未初始化过
        return
    end
    return self._SubModels[cls]
end
--endregion

function XModelBase:CallResetAll()
    if self._SubModels then
        for _, subModel in pairs(self._SubModels) do
            subModel:CallResetAll()
        end
    end
    self:ResetAll()
    self._SaveUtil:ReleaseData()
end

---重登清理, 回到登录界面的时候需重置数据
function XModelBase:ResetAll()
end

function XModelBase:Release()
    if self._SubModels then
        for _, subModel in pairs(self._SubModels) do
            subModel:Release()
        end
        self._SubModels = nil
    end

    if self._SaveUtil then
        self._SaveUtil:ReleaseData()
        self._SaveUtil = nil
    end

    if IsWindowsEditor then
        WeakRefCollector.AddRef(WeakRefCollector.Type.Model, self)
    end
end

function XModelBase:_HotReloadModel(oldModel)
    local ReloadFunc = XHotReload.ReloadFunc
    for key, value in pairs(oldModel) do
        if key == "_ConfigUtil" then
            goto continue
        end
        if key == "_MainModel" and value then --主Model已经深拷贝了
            goto continue
        end
        if type(value) == "table" and CheckClassSuper(value, XModelBase) then --如果是子Model，则不处理否则会重新深拷贝一个子Model
            goto continue
        end
        if key == "_SubModels" and value then --深拷贝子Model
            for idx, subModel in pairs(value) do
                self._SubModels[idx]:_HotReloadModel(subModel)
            end
        else
            self[key] = XTool.CloneEx(value)
            if type(value) == "function" then
                ReloadFunc(value)
            end
        end
        ::continue::
    end
end
