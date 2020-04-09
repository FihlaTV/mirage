// SPDX-License-Identifier: LGPL-3.0-or-later

// This file creates the application, registers custom objects for QML
// and launches Window.qml (the root component).

#include <QApplication>
#include <QQmlEngine>
#include <QQmlContext>
#include <QQmlComponent>
#include <QFileInfo>
#include <QQuickStyle>
#include <QFontDatabase>

#include "../submodules/RadialBarDemo/radialbar.h"

#include "utils.h"
#include "clipboard.h"


int main(int argc, char *argv[]) {
    // Define some basic info about the app before creating the QApplication
    QApplication::setOrganizationName("Qtune);
    QApplication::setApplicationName("Qtune");
    QApplication::setApplicationDisplayName("Qtune");
    QApplication::setApplicationVersion("0.4.3");
    QApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);

    // Force the default universal QML style, notably prevents
    // KDE from hijacking base controls and messing up everything
    QQuickStyle::setStyle("Fusion");
    QQuickStyle::setFallbackStyle("Default");

    // Register default theme fonts. Take the files  from the
    // Qt resource system if possible (resources stored in the app executable),
    // else the local file system.
    // The dev qmake flag disables the resource system for faster builds.
    QFileInfo qrcPath(":src/gui/Window.qml");
    QString src = qrcPath.exists() ? ":/src" : "src";

    QList<QString> fontFamilies;
    fontFamilies << "roboto" << "hack";

    QList<QString> fontVariants;
    fontVariants << "regular" << "italic" << "bold" << "bold-italic";

    foreach (QString family, fontFamilies) {
        foreach (QString var, fontVariants) {
            QFontDatabase::addApplicationFont(
                src + "/fonts/" + family + "/" + var + ".ttf"
            );
        }
    }

    // Create the QML engine and get the root context.
    // We will add it some properties that will be available globally in QML.
    QQmlEngine engine;
    QQmlContext *objectContext = new QQmlContext(engine.rootContext());

    // Set the debugMode properties depending of if we're running in debug mode
    // or not (`qmake CONFIG+=dev ...`, default in live-reload.sh)
#ifdef QT_DEBUG
    objectContext->setContextProperty("debugMode", true);
#else
    objectContext->setContextProperty("debugMode", false);
#endif

    // Register our custom non-visual QObject singletons,
    // that will be importable anywhere in QML. Example:
    //     import Clipboard 0.1
    //     ...
    //     Component.onCompleted: print(Clipboard.text)
    qmlRegisterSingletonType<Clipboard>(
        "Clipboard", 0, 1, "Clipboard",
        [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
            Q_UNUSED(engine)
            Q_UNUSED(scriptEngine)
            return new Clipboard();
        }
    );

    qmlRegisterSingletonType<Utils>(
        "CppUtils", 0, 1, "CppUtils",
        [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject * {
            Q_UNUSED(engine)
            Q_UNUSED(scriptEngine)
            return new Utils();
        }
    );

    // Register our custom visual items that will be importable from QML, e.g.
    //     import RadialBar 1.0
    //     ...
    //     RadialBar { ... }
    qmlRegisterType<RadialBar>("RadialBar", 1, 0, "RadialBar");

    // Create the QML root component by loading its file from the Qt Resource
    // System or local file system if not possible.
    QQmlComponent component(
        &engine,
        qrcPath.exists() ? "qrc:/src/gui/Window.qml" : "src/gui/Window.qml"
    );
    component.create(objectContext);

    // Finally, execute the app. Return its system exit code when it exits.
    return app.exec();
}
