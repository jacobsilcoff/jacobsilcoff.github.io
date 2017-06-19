console.log "-----PICO-----"
console.log "Credits:"
console.log "Art --- Fiona Okumu"
console.log "Programming --- Jacob Silcoff"
console.log "Documentation --- Francesca Chu"
console.log "CSGO Analysis --- Freya Ryd"
console.log "Music --- AJ Stensland"

###
_____________________
GRAPHICS
_____________________
###
app = undefined
ASPECT_RATIO = undefined



document.addEventListener 'DOMContentLoaded', (ev) ->
    prepSprites()
    
prepSprites = () ->
    ASPECT_RATIO = 
        width : window.innerWidth
        height : window.innerHeight
    #PIXI.SCALE_MODES.DEFAULT = PIXI.SCALE_MODES.NEAREST
    PIXI.settings.SCALE_MODE = PIXI.SCALE_MODES.NEAREST
    
    app = new PIXI.Application ASPECT_RATIO.width, ASPECT_RATIO.height, {backgroundColor : 0x000000}

    document.body.appendChild app.view
    srcs = [ "boat.png", "Coney1.png",
            "Coney2.png", "Coney3.png", "hook.png", "JackRainbowFish.png",
            "LionFish.png", "MahiMahi.png", "Marlin.png", "SpottedHog.png", "WhaleShark.png",
            "day.png", "GUI.png", "sand.png", "sky.png", "water.png", "sky.png", "waves.png",
            "Bubble.png", "Title.png", "/clouds/0.png", "/clouds/1.png", "/clouds/2.png", 
            "/sky/0.png", "/sky/1.png", "/sky/2.png", "/sky/3.png", "/sky/4.png", "sun.png", "moon.png"]
    i = 0
    for str in srcs
        do =>
            tex = PIXI.Texture.fromImage "res/#{str}"
            spr = new PIXI.Sprite(tex);
            tex.addListener 'update', (ev) ->
                i = i + 1
                run() if i >= srcs.length
    
    
