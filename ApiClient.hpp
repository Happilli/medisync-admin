#pragma once
#include "./SessionManager.hpp"
#include <QNetworkAccessManager>
#include <QObject>
#include <QtQmlIntegration/qqmlintegration.h>

class ApiClient : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON
  Q_PROPERTY(
      QString baseUrl READ baseUrl WRITE setBaseUrl NOTIFY baseUrlChanged)
  Q_PROPERTY(SessionManager *session READ session WRITE setSession NOTIFY
                 sessionChanged)

public:
  explicit ApiClient(QObject *parent = nullptr);

  Q_INVOKABLE void login(const QString &email, const QString &password);

  // authenticated requests...
  Q_INVOKABLE void get(const QString &path, const QString &requestId);
  Q_INVOKABLE void post(const QString &path, const QString &requestId,
                        const QVariantMap &body = QVariantMap());
  Q_INVOKABLE void patch(const QString &path, const QString &requestId,
                         const QVariantMap &body = QVariantMap());
  Q_INVOKABLE void del(const QString &path, const QString &requestId);

  QString baseUrl() const;
  void setBaseUrl(const QString &url);

  SessionManager *session() const;
  void setSession(SessionManager *s);

signals:
  void loginFinished(bool success, const QString &message);
  void requestFinished(QString requestId, bool success, QVariant data,
                       QString message);
  void baseUrlChanged();
  void sessionChanged();

private:
  QNetworkAccessManager *manager;
  SessionManager *m_session = nullptr;
  QString m_baseUrl;

  QNetworkRequest buildRequest(const QString &path, bool withAuth = true) const;
  void sendRequest(const QByteArray &method, const QString &path,
                   const QString &requestId, const QVariantMap &body);
};
