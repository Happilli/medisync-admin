#include "./AuthImageProvider.hpp"
#include <QDir>
#include <QEventLoop>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QQuickTextureFactory>
#include <QSettings>

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
  QNetworkAccessManager manager;

  QNetworkRequest req(QUrl(configBaseUrl() + id));
  QString tok = sessionToken();
  if (!tok.isEmpty())
    req.setRawHeader("Authorization", ("Bearer " + tok).toUtf8());

  QEventLoop loop;
  QNetworkReply *reply = manager.get(req);
  QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
  loop.exec();

  m_image.loadFromData(reply->readAll());
  reply->deleteLater();
  emit finished();
}

QQuickImageResponse *AuthImageProvider::requestImageResponse(const QString &id,
                                                             const QSize &) {
  return new AuthImageResponse(id);
}

QQuickTextureFactory *AuthImageResponse::textureFactory() const {
  return QQuickTextureFactory::textureFactoryForImage(m_image);
}