run = () ->
    pause = false
    gameStats = 
        fishCaught : 0
        errors : 0
        lionfish : 0
        boosts : 0
        deaths : 0
        
    currentLevelNum = null
    levelActive = false
    gs = null
    
    playThenDoFunction = () -> return
    ###
    _____________________
    Structure
    _____________________
    ###
    
    ###
    Some Math Stuff
    ###
    #ang from a to b
    angTo = (a, b) ->
        if a.x is b.x
            return normalize(if a.y < b.y then Math.PI else -Math.PI)
        ang = Math.atan((b.y - a.y) / (b.x - a.x))
        ang += Math.PI if b.x < a.x
        normalizeAng ang
    distance = (x1, y1, x2, y2) ->
        sqr = (a) -> a * a
        Math.sqrt(sqr(x1 - x2) + sqr(y1 - y2))
    #makes an angle between 0 and 2pi
    normalizeAng = (t) ->
    	t += 2 * Math.PI while t < 0
    	t -= 2 * Math.PI while t > 2 * Math.PI
    	return t
    printAng = (a) ->
        console.log "#{Math.floor(a / Math.PI * 1000) / 1000}pi"
    
    random = (a, b) ->
        Math.floor(Math.random() * (b - a)) + a
        
    clearConsole = () ->
        consl = undefined
        if typeof console._commandLineAPI isnt 'undefined'
            consl = console._commandLineAPI #chrome
        else if typeof console._inspectorCommandLineAPI isnt 'undefined'
            consl = console._inspectorCommandLineAPI #Safari
        else if typeof console.clear isnt 'undefined'
            consl = console
        consl?.clear()

    ###
    Layer groups
    ###
    backgroundLayer = new PIXI.Container()
    fishLayer = new PIXI.Container()
    boatLayer = new PIXI.Container()
    topWaveLayer = new PIXI.Container()
    guiLayer = new PIXI.Container()
    cutScenesLayer = new PIXI.Container()
    
    
    app.stage.addChild(backgroundLayer)
    app.stage.addChild(boatLayer)
    app.stage.addChild(topWaveLayer)
    app.stage.addChild(fishLayer)
    app.stage.addChild(guiLayer)
    app.stage.addChild(cutScenesLayer)
    
    
    
    ###
    Classes
    &
    Vars
    ###
    
    background = null
    title = null
    
    class Background
        @waterLevel : 350
        frontWaveSpeed = 0.5
        backWaveSpeed = 0.3
        waveOffset = 10
        constructor : (@depth) ->
            @water = null
            @frontWaves = null
            @bottom = null
            @sky = null
            
            @draw()
        draw : () ->
            @sky = []
            do =>
                skyNum = if currentLevelNum? then currentLevelNum else 1
                tempSky = PIXI.Sprite.fromImage "res/sky/#{skyNum}.png"
                tempSky.x = 0
                tempSky.y = -5
                tempSky.width = ASPECT_RATIO.width
                tempSky.height = Background.waterLevel + 10
                backgroundLayer.addChild tempSky
                @sky.push tempSky
            
        
            currentLevelNum = 1 unless currentLevelNum?
            pos = currentLevelNum / 3 * Math.PI
            sun = null
            if currentLevelNum is 4
                sun = PIXI.Sprite.fromImage "res/moon.png"
                sun.scale.set 10
                pos = 3/4 * Math.PI
            else
                sun = PIXI.Sprite.fromImage "res/sun.png"
            sun.anchor.set .5
            sun.x = ASPECT_RATIO.width / 2 - Math.cos(pos) * (ASPECT_RATIO.width / 3)
            sun.y = Background.waterLevel - 75 - Math.sin(pos) * (Background.waterLevel - 75)
            console.log ("#{sun.x}, #{sun.y}")
            console.log "num: #{currentLevelNum}"
            backgroundLayer.addChild(sun)
            @sky.push sun
            for i in [0... 3]
                spr = PIXI.Sprite.fromImage "res/clouds/#{i}.png"
                spr.anchor.set(.5, 1) 
                spr.x = random(0, ASPECT_RATIO.width)
                spr.y = random(5, Background.waterLevel - 10)
                backgroundLayer.addChild(spr)
                @sky.push(spr)
        
            @water = PIXI.Sprite.fromImage "res/water.png"
            @water.width = ASPECT_RATIO.width
            @water.height = @depth
            @water.x = 0
            @water.y = Background.waterLevel
            backgroundLayer.addChild @water
            

            @bottom = PIXI.Sprite.fromImage 'res/sand.png'
            scl = ASPECT_RATIO.width / @bottom.width
            @bottom.scale.set(scl)
            @bottom.anchor.set 0, 1
            @bottom.x = 0
            @bottom.y = @depth + @water.y
            
            backgroundLayer.addChild @bottom
            
            @frontWaves = []
            @backWaves = []
            waveScale = 2
            x = -(waveScale * (new PIXI.Sprite.fromImage 'res/waves.png').width)
            i = 0
            while (x < ASPECT_RATIO.width)
                t.push new PIXI.Sprite.fromImage 'res/waves.png' for t in [@frontWaves, @backWaves]
                t[i].scale.set(waveScale)  for t in [@frontWaves, @backWaves]
                t[i].anchor.set 0, 1  for t in [@frontWaves, @backWaves]
                t[i].x = x for t in [@frontWaves, @backWaves]
                @frontWaves[i].y = Background.waterLevel + waveOffset
                @backWaves[i].y = Background.waterLevel
                topWaveLayer.addChild @frontWaves[i]
                backgroundLayer.addChild @backWaves[i]
                x += @frontWaves[i].width
                i++
        
        update : () ->
            w.x += frontWaveSpeed for w in @frontWaves
            w.x += backWaveSpeed for w in @backWaves
            
            for l in [@frontWaves, @backWaves]
                for wave in l
                    if wave.x > ASPECT_RATIO.width
                        minX = 0
                        minX = Math.min(w.x, minX) for w in l
                        wave.x = minX - wave.width
                        break
                    
            
        move : (x, y) ->
            @water.x += x
            @water.y += y
            @bottom.x += x
            @bottom.y += y
            wave.x += x for wave in @frontWaves
            wave.y += y for wave in @frontWaves
            wave.x += x for wave in @backWaves
            wave.y += y for wave in @backWaves
            el.x += x for el in @sky
            el.y += y for el in @sky
        clear : () ->
            backgroundLayer.removeChild @water
            topWaveLayer.removeChild wave for wave in @frontWaves
            backgroundLayer.removeChild wave for wave in @backWaves
            backgroundLayer.removeChild @bottom
            backgroundLayer.removeChild el for el in @sky
        reset : () ->
            @water.y = Background.waterLevel
            wave.y = Background.waterLevel + waveOffset for wave in @frontWaves
            wave.y = Background.waterLevel for wave in @backWaves
            @bottom.y = @water.y + @depth
    
    
    fish = []
    bubbles = []
    displSprites = []
    
    
    class Hook
        hookScale = .2
        boatScale = 8
        padding = 100
        boostAudio = new Audio 'res/Boost.mp3'
        @speed : 5
        constructor : () ->
            @velocity = new PIXI.Point(0, 0)
            @boostCount = 0
            @lineTool = new PIXI.Graphics
            
            @hookSprite = PIXI.Sprite.fromImage 'res/hook.png'
            @hookSprite.scale.x = @hookSprite.scale.y = hookScale
            @hookSprite.anchor.set .5
            
            @boatSprite = PIXI.Sprite.fromImage 'res/boat.png'
            @boatSprite.scale.x = @boatSprite.scale.y = boatScale
            @boatSprite.scale.x *= -1
            @boatSprite.anchor.set .5, 1
            
            @boatSprite.x = @hookSprite.x = ASPECT_RATIO.width / 2
            @boatSprite.y = Background.waterLevel
            @hookSprite.y = @boatSprite.y + 100
            
            @boostFilter = new PIXI.filters.ColorMatrixFilter()
            
            boatLayer.addChild @hookSprite
            boatLayer.addChild @boatSprite
            boatLayer.addChild @lineTool
            
            @drawLine()
            
            @realY = @hookSprite.y
        update : () ->
            if @boostCount > 0
                @boostCount--
                @hookSprite.filters = [@boostFilter]
                mat = @boostFilter.matrix
                mat[1] = Math.sin(@boostCount / 10) * 3
                mat[2] = Math.cos(@boostCount / 10)
                mat[3] = Math.cos(@boostCount / 10) * 1.5
                mat[4] = Math.sin(@boostCount / 30) * 2
                mat[5] = Math.sin(@boostCount / 20)
                mat[6] = Math.sin(@boostCount / 40)
            else
                @hookSprite.filters = null
            if fishCaught.LionFish >= 10
                fishCaught.LionFish = 0
                gameStats.boosts++
                boostAudio.load()
                boostAudio.play()
                @boostCount = 1000
                
            
        move : (x, y) ->
            x *= 2 if @boostCount > 0
            y *= 2 if @boostCount > 0
            #here I round input because fuck me
            y = Math.floor(y * 1000) / 1000
            
            if 0 < @boatSprite.x + x < ASPECT_RATIO.width and x isnt 0
                @boatSprite.x += x
                @hookSprite.x += x
                @boatSprite.scale.x *= -1 if (x > 0) isnt (@boatSprite.scale.x < 0)
             
            hy = @hookSprite.y
            if (hy > padding + @boatSprite.y or y > 0) and (hy <= ASPECT_RATIO.height - padding or y < 0) and @realY <= hy
                @hookSprite.y += y
                @realY = @hookSprite.y
                background.reset()
                @boatSprite.y = Background.waterLevel
            else if hy >= ASPECT_RATIO.height - padding and (y < 0 or hy + padding <= background.water.y + background.depth)
                @realY += y
                @boatSprite.y = Math.floor((@boatSprite.y - y) * 1000) / 1000
                background.move(0, -y)
                f.y -= y for f in fish
                b.spr.y -= y for b in bubbles
            @drawLine()
        #doesn't work at all
        drawLine : () ->
            thickness = 1
            color = 0xffd900
            xShift = 0
            yShift = -26
            @lineTool.clear()
            @lineTool.lineStyle(thickness, color, 1);
            
            
            #@lineTool.moveTo @boatSprite.x + xShift, @boatSprite.y #boatpos
            dir = Math.abs(@boatSprite.scale.x) / @boatSprite.scale.x
            x1 = @boatSprite.x + (@boatSprite.width / 2 * .97)* dir
            y1 = @boatSprite.y - @boatSprite.height * .67
            @lineTool.moveTo x1, y1
            
            @lineTool.bezierCurveTo x1, y1, x1, @hookSprite.y, @hookSprite.x + xShift, @hookSprite.y + yShift  #hookpos

        clear : () ->
            @lineTool.clear()
            boatLayer.removeChild @hookSprite
            boatLayer.removeChild @boatSprite


    hook = new Hook()
    relocateHook = () ->
        hook.boatSprite.y = Background.waterLevel
    
    fishCaught =
        Coney1 : 0
        Coney2 : 0
        Coney3 : 0
        JackRainbowFish : 0
        LionFish : 0
        MahiMahi : 0
        Marlin : 0
        SpottedHog : 0
        WhaleShark : 0
        
    class Bubble
        constructor : (x, y) ->
            sizeRange = [10, 30]
            @spr = PIXI.Sprite.fromImage 'res/Bubble.png'
            @spr.x = x
            @spr.y = y
            @spr.width = @spr.height = random(sizeRange[0], sizeRange[1])
            bubbles.push this
            fishLayer.addChild @spr
        update : () ->
            @spr.x += random(0, 4) - 2
            @spr.y -= 3
            if @spr.y < background.water.y
                @clear()
        clear : () ->
            pop = new Audio 'res/pop.wav'
            pop.play()
            fishLayer.removeChild @spr
            bubbles.splice bubbles.indexOf(this), 1
            
            
    class Fish extends PIXI.Container
        padding = 100
        constructor : (@title = false) ->
            super()
            @size = 1
            fishLayer.addChild this
            @x = @y = undefined
            @rotation = 0
            xvals = [-padding, ASPECT_RATIO.width + padding]
            until @x? and @y? and distance(@x, @y, hook.hookSprite.x, hook.hookSprite.y) > 200
                r = random 0,2
                if @title
                    @rotation = Math.PI * r
                @x = xvals[r]
                @y = random(background.water.y + 10, background.water.y + background.depth)
            #@rotation = Math.random() * 2 * Math.PI
            @height = 20
            @width = 20
            @speed = (Math.random()) + 1
            @turnRad = 0.1
            @sprite = undefined
            @tracking = true
        draw : () ->
            @sprite.anchor.set .5
            @sprite.x = @sprite.y = 0
            @sprite.scale.x *= @size
            @sprite.scale.y *= @size
            @addChild @sprite
        update : () ->
            if not @title
                @rotation = normalizeAng @rotation
                @x += @speed * Math.cos @rotation
                @y += @speed * Math.sin @rotation if (@y > padding + background.water.y) or (Math.sin(@rotation) >= 0) #check angles
                if @tracking# chases boat
                    #clean up this logic later please
                    aim = angTo this, hook.hookSprite
                    @rotation += @turnRad if ((aim - @rotation) + 2 * Math.PI) % (2 * Math.PI) < Math.PI
                    @rotation -= @turnRad if ((aim - @rotation) + 2 * Math.PI) % (2 * Math.PI) > Math.PI
                    @rotation = aim if Math.abs(aim - @rotation) < @turnRad or 2*Math.PI - Math.abs(aim - @rotation) < @turnRad
                else #skims surface
                    @rotation = if Math.PI > @rotation > Math.PI / 2 then Math.PI else 0
                    @rotation = Math.PI if @x >= ASPECT_RATIO.width
                    @rotation = 0 if @x <= 0
                @sprite.scale.y *= -1 if (Math.PI * 3 / 2> @rotation > Math.PI / 2) isnt (@sprite.scale.y < 0)
                if @sprite.containsPoint new PIXI.Point(hook.hookSprite.x, hook.hookSprite.y) #work on this
                    @getCaught()
            else
                @sprite.scale.y *= -1 if (Math.PI * 3 / 2> @rotation > Math.PI / 2) isnt (@sprite.scale.y < 0)
                @rotation = normalizeAng @rotation
                @x += @speed * Math.cos @rotation
                @rotation += Math.PI if (@x < -@sprite.width or @x > ASPECT_RATIO.width + @sprite.width)
                
            if (random(0, 1000) < 5)
                lim = random(3, 6)
                for i in [0, lim]
                    new Bubble(@x, @y + i * 5)
        getCaught : () ->
            fish.splice fish.indexOf(this), 1
            @clear()
        clear : () ->
            @removeChild @sprite
            @destroy
        print : () ->
            console.log "FISH"
            
    class JackRainbowFish extends Fish
        scl = 0.6
        constructor : (b = false) ->
            super(b)
            @speed = (Math.random()) + 2.5
            @turnRad = 0.03
            @sprite = PIXI.Sprite.fromImage 'res/JackRainbowFish.png'
            @sprite.scale.x *= scl
            @sprite.scale.y *= scl
            @sprite.scale.x *= -1
            @draw()
        print : () ->
            console.log "JACKFISH"
        getCaught : () ->
            super()
            fishCaught.JackRainbowFish++
            
            displayCatch "JackRainbowFish"
    class Marlin extends Fish
        scl = 1
        constructor : (b = false) ->
            super(b)
            @speed = (Math.random()) + 3
            @turnRad = 0.06
            @sprite = PIXI.Sprite.fromImage 'res/Marlin.png'
            @sprite.scale.x *= scl
            @sprite.scale.y *= scl
            @sprite.scale.x *= -1
            
            @draw()
        print : () ->
            console.log "MARLIN"
        getCaught : () ->
            super()
            fishCaught.Marlin++
            
            displayCatch "Marlin"
    class Coney1 extends Fish
        scl = 0.3
        constructor : (b = false) ->
            super(b)
            @speed = (Math.random()) + 1.5
            @turnRad = 0.02
            @sprite = PIXI.Sprite.fromImage 'res/Coney1.png'
            @sprite.scale.x *= scl
            @sprite.scale.y *= scl
            @sprite.scale.x *= -1
            @draw()
        print : () ->
            console.log "Coney 1"
        getCaught : () ->
            super()
            fishCaught.Coney1++
            
            displayCatch "Coney1"
    class Coney2 extends Fish
        scl = 0.3
        constructor : (b = false) ->
            super(b)
            @speed = (Math.random()) + 1.5
            @turnRad = 0.02
            @sprite = PIXI.Sprite.fromImage 'res/Coney2.png'
            @sprite.scale.x *= scl
            @sprite.scale.y *= scl
            @sprite.scale.x *= -1
            @draw()
        print : () ->
            console.log "Coney 2"
        getCaught : () ->
            super()
            fishCaught.Coney2++
            
            displayCatch "Coney2"
    class Coney3 extends Fish
        scl = 0.2
        constructor : (b = false) ->
            super(b)
            @speed = (Math.random()) + 1.5
            @turnRad = 0.05
            @sprite = PIXI.Sprite.fromImage 'res/Coney3.png'
            @sprite.scale.x *= scl
            @sprite.scale.y *= scl
            @sprite.scale.x *= -1
            @draw()
        print : () ->
            console.log "Coney 3"
        getCaught : () ->
            super()
            fishCaught.Coney3++
            
            displayCatch "Coney3"
    class LionFish extends Fish
        scl = 0.5
        constructor : (b = false) ->
            super(b)
            @speed = (Math.random()) + 1
            @turnRad = 0.07
            @sprite = PIXI.Sprite.fromImage 'res/LionFish.png'
            @sprite.scale.x *= -1
            @sprite.scale.x *= scl
            @sprite.scale.y *= scl
            @draw()
        print : () ->
            console.log "Lion Fish"
        getCaught : () ->
            super()
            fishCaught.LionFish++
            
            displayCatch "LionFish"
    class SpottedHog extends Fish
        scl = 0.2
        constructor : (b = false) ->
            super(b)
            @speed = (Math.random()) + 2
            @turnRad = 0.05
            @sprite = PIXI.Sprite.fromImage 'res/SpottedHog.png'
            @sprite.scale.x *= scl
            @sprite.scale.y *= scl
            @sprite.scale.x *= -1
            @draw()
        print : () ->
            console.log "SPOTTED HOG"
        getCaught : () ->
            super()
            fishCaught.SpottedHog++
            
            displayCatch "SpottedHog"
    class MahiMahi extends Fish
        scl = .75
        constructor : (b = false) ->
            super(b)
            @speed = (Math.random()) + 1.5
            @turnRad = 0.01
            @sprite = PIXI.Sprite.fromImage 'res/MahiMahi.png'
            @sprite.scale.x *= scl
            @sprite.scale.y *= scl
            @sprite.scale.x *= -1
            @draw()
        print : () ->
            console.log "MahiMahi"
        getCaught : () ->
            super()
            fishCaught.MahiMahi++
            
            displayCatch "MahiMahi"
    class WhaleShark extends Fish
        scl = 0.9
        constructor : (b = false) ->
            super(b)
            @speed = (Math.random()) + 2
            @turnRad = 0.01
            @sprite = PIXI.Sprite.fromImage 'res/WhaleShark.png'
            @sprite.scale.x *= scl
            @sprite.scale.y *= scl
            @sprite.scale.x *= -1
            @draw()
        print : () ->
            console.log "Whale Shark"
        getCaught : () ->
            super()
            fishCaught.WhaleShark++
            
            displayCatch "WhaleShark"
    
    
    class Level
        @numLevels : 5
        constructor : (num) ->
            if num is 0
                @spawnRates =
                   	Coney1 : 2
                    Coney2 : 2
                    Coney3 : 2
                    JackRainbowFish : 0
                    LionFish : 2
                    MahiMahi : 0
                    Marlin : 0
                    SpottedHog : 2
                    WhaleShark : 0
                @goals =
                 	Coney1 : 2
                 	Coney2 : 2
                 	Coney3 : 2
                 	JackRainbowFish : 0
                 	MahiMahi : 0
                 	Marlin : 0
                 	SpottedHog : 0
                 	WhaleShark : 0
                @depth = 1000
            if num is 1
                @spawnRates =
                   	Coney1 : 2
                    Coney2 : 2
                    Coney3 : 2
                    JackRainbowFish : 1
                    LionFish : 2
                    MahiMahi : 1
                    Marlin : 0
                    SpottedHog : 1
                    WhaleShark : 0
                @goals =
                    Coney1 : 2
                    Coney2 : 2
                    Coney3 : 2
                    JackRainbowFish : 0
                    MahiMahi : 1
                    Marlin : 0
                    SpottedHog : 0
                    WhaleShark : 0
                @depth = 1500
            if num is 2
                @spawnRates =
                   	Coney1 : 2
                    Coney2 : 1
                    Coney3 : 1
                   	JackRainbowFish : 1
                    LionFish : 2
                    MahiMahi : 1
                    Marlin : 0
                    SpottedHog : 4
                    WhaleShark : 0
                @goals =
                    Coney1 : 1
                    Coney2 : 1
                    Coney3 : 1
                   	JackRainbowFish : 0
                    MahiMahi : 0
                    Marlin : 0
                    SpottedHog : 4
                    WhaleShark : 0
                @depth = 1750
            if num is 3
                @spawnRates =
                   	Coney1 : 2
                    Coney2 : 1
                    Coney3 : 1
                   	JackRainbowFish : 3
                    LionFish : 2
                    MahiMahi : 2
                    Marlin : 0
                    SpottedHog : 2
                    WhaleShark : 3
                @goals =
                    Coney1 : 2
                    Coney2 : 1
                    Coney3 : 1
                   	JackRainbowFish : 2
                    MahiMahi : 2
                    Marlin : 0
                    SpottedHog : 0
                    WhaleShark : 0
                @depth = 2000
            if num is 4
                @spawnRates =
                   	Coney1 : 1
                    Coney2 : 1
                    Coney3 : 2
                   	JackRainbowFish : 2
                    LionFish : 2
                    MahiMahi : 2
                    Marlin : 2
                    SpottedHog : 2
                    WhaleShark : 3
                @goals =
                    Coney1 : 1
                    Coney2 : 1
                    Coney3 : 2
                   	JackRainbowFish : 1
                    MahiMahi : 0
                    Marlin : 1
                    SpottedHog : 2
                    WhaleShark : 0
                @depth = 1750
                

    
    checkLevelWon = () ->
        return unless currentLevel? and fishCaught?
        for type, val of currentLevel.goals
            if fishCaught[type] < val
                return
        winLevel()
    
    document.addEventListener 'keydown', (event) ->
        hook.velocity.x = -Hook.speed if event.keyCode is 37 #left
        hook.velocity.x = Hook.speed if event.keyCode is 39 #right
        hook.velocity.y = -Hook.speed if event.keyCode is 38 #up
        hook.velocity.y = Hook.speed if event.keyCode is 40 #down
        #fishCaught.LionFish = 10 if event.keyCode is 32 #spacebar
    document.addEventListener 'keyup', (event) ->
        hook.velocity.x = 0 if (event.keyCode is 37 and hook.velocity.x < 0) or (event.keyCode is 39 and hook.velocity.x > 0)
        hook.velocity.y = 0 if (event.keyCode is 38 and hook.velocity.y < 0) or (event.keyCode is 40 and hook.velocity.y >0)
    document.addEventListener 'keypress', (event) ->
        gs?.finish()
        playThenDoFunction() unless levelActive
        pause = !pause if event.keyCode is 112
        
        startPlayingLevel currentLevelNum if event.keyCode is 8 #backspace
        winLevel() if levelActive and event.keyCode is 78 #n
        
    currentLevel = new Level 0
    
    clearScreen = () ->
        fish = []
        bubbles = []
        displSprites = [] #doubt this will cause problems?
        l.removeChildren() for l in [guiLayer, fishLayer, topWaveLayer, backgroundLayer, boatLayer, cutScenesLayer]
        gui?.clear()

    
    class TitleScreen
        constructor : () ->
            for type, val of gameStats
                gameStats[type] = 0
            background = new Background(ASPECT_RATIO.height - Background.waterLevel + 70)
            
            fish.push new JackRainbowFish(true) if random(0, 2) is 0
            fish.push new Marlin(true) if random(0, 2) is 0
            fish.push new Coney1(true) if random(0, 2) is 0
            fish.push new Coney2(true) if random(0, 2) is 0
            fish.push new Coney3(true) if random(0, 2) is 0
            fish.push new LionFish(true) if random(0, 2) is 0
            fish.push new SpottedHog(true) if random(0, 2) is 0
            fish.push new MahiMahi(true) if random(0, 2) is 0
            fish.push new WhaleShark(true) if random(0, 2) is 0
            
            titleSprite = PIXI.Sprite.fromImage "res/Title.png"
            scl = ASPECT_RATIO.width * 2 / 3 / titleSprite.width
            titleSprite.scale.set(scl)
            titleSprite.anchor.set .5
            titleSprite.x = ASPECT_RATIO.width/2
            titleSprite.y = ASPECT_RATIO.height/2
            
            guiLayer.addChild titleSprite
            
            regStyle = new PIXI.TextStyle {
                fontSize : 60
                fontFamily : "'Press Start 2P', cursive"
                fill: "#ffffff"
                stroke: "#000000"
                strokeThickness : 5
            }
            
            bigStyle = new PIXI.TextStyle {
                fontSize : 72
                fontFamily : "'Press Start 2P', cursive"
                fill: "#ffffff"
                stroke: "#000000"
                strokeThickness : 5
            }
            
            @playButton = new PIXI.Text "PLAY", regStyle
            @tutorialButton = new PIXI.Text "HOW TO", regStyle
            titleSprite.y -= @playButton.height
            for k in [@playButton, @tutorialButton]
                k.interactive = true
                k.buttonMode = true
                k.anchor.set .5
                k.y = titleSprite.y + titleSprite.height / 2 + k.height / 2 + 10
                guiLayer.addChild(k)
            
            @playButton.x = ASPECT_RATIO.width * 1 / 4
            @tutorialButton.x = ASPECT_RATIO.width * 3 / 4
            
            @playButton.on('pointerover', () => @playButton.style = bigStyle; (new Audio 'res/Click.mp3').play())
            @playButton.on('pointerout', () => @playButton.style = regStyle)
            @playButton.on('pointerdown', () -> 
                                            startLevel 0
                                            )
            @tutorialButton.on('pointerover', () => @tutorialButton.style = bigStyle; (new Audio 'res/Click.mp3').play())
            @tutorialButton.on('pointerout', () => @tutorialButton.style = regStyle)
            
    class GameSummary
        levelActive = false
        scrollRate = 1.5
        padding = 50
        constructor : () ->
            clearScreen()
            style = new PIXI.TextStyle {
                fontSize : 36
                fontFamily : "'Press Start 2P', cursive"
                fill: "#ffffff"
                stroke: "#000000"
                strokeThickness : 5
                wordWrap : true
                wordWrapWidth : ASPECT_RATIO.width - 50
            }
            strings = ["---- GAME STATS ----",
                        "FISH CAUGHT: #{gameStats.fishCaught}",
                        "ERRORS: #{gameStats.errors}",
                        "LION FISH CAUGHT: #{gameStats.lionfish}",
                        "BOOSTS ACQUIRED: #{gameStats.boosts}",
                        "DEATHS: #{gameStats.deaths}",
                        "",
                        "---- CREDITS ----",
                        "ART: FIONA OKUMU",
                        "PROGRAMMING: JACOB SILCOFF",
                        "MUSIC: AJ STENSLAND",
                        "DOCUMENTATION: FRANCESCA CHU"
                        "BEING/KNOWING/DOING: FREYA RYD",
                        "",
                        "Submitted to the 2017 National TSA Conference in Orlando, Florida,
                        as an entry in the Video Game competition"]
            @text = []
            @text.push new PIXI.Text str, style for str in strings
            t.anchor.set .5 for t in @text
            cutScenesLayer.addChild t for t in @text
            t.y = ASPECT_RATIO.height for t in @text
            t.x = ASPECT_RATIO.width / 2 for t in @text
            i = 0
            for t in @text
                t.y += (@text[0].height + padding) * i
                i++
            
        update : () ->
            t.y -= scrollRate for t in @text
            @finish() if @text[@text.length - 1].y <= -50
        finish : () ->
            clearScreen()
            gs = null
            new TitleScreen
            
            
    
    class GUI
        constructor : () ->
            @box = PIXI.Sprite.fromImage 'res/GUI.png'
            @box.x = 0
            @box.y = 0
            @box.alpha = .9
            guiLayer.addChild @box
            
            @gd = new GoalDisplay()
            @dd = new DeathDisplay()
        update : () ->
            @gd.update()
            #@dd.update()
        clear : () ->
            @gd.clear()
            @dd.clear()
            guiLayer.removeChild @box
    
    class GoalDisplay extends PIXI.Container
        itemWidth = 60
        itemPaddingX = 5
        itemPaddingY = -7
        itemsPerLine = 4
        constructor : () ->
            super()
            guiLayer.addChild this
            @sprites = []
            @x = 20
            @y = 55
            for type, val of currentLevel.goals
                for i in [0...val]
                    spr = PIXI.Sprite.fromImage "res/#{type}.png"
                    scl = itemWidth / spr.width
                    spr.scale.set(scl)
                    @addChild spr
                    @sprites.push spr
                    spr.alpha = .25
                    spr.x = (itemPaddingX + itemWidth) * ((@sprites.length - 1) % itemsPerLine)
                    spr.y = (itemPaddingY + itemWidth) * ((@sprites.length - 1) // itemsPerLine)
        update : () ->
            index = 0
            for type, val of currentLevel.goals
                count = if fishCaught? then fishCaught[type] else 0
                for i in [0...val]
                    @sprites[index].alpha = 1 if count > 0
                    count--
                    index++
        clear : () ->
            @removeChild spr for spr in @sprites
            @destroy
    
    class DeathDisplay extends PIXI.Container
        @itemWidth : 70 
        @itemPadding : 10
        constructor : () ->
            super()
            guiLayer.addChild this
            @sprites = []
            @x = 26
            @y = 214
        add : (type) ->
            if @sprites.length >= 3
                loseLevel(currentLevelNum)
                console.log "death"
                return
            spr = PIXI.Sprite.fromImage "res/#{type}.png"
            scl = DeathDisplay.itemWidth / spr.width
            spr.scale.set scl
            @addChild spr
            @sprites.push spr
            spr.y = 0
            spr.x = (DeathDisplay.itemPadding + DeathDisplay.itemWidth) * (@sprites.length - 1)
        clear : () ->
            @removeChild spr for spr in @sprites
            @destroy
            
            
    gui = undefined
    
    music = new Audio 'res/MainLoop.mp3'
    ```
    music.loop = true;
    
    ```
    
    
    playThenDo = (videoSrc, task) ->
        clearScreen()
        levelActive = false
        tex = PIXI.Texture.fromVideo videoSrc
        vid = new PIXI.Sprite tex
        vid.width = ASPECT_RATIO.width
        vid.height = ASPECT_RATIO.height
        cutScenesLayer.addChild vid
        playThenDoFunction = () ->
            playThenDoFunction = () -> return
            tex.baseTexture.source.pause()
            clearScreen()
            task()
        tex.baseTexture.source.addEventListener('ended',
            () ->
                playThenDoFunction() 
        )
        
    startLevel = (n) ->
        playThenDo("res/vids/o#{n}.mp4",
            () ->
                startPlayingLevel(n)
        )
    
    startPlayingLevel = (n) ->
        music.load()
        music.play()
        currentLevelNum = n
        currentLevel = new Level n
        clearScreen()
        
        background = new Background(currentLevel.depth)
        fish = []
        bubbles = []
        fishCaught[type] = 0 for type of fishCaught
        hook = new Hook()
        gui = new GUI()
        displayLevel()
        levelActive = true
        
    nextLevel = () ->
        if currentLevelNum + 1 < Level.numLevels
            currentLevelNum++
            startLevel currentLevelNum
        else
            currentLevelNum = null
            playThenDo("res/vids/game over.mp4", () -> gs = new GameSummary)
    
    winLevel = () ->
        music.pause()
        playThenDo("res/vids/w#{currentLevelNum}.mp4", () -> 
            nextLevel()
        )
    
    loseLevel = () ->
        gameStats.deaths++
        n = currentLevelNum
        music.pause()
        playThenDo("res/vids/l#{n}.mp4", () ->
            startPlayingLevel(n)
        )
        
    
    #startLevel currentLevelNum

    addFish = () ->
        lim = 2000
        spreadRate = 7
        lionCount = 0
        (lionCount += 1 if i instanceof LionFish) for i in fish
        #replace fish w/ lion fish
        replace fish[random 0, fish.length] if lionCount * spreadRate > random 0, lim
        
        fish.push new Coney1 if currentLevel.spawnRates.Coney1 > random 0, lim
        fish.push new Coney2 if currentLevel.spawnRates.Coney2 > random 0, lim
        fish.push new Coney3 if currentLevel.spawnRates.Coney3 > random 0, lim
        fish.push new SpottedHog if currentLevel.spawnRates.SpottedHog > random 0, lim
        fish.push new MahiMahi if currentLevel.spawnRates.MahiMahi > random 0, lim
        fish.push new WhaleShark if currentLevel.spawnRates.WhaleShark > random 0, lim
        fish.push new Marlin if currentLevel.spawnRates.Marlin > random 0, lim
        fish.push new JackRainbowFish if currentLevel.spawnRates.JackRainbowFish > random 0, lim
        fish.push new LionFish if currentLevel.spawnRates.LionFish > random 0, lim
        
    replace = (fsh) ->
        lion = new LionFish()
        fish.push lion
        lion.x = fsh.x
        lion.y = fsh.y
        lion.rotation = fsh.rotation
        fish.splice fish.indexOf(fsh), 1
        fsh.clear()

    
    pickupAudio = new Audio 'res/pickup.wav'
    toomanyAudio = new Audio 'res/buzzer.mp3'
    ```
    pickupAudio.loop = false
    toomanyAudio.loop = false
    ```
    displayLevel = () ->
        str = "LEVEL #{currentLevelNum + 1}"
        style = new PIXI.TextStyle {
            fontSize : 72
            fontFamily : "'Press Start 2P', cursive"
            fill: "#ffffff"
            stroke: "#000000"
            strokeThickness : 5
        }
        txt = new PIXI.Text str, style
         
        displSprites.push txt
        guiLayer.addChild txt
        txt.anchor.set(.5, .5)
        txt.y = ASPECT_RATIO.height / 2
        txt.x = ASPECT_RATIO.width / 2
        
    displayCatch = (type) ->
        gameStats.fishCaught++
        padding = 50
        if ((not currentLevel.goals[type]?) or currentLevel.goals[type] < fishCaught[type]) and type isnt "LionFish"
            str = "TOO MANY CAUGHT" 
            gameStats.errors++
            gui.dd.add type
            toomanyAudio.play()
        else
            pickupAudio.play()
            str = "#{fishCaught[type]}"
            #str = "#{str} of #{currentLevel.limits[type]} max" if currentLevel.limits[type]?
            if type is "LionFish"
                str = "#{str}/10 FOR BOOST" 
                gameStats.lionfish++
            str = "#{str}/#{currentLevel.goals[type]} caught" if currentLevel.goals[type]? and currentLevel.goals[type] >= fishCaught[type]
        style = new PIXI.TextStyle {
                fontSize : 36
                fontFamily : "'Press Start 2P', cursive"
                wordWrap : true
                wordWrapWidth : (ASPECT_RATIO.width / 2 - padding * 1.5)
                fill: "#ffffff"
                stroke: "#000000"
                strokeThickness : 5
            }
        txt = new PIXI.Text str, style
        sprite = PIXI.Sprite.fromImage "res/#{type}.png"
        for i in [sprite, txt]
            displSprites.push i
            guiLayer.addChild i
            i.anchor.set(0, .5)
            i.y = ASPECT_RATIO.height / 2
        scl = (ASPECT_RATIO.width / 2 - padding * 1.5) / sprite.width
        sprite.width *= scl
        sprite.height *= scl
        sprite.x = padding
        txt.x = ASPECT_RATIO.width / 2 + padding * .5
        checkLevelWon()
        
    clearScreen()
    playThenDo("res/vids/logo.mp4", () -> 
        playThenDo("res/vids/intro.mp4", () ->
            new TitleScreen()))
    
    app.ticker.add (delta) ->
        if !pause
            f?.update() for f in fish
            b?.update() for b in bubbles
            background?.update()
            gs?.update()
            
            if levelActive
                hook.update()  
                hook.move hook.velocity.x * delta, hook.velocity.y * delta
                
                addFish()
                
                dimRate = .01
                
                toRemove = []
                for i in displSprites
                    i.alpha -= dimRate * delta if i.alpha?
                    if not (i.alpha? and i.alpha >= 0)
                        guiLayer.removeChild i 
                        toRemove.push i
                displSprites.splice displSprites.indexOf(i), 1 for i in toRemove
                
                gui?.update()
