#include "./SessionManager.hpp"
#include <QDir>

QString SessionManager::sessionFilePath() {
  QString dir = QDir::homePath() + "/.local/state/medisync-admin";
  QDir().mkpath(dir);
  return dir + "/session.ini";
}

SessionManager::SessionManager(QObject *parent)
    : QObject(parent), settings(sessionFilePath(), QSettings::IniFormat) {}

void SessionManager::saveSession(const QString &token, const QString &role,
                                 const QString &email) {
  settings.setValue("access_token", token);
  settings.setValue("role", role);
  settings.setValue("email", email);
  settings.sync();
}

QString SessionManager::token() const {
  return settings.value("access_token").toString();
}
QString SessionManager::role() const {
  return settings.value("role").toString();
}
QString SessionManager::email() const {
  return settings.value("email").toString();
}
bool SessionManager::isLoggedIn() const { return !token().isEmpty(); }

void SessionManager::clearSession() {
  settings.clear();
  settings.sync();
}
