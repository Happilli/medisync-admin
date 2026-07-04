#include "./ConfigManager.hpp"
#include <QDir>
#include <QFile>
#include <QTextStream>

ConfigManager::ConfigManager(QObject *parent) : QObject(parent) {
  load();

  m_watcher.addPath(configPath());
  connect(&m_watcher, &QFileSystemWatcher::fileChanged, this,
          [this](const QString &path) {
            load();
            if (!m_watcher.files().contains(path))
              m_watcher.addPath(path);
          });
}

QString ConfigManager::configDir() const {
  return QDir::homePath() + "/.config/medisync-admin";
}

QString ConfigManager::configPath() const {
  return configDir() + "/config.ini";
}

void ConfigManager::parseIniFile(const QString &path, QString &baseUrlOut,
                                 QVariantMap &themeOut) const {
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    return;

  QTextStream in(&file);
  QString currentSection;

  while (!in.atEnd()) {
    const QString line = in.readLine().trimmed();

    if (line.isEmpty() || line.startsWith('#') || line.startsWith(';'))
      continue;

    if (line.startsWith('[') && line.endsWith(']')) {
      currentSection = line.mid(1, line.length() - 2).trimmed().toLower();
      continue;
    }

    const int eq = line.indexOf('=');
    if (eq <= 0)
      continue;

    const QString key = line.left(eq).trimmed();
    QString value = line.mid(eq + 1).trimmed();

    if (value.length() >= 2 && value.front() == value.back() &&
        (value.front() == '"' || value.front() == '\''))
      value = value.mid(1, value.length() - 2);

    if (currentSection == "general" &&
        key.compare("baseUrl", Qt::CaseInsensitive) == 0)
      baseUrlOut = value;
    else if (currentSection == "theme")
      themeOut[key] = value;
  }
}

void ConfigManager::load() {
  m_baseUrl.clear();
  m_theme.clear();

  parseIniFile(configPath(), m_baseUrl, m_theme);

  emit configChanged();
}

void ConfigManager::reload() { load(); }

QString ConfigManager::baseUrl() const { return m_baseUrl; }

QVariantMap ConfigManager::theme() const { return m_theme; }
