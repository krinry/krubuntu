import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    function nextSlide() {
        presentation.goToNextSlide();
    }

    Timer {
        id: advanceTimer
        interval: 8000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    Slide {
        Image {
            id: logo1
            source: "krubuntu-logo.svg"
            width: 140; height: 140
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 40
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo1.bottom
            anchors.topMargin: 20
            text: "<h2 style='color:#3daee9;'>Welcome to Krubuntu 26.04 LTS</h2><br/>" +
                  "<p style='font-size:14px;'>A pure, high-performance KDE Plasma experience built on Ubuntu 26.04 LTS.</p><br/>" +
                  "<p style='font-size:13px; color:#7f8c8d;'>Wayland-first, bloat-free, and designed with professional craftsmanship.</p>"
            wrapMode: Text.WordWrap
            width: presentation.width * 0.85
            horizontalAlignment: Text.Center
        }
    }

    Slide {
        Image {
            id: logo2
            source: "krubuntu-logo.svg"
            width: 100; height: 100
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 40
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo2.bottom
            anchors.topMargin: 20
            text: "<h2 style='color:#3daee9;'>Software on Your Terms</h2><br/>" +
                  "<p style='font-size:14px;'>Snap and Flatpak are natively integrated into KDE Discover.</p><br/>" +
                  "<p style='font-size:13px; color:#7f8c8d;'>Disabled by default to keep the system lean and fast. Enable on-demand with one click.</p>"
            wrapMode: Text.WordWrap
            width: presentation.width * 0.85
            horizontalAlignment: Text.Center
        }
    }

    Slide {
        Image {
            id: logo3
            source: "krubuntu-logo.svg"
            width: 100; height: 100
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 40
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logo3.bottom
            anchors.topMargin: 20
            text: "<h2 style='color:#3daee9;'>Minimal, Pure & Bloat-Free</h2><br/>" +
                  "<p style='font-size:14px;'>Zero telemetry, no duplicate browsers, and no office bloat pre-installed.</p><br/>" +
                  "<p style='font-size:13px; color:#7f8c8d;'>A clean canvas ready for you to build your ideal computing environment.</p>"
            wrapMode: Text.WordWrap
            width: presentation.width * 0.85
            horizontalAlignment: Text.Center
        }
    }

    function onActivate() {
        presentation.currentSlide = 0;
    }

    function onLeave() {
    }
}
