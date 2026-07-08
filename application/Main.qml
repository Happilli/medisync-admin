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

    Connections {
        target: Config
        function onConfigChanged() {
            ApiClient.baseUrl = Config.baseUrl;
            NotificationClient.baseUrl = Config.baseUrl;
        }
    }

    Component.onCompleted: {
        ApiClient.baseUrl = Config.baseUrl;
        ApiClient.session = SessionManager;
        NotificationClient.baseUrl = Config.baseUrl;
        NotificationClient.session = SessionManager;
        if (SessionManager.isLoggedIn())
            NotificationClient.connectNow();
    }
}
