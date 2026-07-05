#include "./ApiClient.hpp"
#include <QJsonArray>
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

void ApiClient::get(const QString &path, const QString &requestId) {
  sendRequest("GET", path, requestId, QVariantMap());
}

void ApiClient::post(const QString &path, const QString &requestId,
                     const QVariantMap &body) {
  sendRequest("POST", path, requestId, body);
}

void ApiClient::patch(const QString &path, const QString &requestId,
                      const QVariantMap &body) {
  sendRequest("PATCH", path, requestId, body);
}
void ApiClient::sendRequest(const QByteArray &method, const QString &path,
                            const QString &requestId, const QVariantMap &body) {
  QNetworkRequest request = buildRequest(path, true);
  QByteArray payload = QJsonDocument(QJsonObject::fromVariantMap(body))
                           .toJson(QJsonDocument::Compact);

  QNetworkReply *reply = nullptr;
  if (method == "GET") {
    reply = manager->get(request);
  } else if (method == "POST") {
    reply = manager->post(request, payload);
  } else if (method == "PATCH") {
    reply = manager->sendCustomRequest(request, "PATCH", payload);
  } else {
    return;
  }
  connect(reply, &QNetworkReply::finished, this, [this, reply, requestId]() {
    reply->deleteLater();
    const QByteArray raw = reply->readAll();
    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(raw, &parseError);

    if (reply->error() != QNetworkReply::NoError) {
      QString msg = "Request Failed..";
      if (parseError.error == QJsonParseError::NoError && doc.isObject()) {
        msg = doc.object().value("detail").toString(msg);
      }
      emit requestFinished(requestId, false, QVariant(), msg);
      return;
    }

    QVariant data;
    if (doc.isArray()) {
      data = doc.array().toVariantList();
    } else if (doc.isObject()) {
      data = doc.object().toVariantMap();
    }
    emit requestFinished(requestId, true, data, "");
  });
}
