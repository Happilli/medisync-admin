#include <AuthImageProvider.hpp>
#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[]) {
  QGuiApplication app(argc, argv);
  QQmlApplicationEngine engine;
  engine.addImageProvider("authimg", new AuthImageProvider());
  engine.loadFromModule("MediSyncAdmin", "Main");
  return app.exec();
}
