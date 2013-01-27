----------------------------------------------------------------
-- Copyright (c) 2010-2011 Zipline Games, Inc. 
-- All Rights Reserved. 
-- http://getmoai.com
----------------------------------------------------------------

local inspect = require("inspect")
local math = require("math")

local sprites = {
  male = {
    src = "male.png",
    width = 32,
    height = 55,
    origin = {
      x = 16,
      y = 39
    },
    getRect = function (self)
      return self.origin.x, self.origin.y - self.height, self.origin.x - self.width, self.origin.y
    end
  }
}

local Object = {}

function Object:new ( sprite )
  self.gfxQuad = MOAIGfxQuad2D.new ()
  self.gfxQuad:setTexture ( sprite.src )
  self.gfxQuad:setRect ( sprite:getRect() )

  self.prop = MOAIProp2D.new ()
  self.prop:setDeck ( self.gfxQuad )

  return self
end

function Object:addToLayer ( layer )
  layer:insertProp ( self.prop )
end

function Object:moveTo ( x, y )
  local cx, cy = self.prop:getLoc()
  local angle =  - math.deg ( math.atan ( x / y ) )
  if y < 0 then angle = angle + 180 end
  print (angle)
  self.prop:setRot( angle, 1 )
end

MOAISim.openWindow ( "test", 640, 480 )

viewport = MOAIViewport.new ()
viewport:setSize ( 640, 480 )
viewport:setScale ( 640, 480 )

local layer = MOAILayer2D.new ()
layer:setViewport ( viewport )
MOAISim.pushRenderPass ( layer )

local male = Object:new ( sprites.male )
male:addToLayer ( layer )

local mx, my = 0, 0

function pointerCallback ( x, y )
  mx, my = layer:wndToWorld ( x, y )
end

function clickCallback ( down )
  if not down then
    print (mx, my)
    male:moveTo( mx, my ) 
  end
end

MOAIInputMgr.device.pointer:setCallback ( pointerCallback )
MOAIInputMgr.device.mouseLeft:setCallback ( clickCallback )