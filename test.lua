-- Test for hud_channels.lua & text_styles.lua

register_hud_channel("score", {mode="stack", hud_base_position={x=0.6, y=0.5}, autoremove_interval=4})

modlib.minetest.register_globalstep(1, function()
    if math.random() > 0.5 then
        local choice=math.random(1, 3)
        local text=({"-", "+", "~"})[choice]..tostring(math.random(1, 50))
        --minetest.chat_send_all("adv_chat:hud_channels test - sending "..minetest.get_color_escape_sequence(({"#FF0000","#00FF00", "#9999FF"})[choice])..text)
        add_msg_to_hud(nil, "score", {number=(({0xFF0000, 0x00FF00, 0x9999FF})[choice]),text=text,
                                      hud_elem_type="text",scale={x=100,y=100}, alignment = {x=-1,y=0}})
    end
end)

minetest.after(3, function()
    minetest.chat_send_all(convert_colors("This is a \x033test. \x03This is another \x037one."))
    minetest.chat_send_all(irc_to_markdown(string.char(0x02).."bold "..string.char(0x02).." "..string.char(0x1D).."italics"))
    minetest.chat_send_all(minetest.write_json(markdown_to_irc("**bold***italics*")))
    --minetest.chat_send_all(markdown_to_irc())
end)