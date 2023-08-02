local colors = require "glove/colors"
local love = require "love"

local g = love.graphics

local tabPadding = 5

local function getTabHeight(font)
  return font:getHeight() + tabPadding * 2
end

local function setVisible(widget, visible)
  widget.visible = visible
  if widget.children then
    for _, child in ipairs(widget.children) do
      setVisible(child, visible)
    end
  end
end

local mt = {
  __index = {
    draw = function(self, parentX, parentY)
      parentX = parentX or Glove.margin
      parentY = parentY or Glove.margin
      local x = parentX + self.x
      local y = parentY + self.y
      self.actualX = x
      self.actualY = y

      -- local over = self:isOver(love.mouse.getPosition())
      -- g.setColor(over and Glove.hoverColor or self.color)

      local font = self.font
      g.setFont(font)
      local tabHeight = getTabHeight(font)

      for index, tab in ipairs(self.tabs) do
        local selected = index == self.selectedTabIndex
        local mode = selected and "fill" or "line"
        if selected then g.setColor(colors.gray) end

        local label = tab.label
        local tabWidth = font:getWidth(label) + tabPadding * 2

        -- Draw a rounded rectangle.
        g.setColor(self.color)
        g.rectangle(mode, x, y, tabWidth, tabHeight, tabPadding, tabPadding)

        -- Draw a non-rounded rectangle.
        g.setColor(selected and self.color or colors.black)
        g.rectangle("fill", x, y + tabHeight - tabPadding + 1, tabWidth, tabPadding)

        -- Draw a line across the bottom.
        g.setColor(self.color)
        g.line(x, y + tabHeight, x + tabWidth, y + tabHeight)

        -- Draw the tab text.
        g.setColor(selected and colors.black or self.color)
        g.print(label, x + tabPadding, y + tabPadding)
        x = x + tabWidth
      end

      -- Draw vertical lines to close the bottom of the rounded rectangles
      -- that was erased by the non-rounded rectangles drawn above.
      x = self.actualX
      for index, tab in ipairs(self.tabs) do
        local selected = index == self.selectedTabIndex
        local label = tab.label
        local tabWidth = font:getWidth(label) + tabPadding * 2

        g.setColor(self.color)
        local y1 = y + tabHeight - 1
        local y2 = y1 - tabPadding + 2
        if not selected then g.line(x, y1, x, y2) end

        local x2 = x + tabWidth
        g.line(x2, y1, x2, y2)

        x = x + tabWidth
      end

      local selectedTab = self.tabs[self.selectedTabIndex]
      selectedTab.widget:draw(parentX, parentY + tabHeight + tabPadding)
    end,

    getHeight = function(self)
      return self.font:getHeight()
    end,

    getWidth = function(self)
      return self.width or Glove.getAvailableWidth()
    end,

    handleClick = function(self, clickX, clickY)
      local currentTab = self.tabs[self.selectedTabIndex]

      local clicked = self:isOver(clickX, clickY)
      if clicked then
        local index = self.selectedTabIndex
        local newTab = self.tabs[index]
        if self.onChange then
          self.onChange(index, newTab)
        end

        setVisible(currentTab.widget, false)
        setVisible(newTab.widget, true)
      end

      return clicked
    end,

    isOver = function(self, mouseX, mouseY)
      local x = self.actualX
      local y = self.actualY
      if not x or not y then return false end

      local font = self.font
      local tabHeight = getTabHeight(font)

      for index, tab in ipairs(self.tabs) do
        local tabWidth = font:getWidth(tab.label) + tabPadding * 2
        local endX = x + tabWidth
        local over = mouseX >= x and mouseX <= endX and
            mouseY >= y and mouseY <= y + tabHeight
        if over then
          self.selectedTabIndex = index
          return true
        end
        x = endX
      end

      return false
    end
  }
}

--[[
This widget displays a row of tabs where only one can be selected at a time.
Each tab is associated with a single widget which is
typically an `HStack`, `VStack`, or `ZStack`.
The widget associated with the selected tab is displayed below the tabs.

The parameters are:

- tabs described by an array-like table containing
  tables with `label` and `widget` keys
- table of options

The supported options are:

- `color`: of the labels; defaults to white
- `font`: used for the labels
- `onChange`: optional function to be called when a tab is selected;
   passed the tab index and the table describing the tab
--]]
local function Tabs(tabs, options)
  options = options or {}
  assert(type(options) == "table", "Tabs options must be a table.")

  for index, tab in ipairs(tabs) do
    local widget = tab.widget
    widget.x = 0
    widget.y = 0
    widget.visible = index == 1
  end

  local instance = options
  instance.kind = "Tabs"
  instance.color = instance.color or colors.white
  instance.font = options.font or g.getFont()
  instance.selectedTabIndex = 1
  instance.tabs = tabs
  instance.visible = true
  instance.x = 0
  instance.y = 0

  setmetatable(instance, mt)

  table.insert(Glove.clickables, instance)

  return instance
end

return Tabs
