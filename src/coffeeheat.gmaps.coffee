 # heatmap.js GMaps overlay
 #
 # Copyright (c) 2011, Patrick Wied (http://www.patrick-wied.at)
 # Dual-licensed under the MIT (http://www.opensource.org/licenses/mit-license.php)
 # and the Beerware (http://en.wikipedia.org/wiki/Beerware) license.
((w) ->
  class HeatmapOverlay extends google.maps.OverlayView
    constructor: (map, cfg) ->
      @heatmap = null
      @conf = cfg
      @latlngs = []
      @bounds = null
      @setMap map

      google.maps.event.addListenerOnce map, "idle", => @draw()

    onAdd: ->
      map_div = @getMap().getDiv()

      el = document.createElement("div")
      el.style.position = "absolute"
      el.style.top = el.style.border = el.style.left = 0
      el.style.width = map_div.clientWidth + "px"
      el.style.height = map_div.clientHeight + "px"

      @getPanes().overlayLayer.appendChild(el)
      @conf.element = el

      @heatmap = heatmapFactory.create(@conf)

    toggle: ->
      @heatmap.toggleDisplay()

    draw: ->
      overlayProjection = @getProjection()
      currentBounds = @map.getBounds()

      return if currentBounds.equals(@bounds)
      @bounds = currentBounds

      ne = overlayProjection.fromLatLngToDivPixel currentBounds.getNorthEast()
      sw = overlayProjection.fromLatLngToDivPixel currentBounds.getSouthWest()
      topY = ne.y
      leftX = sw.x

      @conf.element.style.left = leftX + 'px'
      @conf.element.style.top = topY + 'px'
      @conf.element.style.width = ne.x - sw.x + 'px'
      @conf.element.style.height = sw.y - ne.y + 'px'

      @heatmap.store.get("heatmap").resize()

      if @latlngs.length > 0
        @heatmap.clear()

        len = @latlngs.length
        projection = @getProjection()
        d =
          max: @heatmap.store.max
          data: []

        while len--
          latlng = @latlngs[len].latlng
          continue  unless currentBounds.contains(latlng)
          divPixel = projection.fromLatLngToDivPixel(latlng)
          screenPixel = new google.maps.Point(divPixel.x - leftX, divPixel.y - topY)
          roundedPoint = @pixelTransform(screenPixel)
          d.data.push
            x: roundedPoint.x
            y: roundedPoint.y
            count: @latlngs[len].c
        @heatmap.store.setDataSet(d)

    pixelTransform: (p) ->
      w = @heatmap.get("width")
      h = @heatmap.get("height")
      p.x += w while p.x < 0
      p.x -= w while p.x > w
      p.y += h while p.y < 0
      p.y -= h while p.y > h
      p.x = (p.x >> 0)
      p.y = (p.y >> 0)
      p

    setDataSet: (data) ->
      d = data.data
      dlen = d.length
      projection = @getProjection()
      @latlngs = []
      mapdata =
        max: data.max
        data: []

      while dlen--
        latlng = new google.maps.LatLng(d[dlen].lat, d[dlen].lng)
        @latlngs.push
          latlng: latlng
          c: d[dlen].count

        point = @pixelTransform projection.fromLatLngToDivPixel(latlng)
        mapdata.data.push
          x: point.x
          y: point.y
          count: d[dlen].count

      @heatmap.clear()
      @heatmap.store.setDataSet(mapdata)

    addDataPoint: (lat, lng, count) ->
      projection = @getProjection()
      latlng = new google.maps.LatLng(lat, lng)
      point = @pixelTransform projection.fromLatLngToDivPixel(latlng)
      @heatmap.store.addDataPoint(point.x, point.y, count)
      @latlngs.push
        latlng: latlng
        c: count
  w.HeatmapOverlay = HeatmapOverlay
)(window)