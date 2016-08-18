/****************************************************************************
**
** Copyright (C) 2016 Jolla Ltd.
** Contact: Chris Adams <chris.adams@jollamobile.com>
**
****************************************************************************/

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0

RawWebView {
    id: webview

    signal linkClicked(string url)

    active: true

    onViewInitialized: {
        webview.loadFrameScript("chrome://embedlite/content/embedhelper.js");
        webview.loadFrameScript("chrome://embedlite/content/SelectAsyncHelper.js");
        webview.addMessageListeners([
            "embed:linkclicked",
            "embed:filepicker",
            "embed:selectasync",
            "embed:alert",
            "embed:confirm",
            "embed:prompt"]);
    }

    onRecvAsyncMessage: {
        // cache some symbol resolutions in var properties in the function closure
        var winid = data.winid
        var webView = webview
        var dialog = null
        switch(message) {
            case "embed:linkclicked": {
                webview.linkClicked(data.uri)
                break
            }
            case "embed:filepicker": {
                filePicker.createObject(pageStack, {
                                           "pageStack": pageStack,
                                           "winid": winid,
                                           "webView": webView,
                                           "filter": data.filter,
                                           "mode": data.mode})
                break
            }
            case "embed:selectasync": {
                pageStack.push(data.multiple ? multiSelectDialog : singleSelectPage,
                               { "options": data.options, "webview": webView });
                break
            }
            case "embed:alert": {
                dialog = pageStack.push(alertDialog, { "text": data.text })
                // TODO: also the Async message must be sent when window gets closed
                dialog.done.connect(function() {
                    webView.sendAsyncMessage("alertresponse", {"winid": winid})
                })
                break
            }
            case "embed:confirm": {
                dialog = pageStack.push(confirmDialog, { "text": data.text })
                // TODO: also the Async message must be sent when window gets closed
                dialog.accepted.connect(function() {
                    webView.sendAsyncMessage("confirmresponse",
                                             { "winid": winid, "accepted": true })
                })
                dialog.rejected.connect(function() {
                    webView.sendAsyncMessage("confirmresponse",
                                             { "winid": winid, "accepted": false })
                })
                break
            }
            case "embed:prompt": {
                dialog = pageStack.push(promptDialog, { "text": data.text, "value": data.defaultValue })
                // TODO: also the Async message must be sent when window gets closed
                dialog.accepted.connect(function() {
                    webView.sendAsyncMessage("promptresponse",
                                             { "winid": winid, "accepted": true, "promptvalue": dialog.value })
                })
                dialog.rejected.connect(function() {
                    webView.sendAsyncMessage("promptresponse",
                                             { "winid": winid, "accepted": false })
                })
                break
            }
            default: break
        }
    }

    BusyIndicator {
        id: busySpinner
        anchors.centerIn: parent
        running: true
        visible: webview.loading
        size: BusyIndicatorSize.Large
    }

    Component { id: filePicker; PickerCreator {} }
    Component { id: multiSelectDialog; MultiSelectDialog {} }
    Component { id: singleSelectPage; SingleSelectPage {} }
    Component { id: alertDialog; AlertDialog {} }
    Component { id: confirmDialog; ConfirmDialog {} }
    Component { id: promptDialog; PromptDialog {} }
}