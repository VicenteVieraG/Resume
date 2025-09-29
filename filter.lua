local utils = pandoc.utils

local function latex_escape(str)
    str = str:gsub('\\\\', '\\textbackslash{}')
    str = str:gsub('([%%$#_{}&])', '\\%1')
    str = str:gsub('~', '\\textasciitilde{}')
    str = str:gsub('%^', '\\textasciicircum{}')
    return str
end

local function inlines_to_section_title(inlines)
    local raw = utils.stringify(inlines)
    raw = raw:gsub('^%s+', ''):gsub('%s+$', '')
    if raw == '' then
        return '\\phantom{}'
    end
    return latex_escape(raw)
end

local function extract_date(blockquote)
    local parts = {}
    for _, inner in ipairs(blockquote.content) do
        if inner.t == 'Para' or inner.t == 'Plain' then
            local str = utils.stringify(inner)
            if str ~= '' then
                table.insert(parts, latex_escape(str))
            end
        elseif inner.t == 'Header' then
            local str = utils.stringify(inner.content)
            if str ~= '' then
                table.insert(parts, latex_escape(str))
            end
        end
    end
    return table.concat(parts, ' ')
end

local function strip_marker(inlines, marker)
    local first = inlines[1]
    if not first or first.t ~= 'Str' then
        return false
    end
    local text = first.text
    if text:sub(1, #marker) ~= marker then
        return false
    end
    local remainder = text:sub(#marker + 1)
    if remainder == '' then
        table.remove(inlines, 1)
    else
        inlines[1] = pandoc.Str(remainder)
    end
    while inlines[1] and (inlines[1].t == 'Space' or inlines[1].t == 'SoftBreak') do
        table.remove(inlines, 1)
    end
    return true
end

local function split_on_marker(inlines, marker)
    for idx, inline in ipairs(inlines) do
        if inline.t == 'Str' and inline.text:sub(1, #marker) == marker then
            local before = {}
            for j = 1, idx - 1 do
                before[#before + 1] = inlines[j]
            end
            -- trim trailing whitespace from before
            while before[#before] and (before[#before].t == 'Space' or before[#before].t == 'SoftBreak') do
                before[#before] = nil
            end
            local after = {}
            local remainder = inline.text:sub(#marker + 1)
            if remainder ~= '' then
                after[#after + 1] = pandoc.Str(remainder)
            end
            for j = idx + 1, #inlines do
                after[#after + 1] = inlines[j]
            end
            while after[1] and (after[1].t == 'Space' or after[1].t == 'SoftBreak') do
                table.remove(after, 1)
            end
            return before, after, true
        end
    end
    return inlines, nil, false
end

return {
    {
        Pandoc = function(doc)
            local new_blocks = {}
            local in_entry = false

            local function close_entry()
                if in_entry then
                    table.insert(new_blocks, pandoc.RawBlock('latex', '\\end{twocolentry}'))
                    in_entry = false
                end
            end

            local i = 1
            while i <= #doc.blocks do
                local block = doc.blocks[i]

                if block.t == 'Header' and block.level == 1 then
                    close_entry()
                    local title = inlines_to_section_title(block.content)
                    table.insert(new_blocks, pandoc.RawBlock('latex', '\\section{' .. title .. '}'))

                elseif block.t == 'Header' and block.level == 2 then
                    close_entry()
                    local date = ''
                    if i + 1 <= #doc.blocks and doc.blocks[i + 1].t == 'BlockQuote' then
                        date = extract_date(doc.blocks[i + 1])
                        i = i + 1
                    end
                    if date == '' then
                        date = '\\phantom{}'
                    end
                    table.insert(new_blocks, pandoc.RawBlock('latex', '\\begin{twocolentry}{' .. date .. '}'))
                    table.insert(new_blocks, pandoc.Para(block.content))
                    in_entry = true

                elseif block.t == 'Header' and (block.level == 3 or block.level == 4) then
                    table.insert(new_blocks, pandoc.Para(block.content))

                elseif block.t == 'BlockQuote' then
                    for _, inner in ipairs(block.content) do
                        table.insert(new_blocks, inner)
                    end

                elseif block.t == 'BulletList' then
                    local processed_items = {}
                    local tail_blocks = {}
                    for _, item in ipairs(block.content) do
                        local new_item = {}
                        for _, item_block in ipairs(item) do
                            if (item_block.t == 'Para' or item_block.t == 'Plain') then
                                local before, after, has_marker = split_on_marker(item_block.content, '####')
                                if has_marker then
                                    if #before > 0 then
                                        local before_block = item_block.t == 'Para' and pandoc.Para(before) or pandoc.Plain(before)
                                        table.insert(new_item, before_block)
                                    end
                                    if after and #after > 0 then
                                        table.insert(tail_blocks, pandoc.Para(after))
                                    end
                                else
                                    table.insert(new_item, item_block)
                                end
                            else
                                table.insert(new_item, item_block)
                            end
                        end
                        if #new_item > 0 then
                            table.insert(processed_items, new_item)
                        end
                    end
                    if #processed_items > 0 then
                        table.insert(new_blocks, pandoc.BulletList(processed_items))
                    end
                    for _, extra in ipairs(tail_blocks) do
                        table.insert(new_blocks, extra)
                    end

                elseif block.t == 'Para' or block.t == 'Plain' then
                    local matched = false
                    local markers = { '### ', '###', '#### ', '####' }
                    for _, marker in ipairs(markers) do
                        if strip_marker(block.content, marker) then
                            matched = true
                            break
                        end
                    end
                    if matched then
                        table.insert(new_blocks, pandoc.Para(block.content))
                    else
                        local before, after, has_marker = split_on_marker(block.content, '####')
                        if has_marker then
                            if #before > 0 then
                                table.insert(new_blocks, pandoc.Para(before))
                            end
                            if after and #after > 0 then
                                table.insert(new_blocks, pandoc.Para(after))
                            end
                        else
                            table.insert(new_blocks, block)
                        end
                    end

                else
                    table.insert(new_blocks, block)
                end

                i = i + 1
            end

            close_entry()
            doc.blocks = new_blocks
            return doc
        end
    }
}
