#pragma once
#include <QObject>
#include <QSettings>
#include <QtQmlIntegration/qqmlintegration.h>

class SessionManager : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

public:
  explicit SessionManager(QObject *parent = nullptr);

  Q_INVOKABLE void saveSession(const QString &token, const QString &role,
                               const QString &email);
  Q_INVOKABLE QString token() const;
  Q_INVOKABLE QString role() const;
  Q_INVOKABLE QString email() const;
  Q_INVOKABLE bool isLoggedIn() const;
  Q_INVOKABLE void clearSession();

private:
  QSettings settings;
  static QString sessionFilePath();
};
