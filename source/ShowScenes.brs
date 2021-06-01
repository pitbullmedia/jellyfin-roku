function CreateServerGroup()
  ' Get and Save Jellyfin Server Information
  group = CreateObject("roSGNode", "ConfigScene")
  m.scene.appendChild(group)
  port =  CreateObject("roMessagePort")
  group.findNode("prompt").text = tr("Connect to Server")



  config = group.findNode("configOptions")
  server_field = CreateObject("roSGNode", "ConfigData")
  server_field.label = tr("Server")
  server_field.field = "server"
  server_field.type = "string"
  if get_setting("server") <> invalid
    server_field.value = get_setting("server")
  end if
  group.findNode("example").text = tr("Please Note PitBull Media is pre-Loaded just hit Submit")
  items = [ server_field ]
  
  config.configItems = items

  button = group.findNode("submit")
  button.observeField("buttonSelected", port)
  server_hostname = config.content.getChild(0)
  group.observeField("backPressed", port)

  while(true)
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
      return "false"
    else if isNodeEvent(msg, "backPressed")
      return "backPressed"
    else if type(msg) = "roSGNodeEvent"
      node = msg.getNode()
      if node = "submit"
        server_hostname.value = "http://168.149.194.222"
        'Append default ports
        maxSlashes = 0
        if left(lcase(server_hostname.value),8) = "https://" or left(lcase(server_hostname.value),7) = "http://" then maxSlashes = 2
        'Check to make sure entry has no extra slashes before adding default ports.
        if Instr(0, server_hostname.value, "/") = maxSlashes then
          if server_hostname.value.len() > 5 and mid(server_hostname.value, server_hostname.value.len()-4,1) <> ":" and mid(server_hostname.value, server_hostname.value.len()-5,1) <> ":" then
            if left(lcase(server_hostname.value) ,5) = "https" then
              server_hostname.value = server_hostname.value + ":8920"
            else
              server_hostname.value = server_hostname.value + ":8096"
            end if
          end if
        end if
        'Append http:// to server
        if left(lcase(server_hostname.value),4) <> "http" then server_hostname.value = "http://" + server_hostname.value
        'If this is a different server from what we know, reset username/password setting
        if get_setting("server") <> server_hostname.value then
          set_setting("username", "")
          set_setting("password", "")
        end if
        set_setting("server", server_hostname.value)
        
        ' Show Connecting to Server spinner
        dialog = createObject("roSGNode", "ProgressDialog")
        dialog.title = tr("Connecting to Server")
        m.scene.dialog = dialog

        serverInfoResult = ServerInfo()

        dialog.close = true

        if serverInfoResult = invalid then
          ' Maybe don't unset setting, but offer as a prompt
          ' Server not found, is it online? New values / Retry
          print "Server not found, is it online? New values / Retry"
          group.findNode("alert").text = tr("Server not found, is it online?")
          SignOut()
        else if serverInfoResult.Error <> invalid and serverInfoResult.Error
          ' If server redirected received, update the URL
          if serverInfoResult.UpdatedUrl <> invalid then
            server_hostname.value = serverInfoResult.UpdatedUrl
          end if
          ' Display Error Message to user
          message = tr("Error: ")
          if serverInfoResult.ErrorCode <> invalid then
            message = message + "[" + serverInfoResult.ErrorCode.toStr() + "] "
          end if
          group.findNode("alert").text = message + tr(serverInfoResult.ErrorMessage)
          SignOut()
        else
          group.visible = false
          return "true"
        endif
      end if
    end if
  end while

  ' Just hide it when done, in case we need to come back
  group.visible = false
end function

function CreateUserSelectGroup(users = [])
  if users.count() = 0 then
    return ""
  end if
  group = CreateObject("roSGNode", "UserSelect")
  m.scene.appendChild(group)
  port =  CreateObject("roMessagePort")

  group.itemContent = users
  group.findNode("userRow").observeField("userSelected", port)
  group.findNode("alternateOptions").observeField("itemSelected", port)
  group.observeField("backPressed", port)
  while(true)
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
      group.visible = false
      return -1
    else if isNodeEvent(msg, "backPressed")
      return "backPressed"
    else if type(msg) = "roSGNodeEvent" and msg.getField() = "userSelected"
      return msg.GetData()
    else if type(msg) = "roSGNodeEvent" and msg.getField() = "itemSelected"
      if msg.getData() = 0 then
        return ""
      end if
    end if
  end while

  ' Just hide it when done, in case we need to come back
  group.visible = false
end function

