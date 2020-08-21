// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import "../../.."
import "../../../Base"
import "../../../Base/HTile"

HListView {
    id: root

    property HTextArea textArea
    property bool open: false

    property var originalWord: null
    property int replacementLength: -1
    property bool autoOpenCompleted: false
    property var usersCompleted: ({})  // {displayName: userId}

    readonly property bool autoOpen: {
        if (autoOpenCompleted) return true
        const current = textArea.getWordBehindCursor()
        return current ? /^@.+/.test(current.word) : false
    }

    readonly property var wordToComplete:
        open ? originalWord || textArea.getWordBehindCursor() : null
    // property var pr: wordToComplete
    // onPrChanged: print(JSON.stringify( pr, null, 4))

    readonly property string modelFilter:
        autoOpen && wordToComplete ? wordToComplete.word.replace(/^@/, "") :
        open && wordToComplete ? wordToComplete.word :
        ""

    function getCurrentWordStart() {
        const lastWordMatch = /(?:^|\s)[^\s]+$/.exec(textArea.text)
        if (! lastWordMatch) return textArea.length

        if (! (lastWordMatch.index === 0 && ! textArea.text[0].match(/\s/)))
            return lastWordMatch.index + 1

        return lastWordMatch.index
    }

    function replaceCompletionOrCurrentWord(withText) {
        const current = textArea.getWordBehindCursor()
        if (! current) return

        const start =
            replacementLength === -1 ?
            current.start :
            current.end + 1 - replacementLength

        textArea.remove(start, current.end + 1)
        textArea.insertAtCursor(withText)
    }

    function previous() {
        if (open) {
            decrementCurrentIndex()
            return
        }

        open = true
        const args = [model.modelId, modelFilter]
        py.callCoro("set_string_filter", args, decrementCurrentIndex)
    }

    function next() {
        if (open) {
            incrementCurrentIndex()
            return
        }

        open = true
        const args = [model.modelId, modelFilter]
        py.callCoro("set_string_filter", args, incrementCurrentIndex)
    }

    function accept() {
        if (currentIndex !== -1) {
            const member = model.get(currentIndex)
            usersCompleted[member.display_name] = member.id
            usersCompletedChanged()
        }

        open = false
    }

    function cancel() {
        if (originalWord) replaceCompletionOrCurrentWord(originalWord.word)

        currentIndex = -1
        open         = false
    }


    visible: opacity > 0
    opacity: open && count ? 1 : 0
    implicitHeight: open && count ? Math.min(window.height, contentHeight) : 0
    model: ModelStore.get(chat.userId, chat.roomId, "autocompleted_members")

    delegate: CompletableUserDelegate {
        width: root.width
        onClicked: {
            currentIndex = model.index
            root.open    = false
        }
    }

    onAutoOpenChanged: open = autoOpen
    onOpenChanged: if (! open) {
        originalWord      = null
        replacementLength = -1
        currentIndex      = -1
        autoOpenCompleted = false
        py.callCoro("set_string_filter", [model.modelId, ""])
    }

    onModelFilterChanged: {
        if (! open) return
        py.callCoro("set_string_filter", [model.modelId, modelFilter])
    }

    onCurrentIndexChanged: {
        if (currentIndex === -1) return
        if (! originalWord) originalWord = textArea.getWordBehindCursor()
        if (autoOpen) autoOpenCompleted = true

        const name = model.get(currentIndex).display_name
        replaceCompletionOrCurrentWord(name)
        replacementLength = name.length
    }

    Behavior on opacity { HNumberAnimation {} }
    Behavior on implicitHeight { HNumberAnimation {} }

    Rectangle {
        anchors.fill: parent
        z: -1
        color: theme.chat.typingMembers.background
    }

    Connections {
        target: root.textArea

        function onCursorPositionChanged() {
            if (! root.open) return

            const pos   = root.textArea.cursorPosition
            const start = root.wordToComplete.start
            const end   =
                currentIndex === -1 ?
                root.wordToComplete.end + 1 :
                root.wordToComplete.start +
                model.get(currentIndex).display_name.length

            if (pos < start || pos > end) root.accept()
        }

        function onTextChanged() {
            let changed = false

            for (const displayName of Object.keys(root.usersCompleted)) {
                if (! root.textArea.text.includes(displayName)) {
                    delete root.usersCompleted[displayName]
                    changed = true
                }
            }

            if (changed) root.usersCompletedChanged()
        }
    }
}
