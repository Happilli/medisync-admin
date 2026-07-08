#pragma once
#include "./SessionManager.hpp"
#include <QObject>
#include <QVariantMap>
#include <QWebSocket>
#include <QtQmlIntegration/qqmlintegration.h>

class NotificationClient : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  Q_PROPERTY(
      QString baseUrl READ baseUrl WRITE setBaseUrl NOTIFY baseUrlChanged)
  Q_PROPERTY(SessionManager *session READ session WRITE setSession NOTIFY
                 sessionChanged)
  Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)

public:
  explicit NotificationClient(QObject *parent = nullptr);

  QString baseUrl() const;
  void setBaseUrl(const QString &url);

  SessionManager *session() const;
  void setSession(SessionManager *s);

  bool isConnected() const;

  Q_INVOKABLE void connectNow();
  Q_INVOKABLE void disconnectNow();

signals:
  void notificationReceived(const QVariantMap &notification);
  void baseUrlChanged();
  void sessionChanged();
  void connectedChanged();

private:
  QWebSocket m_socket;
  QString m_baseUrl;
  SessionManager *m_session = nullptr;
  bool m_connected = false;

  QString buildWsUrl() const;
  void onConnected();
  void onDisconnected();
  void onTextMessageReceived(const QString &message);
  void sendDesktopNotification(const QString &title, const QString &body);
};
