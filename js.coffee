#extend original prototype to prevent firing events multilply times
Function::debounce = (threshold, execAsap) ->
  func = this
  timeout = undefined
  debounced = ->
    delayed = ->
      func.apply(obj, args)  unless execAsap # execute now
      timeout = null
      return

    obj = this
    args = arguments
    
    if timeout
      clearTimeout timeout
    
    else func.apply(obj, args) if execAsap
    timeout = setTimeout(delayed, threshold or 100)
    return

$ ->
  #initing variables in global clojure scope
  landmarkTypes = $('.landmarks .landmark_link')
  clearFilter   = $('.landmarks .landmark_link.clear-filter')
  map       = undefined
  landmarks = []
  types     = []
  location = $('#landmarks_map').data('location')

  # use server-side templates for initial point
  mapOptions = {
    zoom: 8
    center: new google.maps.LatLng(location[0], location[1])
  }

  #init map
  map = new google.maps.Map(document.getElementById('landmarks_map'), mapOptions)

  # images dictionary
  markerImages = {
    'statue': '/img/marker_statue.png'
    'cathedral': '/img/marker_cathedral.png'
    'palace': '/img/marker_palace.png'
    'fountain': '/img/marker_fountain.png'
  }

  # set marker properties for each response item
  # extend each object with marker reference for filtering
  setMarkers = ->
    for landmark in landmarks
      image = {
        url: markerImages[landmark.type]
        size: new google.maps.Size(32, 37)
        anchor: new google.maps.Point(0, 32)
      }

      myLatLng  = new google.maps.LatLng(landmark.lat, landmark.lng)

      marker    = new google.maps.Marker {
        position: myLatLng
        map: null
        icon: image
        flat: true
        title: landmark.title
      }

      landmark.marker = marker

    true

  # set map if marker to current
  drawLandmarks = (filerredLandmarks) ->
    for landmark in filerredLandmarks
      landmark.marker.setMap map
    true

  # fetch data from server
  # send current map bounds to draw only visible makers
  getLandmarks = ->
    bounds = map.getBounds().toUrlValue()
    request = $.ajax {
      url: '/landmarks.json'
      type: 'GET'
      data: {
        bounds: bounds
      }
      contentType: 'json'
    }

    clearLandmarks true

    request.then (data) ->
      landmarks = JSON.parse(data)
      setMarkers()
      drawLandmarks(filterLandmarksByType())
    , (error) ->
      console.warn 'data error'

    true

  # hide and delete markers (optional)
  clearLandmarks = (clear = false) ->
    for landmark in landmarks
      landmark.marker.setMap( null )
      delete landmark.marker if clear
    true

  # for type filtering
  filterLandmarksByType = ->
    if types.length > 0
      $.grep landmarks, (landmark, index) ->
        types.indexOf(landmark.type) isnt -1
    else
      landmarks

  landmarkTypes.click (e) ->
    e.preventDefault()
    element = $ @
    elementType = element.data 'type'
    if element.hasClass 'clear-filter'
      types = []
      landmarkTypes.removeClass 'active'
      element.addClass 'active'
    else
      clearFilter.removeClass 'active'
      if element.hasClass 'active'
        element.removeClass 'active'
        types.splice(types.indexOf(elementType), 1)
        clearFilter.addClass 'active' if types.length is 0
      else
        types.push elementType
        element.addClass 'active'

    clearLandmarks()
    drawLandmarks(filterLandmarksByType())

    false

  # detect changing of bounds and query server for markers that fit bounds
  # debouncing this call, call after 100ms from last change
  google.maps.event.addListener(map, 'bounds_changed', ( ->
    getLandmarks()
    return
  ).debounce(100))

  return