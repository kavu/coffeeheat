((w) ->

  heatmapFactory = (() ->

    class Store
      constructor: (hmap) ->
        @max = 1
        _ =
          data: []
          heatmap: hmap

        @get = (key) ->
          _[key]

        @set = (key, value) ->
          _[key] = value
          return

      addDataPoint: (x, y) ->
        return if x < 0 or y < 0
        heatmap = @get("heatmap")
        data = @get("data")

        data[x] = [] if !data[x]
        data[x][y] = 0 if !data[x][y]
        data[x][y] += (if arguments.length < 3 then 1 else arguments[2])

        @set("data", data)

        if @max < data[x][y]
           @max = data[x][y]
           heatmap.get("actx").clearRect(0, 0, heatmap.get("width"), heatmap.get("height"))
           for one of data
             for two of data[one]
               heatmap.drawAlpha(one, two, data[one][two])
           return

        heatmap.drawAlpha(x, y, data[x][y])
        return

      setDataSet: (obj) ->
        heatmap = @get("heatmap")
        data = []
        d = obj.data
        dlen = d.length

        heatmap.clear()
        @max = obj.max

        while dlen--
          point = d[dlen]
          heatmap.drawAlpha point.x, point.y, point.count
          data[point.x] = [] unless data[point.x]
          data[point.x][point.y] = 0 unless data[point.x][point.y]
          data[point.x][point.y] = point.count

        @set "data", data
        return

      exportDataSet: () ->
        data = @get("data")
        exportData = []
        for one of data
          continue if one is 'undefined'
          for two of data[one]
            continue  if two is 'undefined'
            exportData.push
              x: parseInt(one, 10)
              y: parseInt(two, 10)
              count: data[one][two]

        max: @max
        data: exportData

      generateRandomDataSet: (points) ->
        heatmap = @get("heatmap")
        max = Math.floor(Math.random()*1000+1)

        data = []
        while points--
          data.push(
            x: Math.floor(Math.random()*heatmap.get("width")+1)
            y: Math.floor(Math.random()*heatmap.get("height")+1)
            count: Math.floor(Math.random()*max+1)
          )

        @setDataSet
          max: max
          data: data

        return

    class Heatmap
      constructor: (config) ->
        _ =
          radiusIn: 20
          radiusOut: 40
          element: {}
          canvas: {}
          acanvas: {}
          ctx: {}
          actx: {}
          visible: true
          width: 0
          height: 0
          max: false
          gradient: false
          opacity: 180
          premultiplyAlpha: false
          debug: false

        @store = new Store(this)
        @get = (key) ->
          _[key]

        @set = (key, value) ->
          _[key] = value
          return

        @configure config
        @init()

      configure: (config) ->
        if config.radius
          rout = config.radius
          rin = parseInt(rout / 4, 10)
        @set "radiusIn", rin or 15
        @set "radiusOut", rout or 40
        @set "element", (if (config.element instanceof Object) then config.element else document.getElementById(config.element))
        @set "visible", config.visible
        @set "max", config.max or false

        @set("gradient", config.gradient or
          {
            0.45: "rgb(0,0,255)"
            0.55: "rgb(0,255,255)"
            0.65: "rgb(0,255,0)"
            0.95: "yellow"
            1.0: "rgb(255,0,0)"
          }
        )

        @set "opacity", parseInt(255 / (100 / config.opacity), 10) or 180
        @set "width", config.width or 0
        @set "height", config.height or 0
        @set "debug", config.debug
        return

      resize: ->
        element = @get("element")
        canvas = @get("canvas")
        acanvas = @get("acanvas")
        canvas.width = acanvas.width = element.style.width.replace(/px/, "") or @getWidth(element)
        @set "width", canvas.width
        canvas.height = acanvas.height = element.style.height.replace(/px/, "") or @getHeight(element)
        @set "height", canvas.height
        return

      init: ->
        canvas = document.createElement("canvas")
        acanvas = document.createElement("canvas")
        element = @get("element")

        @initColorPalette()

        @set "canvas", canvas
        @set "acanvas", acanvas

        @resize()

        canvas.style.position = acanvas.style.position = "absolute"
        canvas.style.top = acanvas.style.top = "0"
        canvas.style.left = acanvas.style.left = "0"
        canvas.style.zIndex = 1000000
        canvas.style.display = "none" unless @get("visible")

        @get("element").appendChild canvas
        document.body.appendChild acanvas if @get("debug")

        @set "ctx", canvas.getContext("2d")
        @set "actx", acanvas.getContext("2d")
        return

      initColorPalette: ->
        canvas = document.createElement("canvas")
        gradient = @get("gradient")
        canvas.width = "1"
        canvas.height = "256"
        ctx = canvas.getContext("2d")
        grad = ctx.createLinearGradient(0, 0, 1, 256)
        testData = ctx.getImageData(0, 0, 1, 1)
        testData.data[0] = testData.data[3] = 64
        testData.data[1] = testData.data[2] = 0
        ctx.putImageData testData, 0, 0
        testData = ctx.getImageData(0, 0, 1, 1)
        @set "premultiplyAlpha", (testData.data[0] < 60 or testData.data[0] > 70)
        for x of gradient
          grad.addColorStop x, gradient[x]
        ctx.fillStyle = grad
        ctx.fillRect 0, 0, 1, 256
        @set "gradient", ctx.getImageData(0, 0, 1, 256).data
        return

      getWidth: (element) ->
        width = element.offsetWidth
        width += element.style.paddingLeft  if element.style.paddingLeft
        width += element.style.paddingRight  if element.style.paddingRight
        width

      getHeight: (element) ->
        height = element.offsetHeight
        height += element.style.paddingTop  if element.style.paddingTop
        height += element.style.paddingBottom  if element.style.paddingBottom
        height

      colorize: (x, y) ->
        width = @get("width")
        radiusOut = @get("radiusOut")
        height = @get("height")
        actx = @get("actx")
        ctx = @get("ctx")
        x2 = radiusOut * 4
        premultiplyAlpha = @get("premultiplyAlpha")
        palette = @get("gradient")
        opacity = @get("opacity")
        x = width - x2 if x + x2 > width
        x = 0 if x < 0
        y = 0 if y < 0
        y = height - x2 if y + x2 > height
        image = actx.getImageData(x, y, x2, x2)
        imageData = image.data
        length = imageData.length
        i = 3

        while i < length
          alpha = imageData[i]
          offset = alpha * 4

          continue unless offset?

          finalAlpha = (if (alpha < opacity) then alpha else opacity)
          imageData[i - 3] = palette[offset]
          imageData[i - 2] = palette[offset + 1]
          imageData[i - 1] = palette[offset + 2]
          if premultiplyAlpha
            imageData[i - 3] /= 255 / finalAlpha
            imageData[i - 2] /= 255 / finalAlpha
            imageData[i - 1] /= 255 / finalAlpha
          imageData[i] = finalAlpha
          i += 4

        # FIXME: fix this in Strict Mode
        image.data = imageData
        ctx.putImageData image, x, y
        return

      drawAlpha: (x, y, count) ->
        r2 = @get("radiusOut")
        ctx = @get("actx")
        ctx.shadowOffsetX = 1000
        ctx.shadowOffsetY = 1000
        ctx.shadowBlur = 15
        ctx.shadowColor = ("rgba(0,0,0,#{if (count) then (count / @store.max) else "0.1"})")
        ctx.fillStyle = "rgba(0,0,0,1)"
        ctx.beginPath()
        ctx.arc(x - 1000, y - 1000, r2, 0, Math.PI * 2, true)
        ctx.closePath()
        ctx.fill()
        @colorize(x - 2 * r2, y - 2 * r2)
        return

      toggleDisplay: ->
        visible = @get("visible")
        canvas = @get("canvas")
        unless visible
          canvas.style.display = "block"
        else
          canvas.style.display = "none"
        @set "visible", not visible
        return

      getImageData: ->
        @get("canvas").toDataURL()

      clear: ->
        w = @get("width")
        h = @get("height")
        @store.set "data", []
        @get("ctx").clearRect 0, 0, w, h
        @get("actx").clearRect 0, 0, w, h
        return

      cleanup: ->
        @get("element").removeChild @get("canvas")
        return

    {
      create: (config) ->
        new Heatmap(config)
      util:
        mousePosition: (ev) ->
          if ev.layerX
            x = ev.layerX
            y = ev.layerY
          else if ev.offsetX
            x = ev.offsetX
            y = ev.offsetY
          [x,y] if x?
    }
  )()

  w.h337 = w.heatmapFactory = heatmapFactory
)(window)
