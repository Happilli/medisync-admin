#include "./ApiClient.hpp"
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QUrl>

ApiClient::ApiClient(QObject *parent)
    : QObject(parent), manager(new QNetworkAccessManager(this)),
      session(new SessionManager(this)) {}

QNetworkRequest ApiClient::buildRequest(const QString &path,
                                        bool withAuth) const {
  QNetworkRequest request(QUrl(baseUrl + path));
  request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
  if (withAuth) {
    QString tok = session->token();
    if (!tok.isEmpty())
      request.setRawHeader("Authorization", ("Bearer " + tok).toUtf8());
  }
  return request;
}

void ApiClient::login(const QString &email, const QString &password) {
  QNetworkRequest request = buildRequest("/auth/login", false);
  QJsonObject body{{"email", email}, {"password", password}};
  QNetworkReply *reply = manager->post(request, QJsonDocument(body).toJson());

  connect(reply, &QNetworkReply::finished, this, [this, reply]() {
    reply->deleteLater();
    QJsonObject obj = QJsonDocument::fromJson(reply->readAll()).object();

    if (reply->error() != QNetworkReply::NoError) {
      emit loginFinished(false, obj.value("detail").toString("Login failed"));
      return;
    }

    QString role = obj.value("role").toString();
    if (role.compare("admin", Qt::CaseInsensitive) != 0) {
      emit loginFinished(false, "This account is not an admin account.");
      return;
    }

    session->saveSession(obj.value("access_token").toString(), role,
                         obj.value("email").toString());
    emit loginFinished(true, "Logged in");
  });
}
