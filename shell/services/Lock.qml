pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pam

Singleton {
    id: root

    property bool locked: false
    property string password: ""
    property bool busy: false
    property bool fail: false
    property bool fprint: false
    property bool fprintOff: false
    property bool fprintSaw: false

    onPasswordChanged: {
        if (password.length)
            fail = false;
    }

    function request() {
        ShellState.closeMenus();
        lock();
    }

    function lock() {
        if (locked)
            return;
        ShellState.closeMenus();
        password = "";
        fail = false;
        busy = false;
        fprint = false;
        fprintOff = false;
        fprintSaw = false;
        locked = true;
        Qt.callLater(startFprint);
    }

    function unlock() {
        passPam.abort();
        printPam.abort();
        fprintTimer.stop();
        locked = false;
        password = "";
        fail = false;
        busy = false;
        fprint = false;
        fprintOff = false;
        fprintSaw = false;
    }

    function submit() {
        if (!locked || busy || !password.length)
            return;
        busy = true;
        fail = false;
        passPam.abort();
        Qt.callLater(() => passPam.start());
    }

    function startFprint() {
        if (!locked || fprintOff || printPam.active)
            return;
        fprintSaw = false;
        if (!printPam.start())
            fprintOff = true;
    }

    PamContext {
        id: passPam
        configDirectory: `${Quickshell.shellDir}/pam`
        config: "password.conf"

        onPamMessage: {
            if (responseRequired)
                respond(root.password);
        }

        onCompleted: result => {
            root.busy = false;
            if (result == PamResult.Success) {
                root.unlock();
                return;
            }
            root.password = "";
            root.fail = true;
        }

        onError: {
            root.busy = false;
            root.password = "";
            root.fail = true;
        }
    }

    PamContext {
        id: printPam
        configDirectory: `${Quickshell.shellDir}/pam`
        config: "fingerprint.conf"

        onCompleted: result => {
            const again = root.fprintSaw;
            root.fprint = false;
            if (result == PamResult.Success) {
                root.unlock();
                return;
            }
            if (root.locked && !root.fprintOff && again)
                fprintTimer.restart();
            else
                root.fprintOff = true;
        }

        onError: {
            root.fprint = false;
            root.fprintOff = true;
        }

        onPamMessage: {
            if (!responseRequired) {
                root.fprint = true;
                root.fprintSaw = true;
            }
        }
    }

    Timer {
        id: fprintTimer
        interval: 500
        repeat: false
        onTriggered: root.startFprint()
    }

    onLockedChanged: {
        Quickshell.execDetached(["killall", locked ? "-STOP" : "-CONT", "mpvpaper"]);
        if (!locked) {
            passPam.abort();
            printPam.abort();
            fprintTimer.stop();
        }
    }
}
