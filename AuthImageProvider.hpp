#pragma once
#include <QNetworkAccessManager>
#include <QQuickAsyncImageProvider>
#include <QQuickImageResponse>
#include <QThreadStorage>

class AuthImageResponse : public QQuickImageResponse {
  Q_OBJECT
public:
  AuthImageResponse(const QString &id);
  QQuickTextureFactory *textureFactory() const override;

private:
  QImage m_image;
  QNetworkReply *m_reply = nullptr;
};

class AuthImageProvider : public QQuickAsyncImageProvider {
public:
  QQuickImageResponse *
  requestImageResponse(const QString &id, const QSize &requestedSize) override;
};
