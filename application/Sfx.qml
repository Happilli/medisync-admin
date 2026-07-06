pragma Singleton
import QtQuick
import QtMultimedia

QtObject {
    id: root

    readonly property SoundEffect moveSfx: SoundEffect {
        source: "assets/sfx/move.wav"
        volume: 0.6
    }
    readonly property SoundEffect enterSfx: SoundEffect {
        source: "assets/sfx/enter.wav"
        volume: 0.7
    }
    readonly property SoundEffect backSfx: SoundEffect {
        source: "assets/sfx/back.wav"
        volume: 0.7
    }
    readonly property SoundEffect changePaneSfx: SoundEffect {
        source: "assets/sfx/changepane.wav"
        volume: 0.7
    }

    function playMove() {
        root.moveSfx.play();
    }
    function playEnter() {
        root.enterSfx.play();
    }
    function playBack() {
        root.backSfx.play();
    }
    function playChangePane() {
        root.changePaneSfx.play();
    }
}
