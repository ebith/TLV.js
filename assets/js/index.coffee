jQuery ->
  page = 1

  $.ajax {
    type: 'POST'
    url: '/recent.json'
    data: {
      page: page
      limit: 20
    }
    dataType: 'json'
    success: (data, textStatus, jqXHR) ->
      make data, (msg) ->
        $('#message-container').prepend(msg).hide().fadeIn()
  }

  $('#load-older').on 'click', (e) ->
    do e.preventDefault
    $.ajax {
      type: 'POST'
      url: '/recent.json'
      data: {
        page: page+1
        limit: 50
      }
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        make data, (msg) ->
          $('#message-container').prepend(msg).hide().fadeIn()
    }
    page++

  $('#load-recent').on 'click', (e) ->
    do e.preventDefault
    $('#message-container').find('div').remove()
    $.ajax {
      type: 'POST'
      url: '/recent.json'
      data: {
        page: 1
        limit: 20
      }
      dataType: 'json'
      success: (data, textStatus, jqXHR) ->
        make data, (msg) ->
          $('#message-container').prepend(msg).hide().fadeIn()
    }
    page = 1

  $('#search').keypress (e) ->
    if e.which is 13
      do e.preventDefault
      $('#message-container').find('div').remove()
      word = $(this).val()
      $.ajax {
        type: 'POST'
        url: '/search.json'
        data: {
          word: word
          limit: 0
        }
        dataType: 'json'
        success: (data, textStatus, jqXHR) ->
          if data.length
            make data, (msg) ->
              $('#message-container').prepend(msg).hide().fadeIn()
          else
            msg = "<div class=\"message message-info\" style=\"text-align: center\">誰も <strong>#{word}</strong> とか言ってないし</div>"
            $('#message-container').prepend(msg).hide().fadeIn()
      }

  make = (data, callback) ->
    msg = data.map (line) ->
      tmp = ''
      if line.info
        tmp += "<div class=\"message message-info\"><a href=\"/#{line.info}/\">#{line.info}</a></div>"
      if line.isNotice
        tmp += "<div class=\"message message-notice\">#{line.time} #{line.nick} : #{line.msg}</div>"
      else
        tmp += "<div class=\"message\">#{line.time} #{line.nick} : #{line.msg}</div>"
      return tmp
    callback msg
