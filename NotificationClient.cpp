#include "./NotificationClient.hpp"
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QUrl>
#include <QUrlQuery>

NotificationClient::NotificationClient(QObject *parent) : QObject(parent) {
  connect(&m_socket, &QWebSocket::connected, this,
          &NotificationClient::onConnected);
  connect(&m_socket, &QWebSocket::disconnected, this,
          &NotificationClient::onDisconnected);
  connect(&m_socket, &QWebSocket::textMessageReceived, this,
          &NotificationClient::onTextMessageReceived);
}

QString NotificationClient::baseUrl() const { return m_baseUrl; }

void NotificationClient::setBaseUrl(const QString &url) {
  if (m_baseUrl == url) {
    return;
  }
  m_baseUrl = url;
  emit baseUrlChanged();
}

SessionManager *NotificationClient::session() const { return m_session; }

void NotificationClient::setSession(SessionManager *s) {
  if (m_session == s) {
    return;
  }
  m_session = s;
  emit sessionChanged();
}

bool NotificationClient::isConnected() const { return m_connected; }

QString NotificationClient::buildWsUrl() const {
  QString url = m_baseUrl;
  if (url.startsWith("https://")) {

    url.replace(0, 8, "wss://");
  } else if (url.startsWith("http://")) {
    url.replace(0, 7, "ws://");
  }

  QString token = m_session ? m_session->token() : QString();

  QUrl wsUrl(url + "/ws/notifications");
  QUrlQuery query;
  query.addQueryItem("token", token);
  wsUrl.setQuery(query);
  return wsUrl.toString();
}

void NotificationClient::connectNow() {
  if (!m_session || m_session->token().isEmpty()) {
    return;
  }
  if (m_socket.state() == QAbstractSocket::ConnectedState ||
      m_socket.state() == QAbstractSocket::ConnectingState) {
    return;
  }

  m_socket.open(QUrl(buildWsUrl()));
}

void NotificationClient::disconnectNow() { m_socket.close(); }

void NotificationClient::onConnected() {
  m_connected = true;
  emit connectedChanged();
}

void NotificationClient::onDisconnected() {
  m_connected = false;
  emit connectedChanged();
}

void NotificationClient::sendDesktopNotification(const QString &title,
                                                 const QString &body) {
  QProcess::startDetached("notify-send", {"-a", "MediSync Admin", "-i",
                                          "dialog-information", title, body});
}

void NotificationClient::onTextMessageReceived(const QString &message) {
  QJsonParseError err;
  QJsonDocument doc = QJsonDocument::fromJson(message.toUtf8(), &err);
  if (err.error != QJsonParseError::NoError || !doc.isObject()) {
    return;
  }

  QJsonObject obj = doc.object();
  sendDesktopNotification(obj.value("title").toString(),
                          obj.value("message").toString());

  emit notificationReceived(obj.toVariantMap());
}
