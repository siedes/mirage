function stripUserId(user_id) {
    // Remove leading @
    return user_id.substring(1)
}


function stripRoomName(name) {
    // Remove leading # (aliases)
    return name[0] == "#" ? name.substring(1) : name
}


function hueFrom(string) {
    // Calculate and return a unique hue between 0 and 1 for the string
    var hue = 0
    for (var i = 0; i < string.length; i++) {
        hue += string.charCodeAt(i) * 99
    }
    return hue % 360 / 360
}


function avatarColor(name) {
   return Qt.hsla(
       hueFrom(name),
       HStyle.avatar.background.saturation,
       HStyle.avatar.background.lightness,
       HStyle.avatar.background.alpha
   )
}


function nameColor(name) {
    return Qt.hsla(
        hueFrom(name),
        HStyle.displayName.saturation,
        HStyle.displayName.lightness,
        1
    )
}


function coloredNameHtml(name, alt_id) {
    return "<font color='" + nameColor(name || stripUserId(alt_id)) + "'>" +
           escapeHtml(name || alt_id) +
           "</font>"
}


function escapeHtml(string) {
    // Replace special HTML characters by encoded alternatives
    return string.replace("&", "&amp;")
                 .replace("<", "&lt;")
                 .replace(">", "&gt;")
                 .replace('"', "&quot;")
                 .replace("'", "&#039;")
}


function eventIsMessage(ev) {
    return /^RoomMessage($|[A-Z])/.test(ev.eventType)
}


function translatedEventContent(ev) {
    // ev: timelines item
    if (ev.translatable == false) { return ev.content }

    // %S → sender display name
    var name = users.getUser(ev.senderId).displayName
    var text = ev.content.replace("%S", coloredNameHtml(name, ev.senderId))

    // %T → target (event state_key) display name
    if (ev.targetUserId) {
        var tname = users.getUser(ev.targetUserId).displayName
        text = text.replace("%T", coloredNameHtml(tname, ev.targetUserId))
    }

    text = qsTr(text)
    if (ev.translatable == true) { return text }

    // Else, model.translatable should be an array of args
    for (var i = 0; ev.translatable.length; i++) {
        text = text.arg(ev.translatable[i])
    }
    return text
}
