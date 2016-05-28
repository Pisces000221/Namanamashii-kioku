require './http'

http.default_referer = 'http://web.kuaipan.cn/n/drive/files'
-- print(http.post('http://web.kuaipan.cn/n/drive/getFiles', { id = '', sortby = '', cc = 'false' }))

function ls(path, id)
    if id ~= 0 then id = tostring(id) else id = '' end
    print(http.post('http://web.kuaipan.cn/n/drive/getFiles', { id = id, sortby = '', cc = 'false' }))
end

local tree = ls('/', 0)
