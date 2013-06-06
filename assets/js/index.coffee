jQuery ->
  skip = 0
  stream = ''
  name = ''

  $.get '/info', (data) ->
    name = data.hostname

  navPosTop = true
  $(window).scroll ->
    if $(this).scrollTop() > ($(document).height() - $(window).height()) / 2
      if navPosTop
        $('#navigation').appendTo('#wrapper').css('opacity', 0).transition({opacity: 1})
        navPosTop = false
    else
      unless navPosTop
        $('#navigation').prependTo('#wrapper').css('opacity', 0).transition({opacity: 1})
        navPosTop = true

  do loadRecent = ->
    $.ajax {
      type: 'GET'
      url: '/recent.json'
      data: {
        limit: 20
      }
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        skip = 20
        $('html, body').scrollTop(0)
        make data, true
    }

    stream = new EventSource '/stream.json'
    setTimeout (-> ($.post '/say', { notice: 'yes', text: "#{name}がTLV.js見てる" })), 10000
    stream.addEventListener 'message', (e) ->
      make JSON.parse(e.data), false, (msg) ->
        $(msg[0]).appendTo('#message-container').css('opacity', 0).transition({opacity: 1}, 'slow')
        $('html, body').scrollTop(do $(document).height)

  $('#load-older').on 'click', (e) ->
    do stream.close
    do e.preventDefault
    $.ajax {
      type: 'GET'
      url: '/recent.json'
      data: {
        skip: skip
        limit: 50
      }
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        $.post '/say', { notice: 'yes', text: "#{name}が過去ログ読んでる" } if skip is 70
        skip += 50
        $('html, body').scrollTop(0)
        make data, true
    }

  $('#load-recent').on 'click', (e) ->
    do e.preventDefault
    $('#message-container').find('div').remove()
    do loadRecent

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
          $.post '/say', { notice: 'yes', text: "#{name}が#{word}検索してる" }
          $('html, body').scrollTop(0)
          if data.length > 1
            make data, true
          else
            msg = "<div class=\"message message-info\" style=\"text-align: center\">誰も <strong>#{word}</strong> とか言ってないし</div>"
            $(msg).prependTo('#message-container').css('opacity', 0).transition({opacity: 1})
      }

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
      $(div).prependTo('#message-container').css('opacity', 0).transition({opacity: 1}) for div in msg.reverse()
    else
      callback msg.reverse()
