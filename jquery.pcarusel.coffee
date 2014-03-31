(($, window, document) ->
  
  #   1. Create a photo carousel using the large photos linked from the thumbnails
  #   currently in the page. Some ideas you may consider: include an automatic
  #   slideshow mode, add prev/next buttons to manually controll the carousel,
  #   add a layer that shows the contents of the images alt text.

  pluginName  = "pcarusel"

  defaults    = {
    animSpeed: 500
    animInterval: 5000
    showTitles: true
    autoplay: true
    prevClass: 'carusel-prev'
    nextClass: 'carusel-next'
  }

  class Carusel
    constructor: (element, options) ->
      @slideIndex   = 0
      @animProgress = true
      @element      = $ element
      @settings     = $.extend({}, defaults, options)
      @_defaults    = defaults
      @_name        = pluginName
      window.carusel = @
      @init()

    init: ->
      carusel = @

      template = $ """
        <div class="viewport">
          <a class="#{carusel.settings.prevClass}" href="#"></a>
          <a class="play-pause pause" href="#"></a>
          <div class="wrapper"></div>
          <div class="slide-title"></div>
          <a class="#{carusel.settings.nextClass}" href="#"></a>
        </div>
      """

      carusel.element.prepend template

      carusel.container     = template.find('.wrapper')
      carusel.title         = template.find('.slide-title')
      carusel.slidesThumbs  = carusel.element.find('.one_photo > a')
      carusel.playPause     = template.find('.play-pause')

      carusel.slideWidth    = template.width()

      carusel.prev          = template.find(".#{carusel.settings.prevClass}")
      carusel.next          = template.find(".#{carusel.settings.nextClass}")

      carusel.slidesThumbs.click (e) ->
        e.preventDefault()
        slide = $ @
        carusel.setIndex slide.parent('.one_photo').index()

      caruselWidth = 0
      carusel.slidesThumbs.each (index, slide) ->
        slide = $(slide)
        slide.attr('data-index', index)
        link  = slide.attr('href')
        title = slide.find('img').attr('alt')
        img   = $ "<img class='carusel-slide' src='#{link}' alt='#{title}' data-index='#{index}'/>"
        carusel.container.append img

        if index is 0
          carusel.title.text title
          slide.addClass 'active'
          # using ti,eout image to determine with of item
          # assuming all images to be equal size
          timeoutImg = new Image
          timeoutImg.src = link
          timeoutImg.onload = ->
            carusel.container.width( timeoutImg.width * (carusel.slidesThumbs.length + 1) )
            carusel.animProgress = false

      carusel.setInterval()

      carusel.playPause.click (e) ->
        e.preventDefault()
        button = $ @
        if button.hasClass 'pause'
          clearInterval carusel.interval
          button.removeClass 'pause'
          button.addClass 'play'
        else if button.hasClass 'play'
          button.addClass 'pause'
          button.removeClass 'play'
          carusel.setInterval()

      carusel.slides = carusel.container.find('.carusel-slide')

      carusel.prev.click (e) ->
        e.preventDefault()
        newIndex = carusel.slideIndex - 1
        carusel.setIndex(newIndex)

      carusel.next.click (e) ->
        e.preventDefault()
        newIndex = carusel.slideIndex + 1
        carusel.setIndex(newIndex)

      return

    setInterval: ->
      @interval = setInterval =>
        newIndex = @slideIndex + 1
        @setIndex(newIndex)
      , @settings.animInterval
      return

    setIndex: (index) =>
      return if @animProgress or index is @slideIndex

      @animProgress = true

      if index >= 0 and index <= @slides.length - 1
        newIndex = index
      else if index < 0
        newIndex = @slides.length - 1
      else
        newIndex = 0

      currentSlide    = @slides.filter("*[data-index=#{@slideIndex}]")
      targetSlide     = @slides.filter("*[data-index=#{newIndex}]")
      tempTargetSlide = targetSlide.clone()
      currentPreview  = @slidesThumbs.filter("*[data-index=#{@slideIndex}]")
      targetPreview   = @slidesThumbs.filter("*[data-index=#{newIndex}]")

      @slidesThumbs.removeClass 'active'
      targetPreview.addClass 'active'

      # still had a bug on last slide - need to figure out whar is happening

      animCallback = =>
        tempTargetSlide.remove()
        @container.css { left: "-#{ @slideWidth * newIndex }px" }
        @slideIndex = newIndex
        @title.text $(@slides[@slideIndex]).attr('alt')
        @animProgress = false

      #animation goes here
      if newIndex > @slideIndex
        tempTargetSlide.insertAfter currentSlide
        @container.animate { left: "-=#{ @slideWidth }" }, @settings.animSpeed, animCallback
      else
        tempTargetSlide.insertBefore currentSlide
        @container.css { left: "-#{ @slideWidth * (@slideIndex + 1) }px" }
        @container.animate { left: "+=#{ @slideWidth }" }, @settings.animSpeed, animCallback

      true

  
  $.fn[pluginName] = (options) ->
    @each ->
      $.data this, "plugin_" + pluginName, new Carusel(this, options) unless $.data(this, "plugin_" + pluginName)
      return

    this

  return

) jQuery, window, document