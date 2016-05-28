require './http'
JSON = JSON or require('./libs/JSON')
inspect = inspect or require('./libs/inspect')

http.default_referer = 'http://web.kuaipan.cn/n/drive/files'

local files = {}
local last_save = 0
local save_interval = 10
function serialize(record)
    local s = record.id .. ','
    if record.isdir then s = s .. 'DIR' else s = s .. record.size end
    s = s .. ',' .. record.ctime .. ',' .. record.mtime .. ',' .. record.path .. '\n'
    return s
end
function file_info_append(path, id, isdir, size, ctime, mtime)
    local record = {
        path = path, id = id, isdir = isdir, size = size, ctime = ctime, mtime = mtime,
    }
    files[#files + 1] = record
    if #files > last_save + save_interval then
        f = io.open('dirlist.txt', 'a')
        for i = last_save + 1, #files do
            f:write(i, ',', serialize(files[i]))
        end
        last_save = #files
        f:close()
    end
end

function ls(id, depth)
    if id ~= nil then id = tostring(id) else id = '' end
    local res = JSON:decode(http.post('http://web.kuaipan.cn/n/drive/getFiles', { id = id, sortby = '', cc = 'false' }))
    if res[1] ~= nil and res[1].docs ~= nil then
        local list = res[1].docs
        if res[1].path == '/' then res[1].path = '' end
        for i = 1, #list do
            file_info_append(
                res[1].path .. '/' .. list[i].name, list[i].id,
                list[i].type == 'folder',
                list[i].bytes,
                list[i].ctime, list[i].mtime
            )
        end
        for i = 1, #list do
            if list[i].type == 'folder' then
                if depth < 3 then
                    print('Retrieving directory list: (' .. id .. ') ' .. res[1].path .. '/' .. list[i].name)
                elseif depth == 3 then
                    print('Retrieving directory list: (' .. id .. ') ' .. res[1].path .. '/' .. list[i].name .. '/...')
                end
                ls(list[i].id, depth + 1)
            end
        end
        return ret
    else
        print('Error while retrieving directory list - - Details is as follows')
        print(inspect(res))
    end
end

local tree = ls(nil, 0)
print('Directory listing finished. Result is as follows.')
print(inspect(tree))
