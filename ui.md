# UI musings

I've seen a few examples of how UI frameworks and widgets are made for love2d now, and have some thoughts on what to do and what a browser needs.

First, it is clear that all widgets need a common interface, including methods for getting and setting height, width, x axis and y axis locations.

This probably also needs to be the case for handler functions, like clicks, keystrokes, mouse hover, etc. Somewhat regrettably (having never done so before) it might be that it is time to learn about lua's idea of inheritance. 

It would be nice to be able to define a UI along these lines:

```
UI = ui.new -- returns a table which knows the size of the window and can accept a list of other tables

myWidget = addressBar.new({ default_url: marginalia.nu, size: enum(compact,regular,large), search_handler: function, ...}) -- an address bar would presumably always be full width, and the height inferred from the "size" field
--[[
myWidget:setHeight
myWidget:getHeight
myWidget:setWidth
myWidget:getWidth
]]
UI[1] = myWidget
UI[2] = myOtherWidget
-- ..etc..
