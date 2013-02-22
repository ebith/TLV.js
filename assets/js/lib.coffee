makeThumbnail = (selector='img.thumbnail', context=null) ->
  $(selector, context).each ->
    $(this).transition({'opacity': 1}, 'slow')
    if $(this).width() >= $(this).height()
      $(this).width('150px')
      $(this).css('top', "#{$(this).height()}px")
    else
      $(this).height('150px')
      $(this).css('left', "#{$(this).width()}px")
window.makeThumbnail = makeThumbnail
jQuery -> do makeThumbnail
