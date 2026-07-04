#pragma once
#include "./SessionManager.hpp"
#include <QNetworkAccessManager>
#include <QObject>
#include <QtQmlIntegration/qqmlintegration.h>

class ApiClient : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

public:
  explicit ApiClient(QObject *parent = nullptr);

  Q_INVOKABLE void login(const QString &email, const QString &password);

signals:
  void loginFinished(bool success, const QString &message);

private:
  QNetworkAccessManager *manager;
  SessionManager *session;
  const QString baseUrl = QStringLiteral("http://192.168.240.1:8000/api/v1");

  QNetworkRequest buildRequest(const QString &path, bool withAuth = true) const;
};
