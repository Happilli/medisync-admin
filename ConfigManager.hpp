#pragma once
#include <QColor>
#include <QFileSystemWatcher>
#include <QObject>
#include <QVariantMap>
#include <QtQmlIntegration/qqmlintegration.h>

class ConfigManager : public QObject {
  Q_OBJECT
  QML_NAMED_ELEMENT(Config)
  QML_SINGLETON
  Q_PROPERTY(QString baseUrl READ baseUrl NOTIFY configChanged)
  Q_PROPERTY(QVariantMap theme READ theme NOTIFY configChanged)

public:
  explicit ConfigManager(QObject *parent = nullptr);

  QString baseUrl() const;
  QVariantMap theme() const;

  Q_INVOKABLE void reload();

signals:
  void configChanged();

private:
  QString m_baseUrl;
  QVariantMap m_theme;
  QFileSystemWatcher m_watcher;

  QString configDir() const;
  QString configPath() const;
  void load();
  void parseIniFile(const QString &path, QString &baseUrlOut,
                    QVariantMap &themeOut) const;
};
