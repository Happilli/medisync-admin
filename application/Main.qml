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
        }
        function onLoggedOut() {
            contentLoader.sourceComponent = loginComponent;
        }
    }

    Connections {
        target: Config
        function onConfigChanged() {
            ApiClient.baseUrl = Config.baseUrl;
        }
    }

    Component.onCompleted: {
        ApiClient.baseUrl = Config.baseUrl;
        ApiClient.session = SessionManager;
    }
}
