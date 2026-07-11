#include "./AuthImageProvider.hpp"
#include <QDir>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QQuickTextureFactory>
#include <QSettings>
#include <QThread>

static QThreadStorage<QNetworkAccessManager *> tlManager;

static QNetworkAccessManager *managerForThread() {
  if (!tlManager.hasLocalData()) {
    tlManager.setLocalData(new QNetworkAccessManager());
  }
  return tlManager.localData();
}

static QString sessionToken() {
  QSettings s(QDir::homePath() + "/.local/state/medisync-admin/session.ini",
              QSettings::IniFormat);
  return s.value("access_token").toString();
}

static QString configBaseUrl() {
  QSettings s(QDir::homePath() + "/.config/medisync-admin/config.ini",
              QSettings::IniFormat);
  return s.value("baseUrl").toString();
}

AuthImageResponse::AuthImageResponse(const QString &id) {
  QNetworkAccessManager *manager = managerForThread();

  QNetworkRequest req(QUrl(configBaseUrl() + id));
  QString tok = sessionToken();
  if (!tok.isEmpty())
    req.setRawHeader("Authorization", ("Bearer " + tok).toUtf8());

  m_reply = manager->get(req);
  connect(m_reply, &QNetworkReply::finished, this, [this]() {
    m_image.loadFromData(m_reply->readAll());
    m_reply->deleteLater();
    m_reply = nullptr;
    emit finished();
  });
}

QQuickImageResponse *AuthImageProvider::requestImageResponse(const QString &id,
                                                             const QSize &) {
  return new AuthImageResponse(id);
}

QQuickTextureFactory *AuthImageResponse::textureFactory() const {
  return QQuickTextureFactory::textureFactoryForImage(m_image);
}