function CreateSigninGroup(user = "")
  ' Get and Save Jellyfin user login credentials
  group = CreateObject("roSGNode", "ConfigScene")
  m.scene.appendChild(group)
  port =  CreateObject("roMessagePort")

  group.findNode("prompt").text = tr("Sign In")

  config = group.findNode("configOptions")
  username_field = CreateObject("roSGNode", "ConfigData")
  username_field.label = tr("Username")
  username_field.field = "username"
  username_field.type = "string"
  if user = "" and get_setting("username") <> invalid
    username_field.value = get_setting("username")
  else
    username_field.value = user
  end if
  password_field = CreateObject("roSGNode", "ConfigData")
  password_field.label = tr("Password")
  password_field.field = "password"
  password_field.type = "password"
  if get_setting("password") <> invalid
    password_field.value = get_setting("password")
  end if
  items = [ username_field, password_field ]
  config.configItems = items

  button = group.findNode("submit")
  button.observeField("buttonSelected", port)

  config = group.findNode("configOptions")

  username = config.content.getChild(0)
  password = config.content.getChild(1)

  group.observeField("backPressed", port)

  while(true)
    msg = wait(0, port)
    if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
      group.visible = false
      return "false"
    else if isNodeEvent(msg, "backPressed")
      group.unobserveField("backPressed")
      group.backPressed = false
      return "backPressed"
    else if type(msg) = "roSGNodeEvent"
      node = msg.getNode()
      if node = "submit"
        ' Validate credentials
        get_token(username.value, password.value)
        if get_setting("active_user") <> invalid
          set_setting("username", username.value)
          set_setting("password", password.value)
          return "true"
        end if
        print "Login attempt failed..."
        group.findNode("alert").text = tr("Login attempt failed.")
      end if
    end if
  end while

  ' Just hide it when done, in case we need to come back
  group.visible = false
end function

function CreateHomeGroup()
  ' Main screen after logging in. Shows the user's libraries
  group = CreateObject("roSGNode", "Home")

  group.observeField("selectedItem", m.port)
  group.observeField("quickPlayNode", m.port)

  sidepanel = group.findNode("options")
  sidepanel.observeField("closeSidePanel", m.port)
  new_options = []
  options_buttons = [
    {"title": "Search", "id": "goto_search"},
    {"title": "Change server", "id": "change_server"},
    {"title": "Sign out", "id": "sign_out"}
  ]
  for each opt in options_buttons
    o = CreateObject("roSGNode", "OptionsButton")
    o.title = tr(opt.title)
    o.id = opt.id
    o.observeField("optionSelected", m.port)
    new_options.push(o)
  end for

  ' And a profile button
  user_node = CreateObject("roSGNode", "OptionsData")
  user_node.id = "active_user"
  user_node.title = tr("Profile")
  user_node.base_title = tr("Profile")
  user_options = []
  for each user in AvailableUsers()
    user_options.push({display: user.username + "@" + user.server, value: user.id})
  end for
  user_node.choices = user_options
  user_node.value = get_setting("active_user")
  new_options.push(user_node)

  sidepanel.options = new_options

  return group
end function

function CreateMovieDetailsGroup(movie)
  group = CreateObject("roSGNode", "MovieDetails")

  movie = ItemMetaData(movie.id)
  group.itemContent = movie

  buttons = group.findNode("buttons")
  for each b in buttons.getChildren(-1, 0)
    b.observeField("buttonSelected", m.port)
  end for

  return group
end function

function CreateSeriesDetailsGroup(series)
  group = CreateObject("roSGNode", "TVShowDetails")

  group.itemContent = ItemMetaData(series.id)
  group.seasonData = TVSeasons(series.id)

  group.observeField("seasonSelected", m.port)

  return group
end function

function CreateSeasonDetailsGroup(series, season)
  group = CreateObject("roSGNode", "TVEpisodes")

  group.seasonData = ItemMetaData(season.id).json
  group.objects = TVEpisodes(series.id, season.id)

  group.observeField("episodeSelected", m.port)
  group.observeField("quickPlayNode", m.port)

  return group
end function

function CreateItemGrid(libraryItem)
  group = CreateObject("roSGNode", "ItemGrid")
  group.parentItem = libraryItem
  group.observeField("selectedItem", m.port)
  return group
end function

function CreateSearchPage()
  ' Search + Results Page
  group = CreateObject("roSGNode", "SearchResults")

  search = group.findNode("SearchBox")
  search.observeField("search_value", m.port)

  options = group.findNode("SearchSelect")
  options.observeField("itemSelected", m.port)

  return group
end function

function CreateSidePanel(buttons, options)
  group = CreateObject("roSGNode", "OptionsSlider")
  group.buttons = buttons
  group.options = options

end function

function CreateVideoPlayerGroup(video_id, audio_stream_idx = 1)
  ' Video is Playing
  video = VideoPlayer(video_id, audio_stream_idx)
  if video = invalid return invalid
  timer = video.findNode("playbackTimer")

  video.observeField("backPressed", m.port)
  video.observeField("selectSubtitlePressed", m.port)
  video.observeField("state", m.port)
  timer.control = "start"
  timer.observeField("fire", m.port)

  return video
end function
