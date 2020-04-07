// SPDX-License-Identifier: LGPL-3.0-or-later

import QtQuick 2.12
import ".."
import "../.."

QtObject {
    function onExitRequested(exitCode) {
        Qt.exit(exitCode)
    }


    function onAlertRequested() {
        const msec = window.settings.alertOnMessageForMsec

        if (Qt.application.state !== Qt.ApplicationActive && msec !== 0) {
            window.alert(msec === -1 ? 0 : msec)  // -1 → 0 = no time out
        }
    }


    function onCoroutineDone(uuid, result, error, traceback) {
        const onSuccess = Globals.pendingCoroutines[uuid].onSuccess
        const onError   = Globals.pendingCoroutines[uuid].onError

        delete Globals.pendingCoroutines[uuid]

        if (error) {
            const type = py.getattr(py.getattr(error, "__class__"), "__name__")
            const args = py.getattr(error, "args")

            if (type === "CancelledError") return

            onError ?
            onError(type, args, error, traceback, uuid) :
            utils.showError(type, traceback, "", uuid)

            return
        }

        if (onSuccess) onSuccess(result)
    }


    function onLoopException(message, error, traceback) {
        // No need to log these here, the asyncio exception handler does it
        const type = py.getattr(py.getattr(error, "__class__"), "__name__")
        utils.showError(type, traceback, message)
    }


    function onModelItemSet(syncId, indexThen, indexNow, fields){
        if (indexThen === undefined) {
            // print("I", syncId, indexThen, indexNow, JSON.stringify(fields))
            ModelStore.get(syncId).insert(indexNow, fields)

        } else {
            // print("S", syncId, indexThen, indexNow, JSON.stringify(fields))
            const model = ModelStore.get(syncId)
            model.set(indexThen, fields)
            if (indexThen !== indexNow) model.move(indexThen, indexNow, 1)
        }
    }


    function onModelItemDeleted(syncId, index) {
        // print("D", syncId, index)
        ModelStore.get(syncId).remove(index)
    }


    function onModelCleared(syncId) {
        // print("C", syncId)
        ModelStore.get(syncId).clear()
    }
}
