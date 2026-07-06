#pragma once
#include <QNetworkAccessManager>
#include <QQuickAsyncImageProvider>
#include <QQuickImageResponse>

class AuthImageResponse : public QQuickImageResponse {
  Q_OBJECT
public:
  AuthImageResponse(const QString &id);
  QQuickTextureFactory *textureFactory() const override;

private:
  QImage m_image;
};

class AuthImageProvider : public QQuickAsyncImageProvider {
public:
  QQuickImageResponse *
  requestImageResponse(const QString &id, const QSize &requestedSize) override;
};
