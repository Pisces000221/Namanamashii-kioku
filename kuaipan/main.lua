require './http'
JSON = JSON or require('./libs/JSON')
inspect = inspect or require('./libs/inspect')

http.default_referer = 'http://web.kuaipan.cn/n/drive/files'

function dir_info_new(path, id, isdir, size, ctime, mtime)
    local ret = {
        path = path, id = id, isdir = isdir, size = size, ctime = ctime, mtime = mtime,
    }
    if is_dir then ret.children = {} end
    return ret
end

function ls(id, path)
    if id ~= nil then id = tostring(id) else id = '' end
    print('Retrieving directory list: (' .. id .. ') ' .. path)
    local res = JSON:decode(http.post('http://web.kuaipan.cn/n/drive/getFiles', { id = id, sortby = '', cc = 'false' }))
    if res[1] ~= nil and res[1].docs ~= nil then
        local ret = {}
        res = res[1].docs
        for i = 1, #res do
            ret[#ret + 1] = dir_info_new(
                res[i].name, res[i].id,
                res[i].type == 'folder',
                res[i].bytes,
                res[i].ctime, res[i].mtime
            )
        end
        for i = 1, #ret do
            if ret[i].isdir then
                ret[i].children = ls(ret[i].id, path .. ret[i].path .. '/')
            end
        end
        return ret
    else
        print('Error while retrieving directory list - - Details is as follows')
        print(inspect(res))
    end
end

local tree = ls(nil, '/')
print('Directory listing finished. Result is as follows.')
print(inspect(tree))
