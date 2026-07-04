#include "./ApiClient.hpp"
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QUrl>

ApiClient::ApiClient(QObject *parent)
    : QObject(parent), manager(new QNetworkAccessManager(this)) {}

QString ApiClient::baseUrl() const { return m_baseUrl; }

void ApiClient::setBaseUrl(const QString &url) {
  if (m_baseUrl == url) {
    return;
  }
  m_baseUrl = url;
  emit baseUrlChanged();
}

SessionManager *ApiClient::session() const { return m_session; }

void ApiClient::setSession(SessionManager *s) {
  if (m_session == s) {
    return;
  }
  m_session = s;
  emit sessionChanged();
}

QNetworkRequest ApiClient::buildRequest(const QString &path,
                                        bool withAuth) const {
  QNetworkRequest request(QUrl(m_baseUrl + path));
  request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
  if (withAuth && m_session) {
    QString tok = m_session->token();
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

    if (m_session) {
      m_session->saveSession(obj.value("access_token").toString(), role,
                             obj.value("email").toString());
      emit loginFinished(true, "Logged in");
    }
  });
}
