http = {}
http.cookie_jar = 'cookies.txt'
http.default_referer = ''
http.xsrf_token = ''

function http.get(url, referer)
    referer = referer or http.default_referer
    local handle = io.popen('curl -q -k -s -b ' .. http.cookie_jar .. ' -c ' .. http.cookie_jar .. ' -X GET '
        .. '-e "' .. referer .. '" '
        .. '-H "Accept-Language: zh-CN,zh;q=0.8,en-US;q=0.6,en;q=0.4,ja;q=0.2"'
        .. '-m 10 "' .. url .. '"', 'r')
    local response = handle:read('*a')
    handle:close()
    return response
end

function http.post(url, content, referer)
    referer = referer or http.default_referer
    local handle = io.popen('curl -q -k -s -b ' .. http.cookie_jar .. ' -c ' .. http.cookie_jar .. ' -X POST '
        .. '-e "' .. referer .. '" '
        .. '-H "Content-Type: application/x-www-form-urlencoded" '
        .. '-H "X-XSRF-TOKEN: ' .. http.xsrf_token .. '" '
        .. '-m 10 "' .. url .. '" -d "' .. http.urlencode(content) .. '"', 'r')
    local response = handle:read('*a')
    handle:close()
    return response
end

function http.download(url, path, referer)
    referer = referer or http.default_referer
    local handle = io.popen('wget --load-cookies ' .. http.cookie_jar .. ' -q '
        .. '-O "' .. path .. '" "' .. url .. '"', 'r')
    handle:close()
end

-- http.urlencode({a = '%%%%""""膜膜膜膜', b = '＊＊＊＊'})
-- > 'a=%25%25%25%25%22%22%22%22%E8%86%9C%E8%86%9C%E8%86%9C%E8%86%9C&b=%EF%BC%8A%EF%BC%8A%EF%BC%8A%EF%BC%8A'
function http.urlencode(table)
    local ret = '', k, v, i, t
    for k, v in pairs(table) do
        ret = ret .. '&' .. k .. '='
        v = tostring(v)
        for i = 1, v:len() do
            t = v:byte(i)
            if (t >= 48 and t <= 57) or (t >= 65 and t <= 90) or (t >= 97 and t <= 122) then
                ret = ret .. v:sub(i, i)
            else ret = ret .. string.format('%%%2X', t) end
        end
    end
    return ret:sub(2)
end
