// Copyright 2019 miruka
// This file is part of harmonyqml, licensed under LGPLv3.


function hsl(hue, saturation, lightness) {
    return hsla(hue, saturation, lightness, 1.0)
}


function hsla(hue, saturation, lightness, alpha) {
    // Convert standard hsla(0-360, 1-100, 1-100, 0-1) to Qt format
    return Qt.hsla(hue / 360, saturation / 100, lightness / 100, alpha)
}


function arrayToModelItem(keys_name, array) {
    // Convert an array to an object suitable to be in a model, example:
    // [1, 2, 3] → [{keys_name: 1}, {keys_name: 2}, {keys_name: 3}]
    var items = []

    for (var i = 0; i < array.length; i++) {
        var obj        = {}
        obj[keys_name] = array[i]
        items.push(obj)
    }
    return items
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
       theme.avatar.background.saturation,
       theme.avatar.background.lightness,
       theme.avatar.background.alpha
   )
}


function nameColor(name) {
    return Qt.hsla(
        hueFrom(name),
        theme.displayName.saturation,
        theme.displayName.lightness,
        1
    )
}


function coloredNameHtml(name, user_id, display_text) {
    // substring: remove leading @
    return "<font color='" + nameColor(name || alt_id.substring(1)) + "'>" +
           escapeHtml(display_text || name || alt_id) +
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
    var name = users.find(ev.senderId).displayName
    var text = ev.content.replace("%S", coloredNameHtml(name, ev.senderId))

    // %T → target (event state_key) display name
    if (ev.targetUserId) {
        var tname = users.find(ev.targetUserId).displayName
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


function filterMatches(filter, text) {
    filter = filter.toLowerCase()
    text   = text.toLowerCase()

    var words = filter.split(" ")

    for (var i = 0; i < words.length; i++) {
        if (words[i] && text.indexOf(words[i]) == -1) {
            return false
        }
    }
    return true
}


function thumbnailParametersFor(width, height) {
    // https://matrix.org/docs/spec/client_server/latest#thumbnails

    if (width > 640 || height > 480)
        return {width: 800, height: 600, fillMode: Image.PreserveAspectFit}

    if (width > 320 || height > 240)
        return {width: 640, height: 480, fillMode: Image.PreserveAspectFit}

    if (width >  96 || height >  96)
        return {width: 320, height: 240, fillMode: Image.PreserveAspectFit}

    if (width >  32 || height >  32)
        return {width: 96, height: 96, fillMode: Image.PreserveAspectCrop}

    return {width: 32, height: 32, fillMode: Image.PreserveAspectCrop}
}
