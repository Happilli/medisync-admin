pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import MediSyncAdmin

Window {
    id: appWindow
    visible: true
    width: 800
    height: 600
    title: "MediSync Admin"
    color: Theme.backgroundColor

    Loader {
        id: contentLoader
        anchors.fill: parent
        sourceComponent: SessionManager.isLoggedIn() ? dashboardComponent : loginComponent
    }

    Component {
        id: loginComponent
        Login {}
    }

    Component {
        id: dashboardComponent
        Dashboard {}
    }

    Connections {
        target: contentLoader.item
        ignoreUnknownSignals: true

        function onLoginSucceeded() {
            contentLoader.sourceComponent = dashboardComponent;
            NotificationClient.connectNow();
        }
        function onLoggedOut() {
            NotificationClient.disconnectNow();
            contentLoader.sourceComponent = loginComponent;
        }
    }

    Binding {
        target: ApiClient
        property: "baseUrl"
        value: Config.baseUrl
    }
    Binding {
        target: ApiClient
        property: "session"
        value: SessionManager
    }
    Binding {
        target: NotificationClient
        property: "baseUrl"
        value: Config.baseUrl
    }
    Binding {
        target: NotificationClient
        property: "session"
        value: SessionManager
    }

    Component.onCompleted: {
        if (SessionManager.isLoggedIn()) {
            NotificationClient.connectNow();
        }
    }
}
