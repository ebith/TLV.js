jQuery ->
  page = 1
  stream = ''

  $(window).scroll ->
    if $(this).scrollTop() > ($(document).height() - $(window).height()) / 2
      $('#navigation').appendTo('#wrapper')
    else
      $('#navigation').prependTo('#wrapper')

  do loadRecent = ->
    $.ajax {
      type: 'GET'
      url: '/recent.json'
      data: {
        page: 1
        limit: 20
      }
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        make data, true
    }

    stream = new EventSource '/stream.json'
    stream.addEventListener 'message', (e) ->
      make JSON.parse(e.data), false, (msg) ->
        $(msg[0]).appendTo('#message-container').hide().fadeIn()
        $('html, body').animate({scrollTop: do $(document).height})

  $('#load-older').on 'click', (e) ->
    do stream.close
    do e.preventDefault
    $.ajax {
      type: 'GET'
      url: '/recent.json'
      data: {
        page: page+1
        limit: 50
      }
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        make data, true
    }
    page++
    $('html, body').scrollTop(0)

  $('#load-recent').on 'click', (e) ->
    do e.preventDefault
    $('#message-container').find('div').remove()
    do loadRecent
    page = 1
    $('html, body').scrollTop(0)

  $('#search').keypress (e) ->
    if e.which is 13
      do stream.close
      do e.preventDefault
      $('#message-container').find('div').remove()
      word = $(this).val()
      $.ajax {
        type: 'GET'
        url: "/search/#{word}.json"
        dataType: 'json'
        success: (data, textStatus, jqXHR) ->
          if data.length > 1
            make data, true
          else
            msg = "<div class=\"message message-info\" style=\"text-align: center\">誰も <strong>#{word}</strong> とか言ってないし</div>"
            $(msg).prependTo('#message-container').hide().fadeIn()
      }
    $('html, body').scrollTop(0)

  make = (data, prepend, callback) ->
    msg = []
    data.forEach (line) ->
      if line.info
        msg.push "<div class=\"message message-info\"><a href=\"/#{line.info}/\">#{line.info}</a></div>"
      if line.date
        msg.push "<div class=\"message message-date\"><a href=\"/#{line.date}/\">#{line.date}</a></div>"
      if line.isNotice
        msg.push "<div class=\"message message-notice\">#{line.time} #{line.nick} : #{line.msg}</div>"
      else if line.msg
        msg.push "<div class=\"message\">#{line.time} #{line.nick} : #{line.msg}</div>"
    if prepend
      $(div).prependTo('#message-container').hide().fadeIn() for div in msg.reverse()
    else
      callback msg.reverse()
