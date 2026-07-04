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

public:
  explicit ApiClient(QObject *parent = nullptr);

  Q_INVOKABLE void login(const QString &email, const QString &password);

  QString baseUrl() const;
  void setBaseUrl(const QString &url);

signals:
  void loginFinished(bool success, const QString &message);
  void baseUrlChanged();

private:
  QNetworkAccessManager *manager;
  SessionManager *session;
  QString m_baseUrl;

  QNetworkRequest buildRequest(const QString &path, bool withAuth = true) const;
};
